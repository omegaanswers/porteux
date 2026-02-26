#!/usr/bin/env python3
# =============================================================================
#  SkyCAIR OS — Calamares Module: skypartition
#  SkyMEMBOOST Auto-Partition — Applies full partition layout from skyboost
#
#  When user selects a disk in the Calamares installer, this module:
#    1. Runs skyboost hardware detection (RAM, DDR gen, PCIe NVMe gen)
#    2. Calculates optimal partition layout via skyboost calc
#    3. Applies GPT partition table via parted
#    4. Formats all partitions with correct labels + filesystem
#    5. Creates ZFS pool "skyvault" on vault partition
#    6. Initializes SKYRESTORE partition with module manifest + activation data
#    7. Tags all partitions in skyboost state for repeatability
#
#  Partition layout (SkyMEMBOOST formula):
#    p1  2 MB     bios_grub  BIOS        GRUB2 GPT boot (front)
#    p2  40 GB    ext4       SkyCAIR     OS + .xzm modules + kernels
#    p3  N GB     swap       AISWAP      AI NVMe swap (min 8, max 32, PCIe-scaled)
#    p4  ALL      ZFS        SKYVAULT    SkyVAULT — expand with zpool add
#    p5  20 GB    FAT32      SKYRESTORE  Recovery partition (end of disk)
#
#  OCI / ISO expansion:
#    SKYRESTORE hosts the module manifest + core model cache for instant
#    activation. As modules grow (new .xzm), they are synced to SKYRESTORE
#    by skyrestore-sync.sh post-module-activate.
#
#  Repeatable: skyboost profile.json + partition labels make reinstall
#              idempotent — same hardware always produces same layout.
#
#  2XR, LLC | Evolve2Linux | 123Tech.net
#  © 2018–2026 2XR, LLC. All Rights Reserved.
# =============================================================================

import libcalamares
import os
import re
import json
import subprocess
import shutil
from datetime import datetime, timezone
from pathlib import Path

# ── Constants ──────────────────────────────────────────────────────────────
OS_SIZE_GB       = 40
RESTORE_SIZE_GB  = 20
FLOOR_SWAP_GB    = 8
HARD_CAP_SWAP_GB = 32
BIOS_SIZE_MB     = 2

# PCIe gen → swap cap (GB): each gen halves swap needed (throughput doubles)
PCIE_SWAP_CAP = {3: 32, 4: 16, 5: 8, 6: 8}


# ── Hardware detection ─────────────────────────────────────────────────────

def detect_ram_gb() -> int:
    with open("/proc/meminfo") as f:
        for line in f:
            if line.startswith("MemTotal:"):
                kb = int(line.split()[1])
                return kb // 1024 // 1024
    return 16

def detect_pcie_gen(nvme_dev: str) -> int:
    """Detect PCIe generation of an NVMe device from sysfs link speed."""
    name = os.path.basename(nvme_dev)
    # Strip partition suffix: nvme0n1p2 → nvme0
    name = re.sub(r'n\d+.*', '', name)
    candidates = [
        f"/sys/block/{os.path.basename(nvme_dev)}/device/device/max_link_speed",
        f"/sys/class/nvme/{name}/device/max_link_speed",
        f"/sys/class/nvme/{name}/device/device/max_link_speed",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                spd_str = Path(path).read_text()
                m = re.search(r'(\d+)', spd_str)
                if m:
                    spd = int(m.group(1))
                    if spd >= 64: return 6
                    if spd >= 32: return 5
                    if spd >= 16: return 4
                    if spd >= 8:  return 3
            except Exception:
                pass
    return 3  # Conservative default

def detect_best_nvme() -> str:
    """Return the highest-gen NVMe device path."""
    best, best_gen = "", 0
    for dev in sorted(Path("/dev").glob("nvme*n1")):
        gen = detect_pcie_gen(str(dev))
        if gen >= best_gen:
            best, best_gen = str(dev), gen
    return best

def calc_ai_swap_gb(ram_gb: int, pcie_gen: int) -> int:
    gen_cap = PCIE_SWAP_CAP.get(pcie_gen, 32)
    target = min(ram_gb * 2, gen_cap, HARD_CAP_SWAP_GB)
    return max(target, FLOOR_SWAP_GB)

def disk_size_gb(disk: str) -> int:
    name = os.path.basename(disk)
    sz_path = f"/sys/block/{name}/size"
    try:
        sectors = int(Path(sz_path).read_text().strip())
        return sectors * 512 // 1024 // 1024 // 1024
    except Exception:
        return 0


# ── Subprocess helpers ─────────────────────────────────────────────────────

def run(cmd: list, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess:
    libcalamares.utils.debug(f"skypartition: run: {' '.join(str(c) for c in cmd)}")
    result = subprocess.run(cmd, capture_output=capture, text=True, check=False)
    if check and result.returncode != 0:
        msg = f"Command failed ({result.returncode}): {' '.join(str(c) for c in cmd)}"
        if capture:
            msg += f"\nstdout: {result.stdout}\nstderr: {result.stderr}"
        raise RuntimeError(msg)
    return result

def part_dev(disk: str, n: int) -> str:
    """Return partition device path: /dev/sda → /dev/sda2; /dev/nvme0n1 → /dev/nvme0n1p2"""
    if re.search(r'nvme\d+n\d+$', disk) or re.search(r'mmcblk\d+$', disk):
        return f"{disk}p{n}"
    return f"{disk}{n}"


# ── Partition creation ─────────────────────────────────────────────────────

def wipe_disk(disk: str):
    """Wipe existing partition table."""
    run(["wipefs", "-a", disk])
    run(["sgdisk", "--zap-all", disk])

def create_partitions(disk: str, ai_swap_gb: int, disk_gb: int):
    """Create GPT partition table with SkyMEMBOOST layout."""

    # Calculate boundaries (MiB)
    p1_start = 1
    p1_end   = p1_start + BIOS_SIZE_MB    # 3 MiB

    p2_start = p1_end
    p2_end   = p2_start + OS_SIZE_GB * 1024

    p3_start = p2_end
    p3_end   = p3_start + ai_swap_gb * 1024

    # SKYRESTORE is always at end — calculate from disk end
    restore_start = disk_gb * 1024 - RESTORE_SIZE_GB * 1024
    p4_start      = p3_end
    p4_end        = restore_start

    run(["parted", "-s", disk, "mklabel", "gpt"])

    # p1: BIOS boot
    run(["parted", "-s", disk, "mkpart", "primary",
         f"{p1_start}MiB", f"{p1_end}MiB"])
    run(["parted", "-s", disk, "set", "1", "bios_grub", "on"])
    run(["sgdisk", "-t", "1:EF02", disk])  # BIOS boot GUID

    # p2: SkyCAIR OS (ext4)
    run(["parted", "-s", disk, "mkpart", "primary", "ext4",
         f"{p2_start}MiB", f"{p2_end}MiB"])
    run(["parted", "-s", disk, "set", "2", "boot", "on"])

    # p3: AI swap (linux-swap)
    run(["parted", "-s", disk, "mkpart", "primary", "linux-swap",
         f"{p3_start}MiB", f"{p3_end}MiB"])

    # p4: SkyVAULT ZFS (all remaining between swap and restore)
    if p4_end > p4_start + 1024:  # At least 1GB for vault
        run(["parted", "-s", disk, "mkpart", "primary",
             f"{p4_start}MiB", f"{p4_end}MiB"])
        run(["sgdisk", "-t", "4:6A898CC3-1DD2-11B2-99A6-080020736631", disk])  # ZFS GUID
    else:
        libcalamares.utils.warning("skypartition: vault partition too small — skipping ZFS partition")

    # p5: SKYRESTORE (FAT32, end of disk)
    run(["parted", "-s", disk, "mkpart", "primary", "fat32",
         f"{restore_start}MiB", "100%"])

    run(["parted", "-s", disk, "print"])
    libcalamares.utils.debug("skypartition: partition table created")


# ── Filesystem creation ───────────────────────────────────────────────────

def format_partitions(disk: str, ai_swap_gb: int, disk_gb: int):
    """Format all partitions with correct filesystems and labels."""

    p2 = part_dev(disk, 2)
    p3 = part_dev(disk, 3)
    p4 = part_dev(disk, 4)
    p5 = part_dev(disk, 5)

    # OS: ext4 with SkyCAIR label
    run(["mkfs.ext4", "-F", "-L", "SkyCAIR", "-E", "lazy_itable_init=0,lazy_journal_init=0", p2])
    libcalamares.utils.debug(f"skypartition: {p2} → ext4 label=SkyCAIR")

    # AI swap
    run(["mkswap", "-L", "AISWAP", p3])
    libcalamares.utils.debug(f"skypartition: {p3} → swap label=AISWAP ({ai_swap_gb}GB)")

    # SkyVAULT: ZFS (create pool)
    vault_gb = disk_gb - 1 - OS_SIZE_GB - ai_swap_gb - RESTORE_SIZE_GB
    if vault_gb >= 1 and os.path.exists(p4):
        try:
            run(["zpool", "create", "-f",
                 "-o", "ashift=12",                    # 4K sector alignment
                 "-O", "compression=lz4",
                 "-O", "atime=off",
                 "-O", "xattr=sa",
                 "-O", "dnodesize=auto",
                 "-O", "normalization=formD",
                 "skyvault", p4])
            # Create AI model dataset with optimal settings
            run(["zfs", "create", "-o", "recordsize=1M", "-o", "primarycache=all",
                 "-o", "prefetch=all", "skyvault/ai-models"])
            run(["zfs", "create", "skyvault/ollama"])
            run(["zfs", "create", "skyvault/media"])
            run(["zfs", "create", "skyvault/backups"])
            libcalamares.utils.debug("skypartition: skyvault ZFS pool created")
        except Exception as e:
            libcalamares.utils.warning(f"skypartition: ZFS pool creation failed: {e}")

    # SKYRESTORE: FAT32
    run(["mkfs.fat", "-F", "32", "-n", "SKYRESTORE", p5])
    libcalamares.utils.debug(f"skypartition: {p5} → FAT32 label=SKYRESTORE")


# ── SKYRESTORE initialization ─────────────────────────────────────────────

def init_restore_partition(disk: str, ram_gb: int, pcie_gen: int, ai_swap_gb: int, disk_gb: int):
    """Mount SKYRESTORE and initialize directory structure + manifest."""

    p5 = part_dev(disk, 5)
    mount_point = "/tmp/skyrestore-init"
    os.makedirs(mount_point, exist_ok=True)

    try:
        run(["mount", "-t", "vfat", p5, mount_point])

        dirs = [
            "boot-health", "audits", "isos",
            "modules/cache", "modules/manifest",
            "packages", "staging",
        ]
        for d in dirs:
            os.makedirs(os.path.join(mount_point, d), exist_ok=True)

        # Write hardware profile — used by skyboost at reinstall for repeatability
        profile = {
            "schema_version":  "1.0",
            "product":         "SkySTACK",
            "created_at":      datetime.now(timezone.utc).isoformat(),
            "hardware": {
                "ram_gb":      ram_gb,
                "pcie_gen":    pcie_gen,
                "ai_swap_gb":  ai_swap_gb,
                "disk_gb":     disk_gb,
            },
            "partitions": {
                "bios_grub":  f"{disk}1",
                "os":         f"{disk}2",
                "ai_swap":    f"{disk}3",
                "vault":      f"{disk}4",
                "restore":    f"{disk}5",
            },
            "zfs_pool":    "skyvault",
            "install_disk": disk,
        }
        with open(os.path.join(mount_point, "skyboost-profile.json"), "w") as f:
            json.dump(profile, f, indent=2)

        # Module manifest template (populated by skyrestore-sync.sh post-activate)
        manifest = {
            "schema_version": "1.0",
            "modules": [],
            "last_sync": None,
            "note": "Populated by skyrestore-sync.sh when modules are activated"
        }
        with open(os.path.join(mount_point, "modules/manifest/modules.manifest"), "w") as f:
            json.dump(manifest, f, indent=2)

        # README
        readme = f"""SKYRESTORE — SkyCAIR OS Recovery Partition
===========================================
Created: {datetime.now(timezone.utc).isoformat()}
Disk:    {disk}  ({disk_gb}GB)
RAM:     {ram_gb}GB
PCIe:    Gen {pcie_gen}
AI Swap: {ai_swap_gb}GB

Directory structure:
  boot-health/     Boot-count tracking (pending-boot, fail-count, needs-recovery)
  audits/          Pre/post audit records (JSON diff per module change)
  isos/            Recovery ISO (place skycair-recovery.iso here)
  modules/cache/   Cached .xzm module files for instant activation
  modules/manifest/ Module manifest (synced by skyrestore-sync.sh)
  packages/        Offline package cache (SkyRepo mirror)
  staging/         Staging area for updates

Recovery:
  - On 3 consecutive boot failures, GRUB auto-boots from isos/skycair-recovery.iso
  - Or boot from recovery ISO manually → run skyrestore-cli.sh
  - ZFS vault expansion: zpool add skyvault /dev/sdX (JBOD)
  - 2XR LLC activation: call (608) 454-6660 or email activate@123tech.net

© 2018–2026 2XR, LLC. All Rights Reserved.
"""
        with open(os.path.join(mount_point, "README.txt"), "w") as f:
            f.write(readme)

        libcalamares.utils.debug("skypartition: SKYRESTORE initialized")

    finally:
        try:
            run(["umount", mount_point], check=False)
        except Exception:
            pass


# ── fstab entries ─────────────────────────────────────────────────────────

def write_fstab(root_mount: str, disk: str, ai_swap_gb: int):
    """Add SkyMEMBOOST partitions to /etc/fstab in the installed system."""

    fstab_path = os.path.join(root_mount, "etc/fstab")
    p3 = part_dev(disk, 3)
    p5 = part_dev(disk, 5)

    entries = [
        f"\n# SkyMEMBOOST AI swap ({ai_swap_gb}GB NVMe, max 32GB, PCIe-gen-scaled)",
        f"LABEL=AISWAP    none    swap    sw,pri=10    0 0",
        f"\n# SKYRESTORE recovery partition (read-only mount, auto not at boot)",
        f"LABEL=SKYRESTORE    /mnt/skyrestore    vfat    noauto,ro,umask=0222    0 0",
    ]

    try:
        with open(fstab_path, "a") as f:
            f.write("\n")
            for e in entries:
                f.write(e + "\n")
        libcalamares.utils.debug(f"skypartition: fstab updated at {fstab_path}")
    except Exception as e:
        libcalamares.utils.warning(f"skypartition: fstab update failed: {e}")


# ── Calamares entry point ─────────────────────────────────────────────────

def run():
    """Main Calamares module entry point."""

    # Get target disk from Calamares global storage
    gs = libcalamares.globalstorage
    disk = gs.value("selectedDisk") or gs.value("partitionLayout.disk") or ""

    if not disk:
        return ("skypartition: No disk selected",
                "Please select an installation disk before running SkyMEMBOOST partitioning.")

    if not os.path.exists(disk):
        return (f"skypartition: Disk not found: {disk}",
                f"The selected disk {disk} does not exist.")

    libcalamares.utils.debug(f"skypartition: target disk = {disk}")

    # Hardware detection
    ram_gb      = detect_ram_gb()
    nvme_dev    = detect_best_nvme()
    pcie_gen    = detect_pcie_gen(nvme_dev) if nvme_dev else 3
    disk_gb     = disk_size_gb(disk)
    ai_swap_gb  = calc_ai_swap_gb(ram_gb, pcie_gen)

    libcalamares.utils.debug(
        f"skypartition: RAM={ram_gb}GB PCIe={pcie_gen} disk={disk_gb}GB ai_swap={ai_swap_gb}GB"
    )

    vault_gb = disk_gb - 1 - OS_SIZE_GB - ai_swap_gb - RESTORE_SIZE_GB
    if vault_gb < 1:
        return ("skypartition: Disk too small",
                f"Disk {disk} ({disk_gb}GB) is too small for the SkyMEMBOOST layout. "
                f"Minimum required: {1 + OS_SIZE_GB + ai_swap_gb + RESTORE_SIZE_GB + 10}GB.")

    # Store layout in Calamares global storage for other modules + summary screen
    gs.insert("skyboost_ram_gb",     ram_gb)
    gs.insert("skyboost_pcie_gen",   pcie_gen)
    gs.insert("skyboost_ai_swap_gb", ai_swap_gb)
    gs.insert("skyboost_vault_gb",   vault_gb)
    gs.insert("skyboost_disk",       disk)

    # Inform Calamares of the mount points it needs to know about
    root_mount = gs.value("rootMountPoint") or "/tmp/calamares-root"

    try:
        # 1. Wipe + partition
        wipe_disk(disk)
        create_partitions(disk, ai_swap_gb, disk_gb)

        # 2. Format
        format_partitions(disk, ai_swap_gb, disk_gb)

        # 3. Initialize SKYRESTORE
        init_restore_partition(disk, ram_gb, pcie_gen, ai_swap_gb, disk_gb)

        # 4. fstab entries (called after OS install, so we do it in post-install hook)
        # write_fstab(root_mount, disk, ai_swap_gb)

    except Exception as e:
        libcalamares.utils.warning(f"skypartition: {e}")
        return ("SkyMEMBOOST partition error", str(e))

    libcalamares.utils.debug(
        f"skypartition: complete — vault={vault_gb}GB, ai_swap={ai_swap_gb}GB, "
        f"SKYRESTORE=20GB, OS=40GB"
    )
    return None  # Success
