#!/usr/bin/env python3
# SkyCAIR OS — Calamares Hardware Detection Module
# Detects CPU, GPU, RAM, storage, NPU — recommends SkySTACK tier
# 2XR, LLC | Evolve2Linux | 123Tech.net

import libcalamares
import subprocess
import os
import re

def detect_cpu():
    try:
        with open("/proc/cpuinfo") as f:
            info = f.read()
        model = re.search(r"model name\s*:\s*(.+)", info)
        cores = len(re.findall(r"^processor", info, re.MULTILINE))
        return model.group(1).strip() if model else "Unknown CPU", cores
    except:
        return "Unknown CPU", 1

def detect_ram_gb():
    try:
        with open("/proc/meminfo") as f:
            mem = f.read()
        total = re.search(r"MemTotal:\s+(\d+)", mem)
        return int(total.group(1)) // 1024 // 1024 if total else 0
    except:
        return 0

def detect_gpu():
    gpus = []
    try:
        result = subprocess.run(
            ["lspci", "-mm"], capture_output=True, text=True, timeout=5
        )
        for line in result.stdout.splitlines():
            if any(x in line.lower() for x in ["vga", "display", "3d controller"]):
                if "nvidia" in line.lower():
                    gpus.append({"vendor": "nvidia", "name": line.split('"')[5] if '"' in line else "NVIDIA GPU"})
                elif "amd" in line.lower() or "radeon" in line.lower():
                    gpus.append({"vendor": "amd", "name": line.split('"')[5] if '"' in line else "AMD GPU"})
                elif "intel" in line.lower():
                    gpus.append({"vendor": "intel", "name": "Intel GPU"})
    except:
        pass
    return gpus

def detect_storage():
    drives = []
    try:
        result = subprocess.run(
            ["lsblk", "-o", "NAME,SIZE,TRAN,MODEL,ROTA", "--json"],
            capture_output=True, text=True, timeout=5
        )
        import json
        data = json.loads(result.stdout)
        for dev in data.get("blockdevices", []):
            if dev.get("type") == "disk" or "SIZE" in dev:
                tran = dev.get("tran", "")
                drives.append({
                    "name": dev.get("name", ""),
                    "size": dev.get("size", ""),
                    "transport": tran,
                    "nvme": tran == "nvme",
                    "usb": tran == "usb",
                    "model": dev.get("model", ""),
                })
    except:
        pass
    return drives

def resolve_bdf_to_block(bdf):
    """
    Map PCIe BDF address (e.g. '01:00.0') to NVMe block device (e.g. '/dev/nvme0n1').
    Uses sysfs symlinks under /sys/block/ which contain the PCIe path.
    """
    try:
        for blk in os.listdir("/sys/block"):
            if not blk.startswith("nvme"):
                continue
            try:
                link = os.readlink(f"/sys/block/{blk}")
                if bdf in link:
                    return f"/dev/{blk}"
            except OSError:
                continue
    except Exception:
        pass
    return ""


def detect_nvme_pcie():
    """
    Detect NVMe M.2 drives with PCIe gen and lane width.
    Returns list of dicts: {bdf, pcie_gen, lanes, speed_gbps, swap_tier, block_dev}

    SkyCAIR NVMe swap tier classification:
      PCIe 3.0 x4  →  ~3.5 GB/s  (~25µs)  — ALLOWED   (any NVMe, standard swap)
      PCIe 4.0 x4  →  ~7.0 GB/s  (~8µs)   — PREFERRED  (RAM-like speeds for AI offload)
      PCIe 4.0 x16 →  ~28.0 GB/s           — PREFERRED+ (ideal for large model offload)
      PCIe 5.0 x4  →  ~14.0 GB/s (~4µs)   — RECOMMENDED (super speed, Xeon W / Ryzen 7000+)
      PCIe 5.0 x16 →  ~56.0 GB/s           — RECOMMENDED (enterprise AI inference & training)
    """
    nvme_drives = []
    try:
        result = subprocess.run(
            ["lspci", "-vv"], capture_output=True, text=True, timeout=10
        )
        current_nvme = None

        for line in result.stdout.splitlines():
            # Find NVMe devices
            if "Non-Volatile memory controller" in line or "NVM Express" in line:
                bdf = line.split()[0]
                current_nvme = {"bdf": bdf, "pcie_gen": 0, "lanes": 0}

            if current_nvme and "LnkSta:" in line:
                # Parse link speed: "Speed 16GT/s (ok), Width x4 (ok)"
                speed_match = re.search(r"Speed (\d+(?:\.\d+)?)GT/s", line)
                width_match = re.search(r"Width x(\d+)", line)
                if speed_match:
                    gt_per_s = float(speed_match.group(1))
                    # Map GT/s → PCIe gen
                    if gt_per_s >= 32:
                        current_nvme["pcie_gen"] = 5
                    elif gt_per_s >= 16:
                        current_nvme["pcie_gen"] = 4
                    elif gt_per_s >= 8:
                        current_nvme["pcie_gen"] = 3
                    else:
                        current_nvme["pcie_gen"] = 2
                if width_match:
                    current_nvme["lanes"] = int(width_match.group(1))

                # Bandwidth: gen3=~1GB/s/lane, gen4=~2GB/s/lane, gen5=~4GB/s/lane
                bw_per_lane = {2: 0.5, 3: 1.0, 4: 2.0, 5: 4.0}
                gen = current_nvme["pcie_gen"]
                lns = current_nvme["lanes"]
                current_nvme["speed_gbps"] = bw_per_lane.get(gen, 1.0) * lns

                # Swap tier: all NVMe allowed; gen4/5 promoted
                if gen >= 5:
                    tier = "recommended"    # Super speed — Xeon W, Ryzen 7000+, AI training
                elif gen == 4 and lns >= 4:
                    tier = "preferred"      # RAM-like speeds for AI memory offload
                elif gen >= 3:
                    tier = "allowed"        # Standard NVMe swap (usable)
                else:
                    tier = "none"

                current_nvme["swap_tier"]         = tier
                current_nvme["suitable_for_swap"] = tier in ("allowed", "preferred", "recommended")
                current_nvme["recommended"]        = tier in ("preferred", "recommended")

                # Resolve BDF → block device path
                current_nvme["block_dev"] = resolve_bdf_to_block(current_nvme["bdf"])

                nvme_drives.append(current_nvme)
                current_nvme = None

    except Exception as e:
        libcalamares.utils.debug(f"NVMe PCIe detection error: {e}")

    return nvme_drives

def detect_npu():
    """Detect Rockchip RK3588 NPU or M.2 AI accelerators"""
    npu = {"found": False, "type": None, "tops": 0}
    try:
        if os.path.exists("/dev/rknpu0"):
            npu = {"found": True, "type": "rk3588-npu", "tops": 6}
        elif os.path.exists("/dev/hailo0"):
            npu = {"found": True, "type": "hailo-8", "tops": 26}
        else:
            # Check for RK3588 in /proc/device-tree
            dt_compat = "/proc/device-tree/compatible"
            if os.path.exists(dt_compat):
                with open(dt_compat, "rb") as f:
                    compat = f.read().decode("ascii", errors="replace")
                if "rk3588" in compat.lower():
                    npu = {"found": True, "type": "rk3588-npu", "tops": 6}
    except:
        pass
    return npu

def recommend_tier(cpu_cores, ram_gb, gpus, drives, npu):
    """Recommend SkySTACK tier based on detected hardware"""
    # SkyCAIR IoT: ARM, low RAM, no GPU
    cpu_name, _ = detect_cpu()
    if "aarch64" in os.uname().machine and ram_gb <= 4:
        return "iot", "SkyCAIR IoT — ARM64 edge device (RK3588 / Pi-class)"

    # SkySTACK-E2L: High-end server
    if cpu_cores >= 16 and ram_gb >= 32:
        return "skystack", "SkySTACK-E2L — Enterprise workstation / server"

    # SkyGRID-E2L: Mid-range with GPU
    if cpu_cores >= 8 and ram_gb >= 16 and len(gpus) > 0:
        return "skygrid", "SkyGRID-E2L — Professional workstation / AI-ready"

    # SkyAIR-E2L: Desktop/laptop
    if ram_gb >= 8:
        return "skyair", "SkyAIR-E2L — Desktop / laptop"

    return "skyair", "SkyAIR-E2L — Desktop (minimum spec)"

def recommend_modules(tier, gpus, npu, ram_gb):
    """Recommend .xzm modules to install based on hardware"""
    mods = ["000-kernel", "001-core", "002-gui", "003-cosmic"]

    # AI module based on hardware
    if npu["found"]:
        mods += ["003-skyomegai", "003-skyomegai-rknn"]
    elif any(g["vendor"] == "nvidia" for g in gpus):
        mods += ["nvidia-driver", "003-skyomegai", "003-skyomegai-nvidia"]
    elif any(g["vendor"] == "amd" for g in gpus):
        mods += ["003-skyomegai", "003-skyomegai-amd"]
    elif ram_gb >= 8:
        mods += ["003-skyomegai"]  # CPU inference

    # Installer always included
    mods.append("004-installer")

    return mods

def run():
    cpu_name, cpu_cores = detect_cpu()
    ram_gb = detect_ram_gb()
    gpus = detect_gpu()
    drives = detect_storage()
    npu = detect_npu()
    nvme_pcie = detect_nvme_pcie()
    tier, tier_desc = recommend_tier(cpu_cores, ram_gb, gpus, drives, npu)
    recommended_mods = recommend_modules(tier, gpus, npu, ram_gb)

    # NVMe swap tier logic
    # PCIe 3.0 = allowed, PCIe 4.0 x4+ = preferred (RAM-like), PCIe 5.0 = recommended
    # Xeon W-class / Ryzen 7000+ / AI inference platforms benefit most from gen4/5
    best_nvme = max(nvme_pcie, key=lambda d: d.get("speed_gbps", 0), default=None)
    nvme_swap_recommended = best_nvme and best_nvme.get("suitable_for_swap", False)
    nvme_swap_note = ""
    if best_nvme:
        gen   = best_nvme.get("pcie_gen", 0)
        lanes = best_nvme.get("lanes", 0)
        speed = best_nvme.get("speed_gbps", 0)
        tier  = best_nvme.get("swap_tier", "none")
        blk   = best_nvme.get("block_dev", "")
        if gen >= 5:
            nvme_swap_note = (
                f"PCIe {gen}.0 x{lanes} ({speed:.0f} GB/s) — RECOMMENDED: super speed "
                f"memory expansion for large AI models (Xeon W / Ryzen 7000+ class) ★★★"
            )
        elif gen == 4 and lanes >= 16:
            nvme_swap_note = f"PCIe 4.0 x{lanes} ({speed:.0f} GB/s) — PREFERRED: ideal AI memory offload ★★"
        elif gen == 4 and lanes >= 4:
            nvme_swap_note = f"PCIe 4.0 x4 ({speed:.0f} GB/s) — PREFERRED: RAM-like speeds for AI offload ★★"
        elif gen == 3:
            nvme_swap_note = f"PCIe 3.0 x{lanes} ({speed:.0f} GB/s) — ALLOWED: NVMe swap enabled"

    # Write env bridge file so shellprocess can consume hardware detection results
    # Calamares shellprocess runs as shell — it cannot read Python globalstorage directly
    nvme_swap_dev = best_nvme.get("block_dev", "") if best_nvme and nvme_swap_recommended else ""
    nvme_swap_tier = best_nvme.get("swap_tier", "none") if best_nvme else "none"
    nvme_pcie_gen  = best_nvme.get("pcie_gen", 0) if best_nvme else 0
    nvme_pcie_lanes = best_nvme.get("lanes", 0) if best_nvme else 0
    try:
        with open("/run/calamares-skyenv.sh", "w") as ef:
            ef.write("# SkyCAIR Calamares hardware env bridge — generated by skyhardware module\n")
            ef.write(f'export SKYCAIR_NVME_SWAP_DEVICE="{nvme_swap_dev}"\n')
            ef.write(f'export SKYCAIR_NVME_SWAP_TIER="{nvme_swap_tier}"\n')
            ef.write(f'export SKYCAIR_NVME_PCIE_GEN="{nvme_pcie_gen}"\n')
            ef.write(f'export SKYCAIR_NVME_PCIE_LANES="{nvme_pcie_lanes}"\n')
        libcalamares.utils.debug("Wrote /run/calamares-skyenv.sh")
    except Exception as env_err:
        libcalamares.utils.debug(f"Could not write calamares-skyenv.sh: {env_err}")

    hw = {
        "cpu_name":             cpu_name,
        "cpu_cores":            cpu_cores,
        "ram_gb":               ram_gb,
        "gpus":                 gpus,
        "drives":               drives,
        "npu":                  npu,
        "nvme_pcie":            nvme_pcie,
        "nvme_swap_recommended": nvme_swap_recommended,
        "nvme_swap_note":       nvme_swap_note,
        "recommended_tier":     tier,
        "recommended_tier_desc": tier_desc,
        "recommended_modules":  recommended_mods,
        "has_nvme":             any(d["nvme"] for d in drives if not d["usb"]),
    }

    libcalamares.globalstorage.insert("skyHardware", hw)

    libcalamares.utils.debug(
        f"SkyCAIR Hardware: {cpu_cores}c CPU, {ram_gb}GB RAM, "
        f"{len(gpus)} GPU(s), NPU={npu['type']}, Tier={tier}"
    )
    if nvme_swap_recommended:
        libcalamares.utils.debug(f"NVMe swap auto-enable: {nvme_swap_note}")

    return None

def pretty_name():
    return "Detecting hardware and recommending SkySTACK tier..."
