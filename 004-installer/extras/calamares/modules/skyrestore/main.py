#!/usr/bin/env python3
# =============================================================================
#  SkyCAIR OS — Calamares Module: skyrestore
#  SkyRESTORE Partition — Create FAT32 recovery partition at end of disk
#
#  Creates a fixed 20 GB FAT32 partition (label: SKYRESTORE) at the end
#  of the installation target disk. Initializes the directory structure
#  for: boot-health tracking, audit records, module cache, package cache,
#  manifests, and staging area.
#
#  The SKYRESTORE partition is intentionally placed LAST on the disk so
#  that sda2 (SkyCAIR OS) and sda3 (SkyVAULT/ZFS) can be resized freely
#  without ever touching it.
#
#  Called after the partitioning module completes and the OS partition
#  is formatted. Runs before module installation.
#
#  2XR, LLC | Evolve2Linux | 123Tech.net
#  © 2018–2026 2XR, LLC. All Rights Reserved.
# =============================================================================

import libcalamares
import os
import subprocess
import json
from datetime import datetime, timezone

RESTORE_LABEL   = "SKYRESTORE"
RESTORE_SIZE_GB = 20
RESTORE_FS      = "vfat"


def find_target_disk(root_mount_point: str) -> str | None:
    """Find the block device that the root partition lives on."""
    try:
        result = subprocess.run(
            ["findmnt", "-n", "-o", "SOURCE", root_mount_point],
            capture_output=True, text=True, check=False
        )
        source = result.stdout.strip()
        if not source:
            return None
        # Strip partition suffix to get disk: /dev/sda2 → /dev/sda
        import re
        match = re.match(r"(/dev/[a-z]+)", source)
        return match.group(1) if match else None
    except Exception as e:
        libcalamares.utils.warning(f"skyrestore: find_target_disk error: {e}")
        return None


def create_restore_partition(disk: str) -> str | None:
    """
    Add a 20 GB FAT32 partition at the end of the disk using parted.
    Returns the new partition device path (e.g. /dev/sda4), or None on failure.
    """
    try:
        # Get current disk end in MB
        result = subprocess.run(
            ["parted", "-s", disk, "unit", "MB", "print"],
            capture_output=True, text=True, check=True
        )
        # Find the end of the last partition
        last_end_mb = 0
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 3 and parts[0].isdigit():
                try:
                    end_str = parts[2].rstrip("MB").rstrip("MiB")
                    last_end_mb = max(last_end_mb, float(end_str))
                except ValueError:
                    pass

        if last_end_mb == 0:
            libcalamares.utils.warning("skyrestore: could not determine last partition end")
            return None

        start_mb = int(last_end_mb) + 1
        end_mb   = start_mb + (RESTORE_SIZE_GB * 1024)

        libcalamares.utils.debug(
            f"skyrestore: creating partition {start_mb}MB–{end_mb}MB on {disk}"
        )

        # Create the partition
        subprocess.run(
            ["parted", "-s", disk,
             "mkpart", "primary", "fat32",
             f"{start_mb}MB", f"{end_mb}MB"],
            check=True
        )

        # Get the new partition number
        result2 = subprocess.run(
            ["parted", "-s", disk, "unit", "MB", "print"],
            capture_output=True, text=True, check=True
        )
        # Last numbered line = newest partition
        new_part_num = None
        for line in result2.stdout.splitlines():
            parts = line.split()
            if parts and parts[0].isdigit():
                new_part_num = int(parts[0])

        if new_part_num is None:
            libcalamares.utils.warning("skyrestore: could not determine new partition number")
            return None

        # Build device path: /dev/sda → /dev/sda4  or  /dev/nvme0n1 → /dev/nvme0n1p4
        import re
        if re.search(r"nvme|mmcblk", disk):
            new_part = f"{disk}p{new_part_num}"
        else:
            new_part = f"{disk}{new_part_num}"

        libcalamares.utils.debug(f"skyrestore: new partition device: {new_part}")
        return new_part

    except subprocess.CalledProcessError as e:
        libcalamares.utils.warning(f"skyrestore: parted error: {e}")
        return None


def format_restore_partition(partition: str) -> bool:
    """Format partition as FAT32 with SKYRESTORE label."""
    try:
        subprocess.run(
            ["mkfs.fat", "-F", "32", "-n", RESTORE_LABEL, partition],
            check=True, capture_output=True
        )
        libcalamares.utils.debug(f"skyrestore: formatted {partition} as FAT32 (label={RESTORE_LABEL})")
        return True
    except subprocess.CalledProcessError as e:
        libcalamares.utils.warning(f"skyrestore: mkfs.fat error: {e}")
        return False


def initialize_structure(mount_point: str, uuid: str, tier: str) -> None:
    """
    Create the SKYRESTORE directory layout and initial JSON records.
    """
    dirs = [
        "skyrestore/audits",
        "skyrestore/modules",
        "skyrestore/packages",
        "skyrestore/staging",
        "skyrestore/manifests",
        "boot-health",
        "isos",
    ]
    for d in dirs:
        os.makedirs(os.path.join(mount_point, d), exist_ok=True)

    now = datetime.now(timezone.utc).isoformat()

    # Write initial activation record
    activation = {
        "uuid":           uuid,
        "tier":           tier,
        "install_date":   now,
        "restore_label":  RESTORE_LABEL,
        "note":           "Written by Calamares installer — skyrestore module",
    }
    with open(os.path.join(mount_point, "skyrestore/manifests/activation.json"), "w") as f:
        json.dump(activation, f, indent=2)

    # Write empty modules.manifest
    with open(os.path.join(mount_point, "skyrestore/manifests/modules.manifest"), "w") as f:
        f.write(f"# SkyRESTORE Module Manifest\n# Initialized: {now}\n")

    # Write initial boot-health state (clean)
    with open(os.path.join(mount_point, "boot-health/last-good-boot"), "w") as f:
        f.write(now)

    # Write README on the root of the FAT partition
    readme = (
        "SkyRESTORE — SkyCAIR OS Recovery Partition\n"
        "2XR, LLC | Evolve2Linux | 123Tech.net\n"
        "\n"
        "DO NOT DELETE OR MODIFY THESE FILES.\n"
        "\n"
        "skyrestore/          Boot audit records + module cache\n"
        "  audits/            Pre/post change audit trail\n"
        "  modules/           Signed .xzm module cache for recovery\n"
        "  manifests/         activation.json, modules.manifest\n"
        "  staging/           Pending module updates\n"
        "boot-health/         Boot failure tracking (read by GRUB2)\n"
        "isos/                Recovery ISO (skycair-recovery.iso)\n"
        "\n"
        "Recovery: Boot fails 3 times → GRUB auto-selects SkyRESTORE Recovery\n"
        "Manual:   skyair modules restore   (from running OS)\n"
        "          skyrestore-cli            (from recovery ISO)\n"
    )
    with open(os.path.join(mount_point, "README.txt"), "w") as f:
        f.write(readme)

    libcalamares.utils.debug("skyrestore: directory structure initialized")


def add_fstab_entry(target_root: str, partition: str) -> None:
    """Add SKYRESTORE mount entry to /etc/fstab on the target system."""
    fstab_path = os.path.join(target_root, "etc", "fstab")
    entry = (
        f"\n# SkyRESTORE — Recovery + Audit Partition (FAT32)\n"
        f"LABEL={RESTORE_LABEL}  /mnt/skyrestore  vfat  "
        f"noauto,ro,uid=0,gid=0,fmask=0133,dmask=0022,shortname=mixed  0 0\n"
    )
    if os.path.exists(fstab_path):
        with open(fstab_path, "a") as f:
            f.write(entry)
        libcalamares.utils.debug("skyrestore: fstab entry added")


def run():
    gs = libcalamares.globalstorage
    target_root  = gs.value("rootMountPoint") or "/tmp/calamares-root"
    uuid         = gs.value("skyDeviceUUID")  or "pending-activation"
    tier         = gs.value("skyTier")        or "skycair-e2l"

    libcalamares.utils.debug(
        f"skyrestore: creating {RESTORE_SIZE_GB}GB SKYRESTORE partition "
        f"on disk for target={target_root}"
    )

    # 1. Find the installation disk
    disk = find_target_disk(target_root)
    if not disk:
        libcalamares.utils.warning(
            "skyrestore: could not determine target disk — skipping partition creation. "
            "SKYRESTORE partition must be created manually."
        )
        gs.insert("skyRestorePartitionCreated", False)
        return None

    # 2. Create the partition
    partition = create_restore_partition(disk)
    if not partition:
        libcalamares.utils.warning("skyrestore: partition creation failed — skipping")
        gs.insert("skyRestorePartitionCreated", False)
        return None

    # 3. Format as FAT32
    if not format_restore_partition(partition):
        libcalamares.utils.warning("skyrestore: format failed — skipping")
        gs.insert("skyRestorePartitionCreated", False)
        return None

    # 4. Mount and initialize directory structure
    mount_point = "/tmp/skyrestore-init"
    os.makedirs(mount_point, exist_ok=True)
    try:
        subprocess.run(
            ["mount", "-t", "vfat", partition, mount_point],
            check=True, capture_output=True
        )
        initialize_structure(mount_point, uuid, tier)
    except subprocess.CalledProcessError as e:
        libcalamares.utils.warning(f"skyrestore: mount/init error: {e}")
        gs.insert("skyRestorePartitionCreated", False)
        return None
    finally:
        subprocess.run(["umount", mount_point], check=False, capture_output=True)

    # 5. Add fstab entry to target system
    add_fstab_entry(target_root, partition)

    # 6. Store results for downstream modules
    gs.insert("skyRestorePartition",        partition)
    gs.insert("skyRestorePartitionCreated", True)
    gs.insert("skyRestoreLabel",            RESTORE_LABEL)

    libcalamares.utils.debug(
        f"skyrestore: ✓ partition {partition} created, formatted, initialized"
    )
    return None


def pretty_name():
    return f"Creating SkyRESTORE recovery partition ({RESTORE_SIZE_GB} GB FAT32)..."
