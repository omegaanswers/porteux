#!/usr/bin/env python3
# SkyCAIR OS — Calamares Module Selection + Deployment Module
# Reads hardware detection results and user selections,
# downloads and deploys .xzm modules to the installed system.
# 2XR, LLC | Evolve2Linux | 123Tech.net

import libcalamares
import subprocess
import os
import json

SKYMOD_REPO  = "https://packages.123tech.net/skymod"
MODULES_DIR  = "/skycair"    # On the live system root (install source)
TARGET_MODS  = ""            # Set by partition step

# Module catalog — what's available per tier
MODULE_CATALOG = {
    "000-kernel": {
        "desc": "SkyCAIR Kernel (required)",
        "required": True,
        "tiers": ["iot", "skyair", "skygrid", "skystack"],
    },
    "001-core": {
        "desc": "Core system utilities (required)",
        "required": True,
        "tiers": ["iot", "skyair", "skygrid", "skystack"],
    },
    "002-gui": {
        "desc": "GUI base libraries",
        "required": False,
        "tiers": ["skyair", "skygrid", "skystack"],
    },
    "003-cosmic": {
        "desc": "COSMIC Desktop Environment",
        "required": False,
        "tiers": ["skyair", "skygrid", "skystack"],
    },
    "003-skyomegai": {
        "desc": "SkyOMEGAi — Private AI (Ollama + Open WebUI + Claude API)",
        "required": False,
        "tiers": ["skyair", "skygrid", "skystack"],
    },
    "003-skyomegai-nvidia": {
        "desc": "SkyOMEGAi — NVIDIA CUDA Acceleration",
        "required": False,
        "tiers": ["skygrid", "skystack"],
    },
    "003-skyomegai-amd": {
        "desc": "SkyOMEGAi — AMD ROCm Acceleration",
        "required": False,
        "tiers": ["skygrid", "skystack"],
    },
    "003-skyomegai-rknn": {
        "desc": "SkyOMEGAi — Rockchip NPU / M.2 AI Accelerator",
        "required": False,
        "tiers": ["iot", "skyair", "skygrid", "skystack"],
    },
    "nvidia-driver": {
        "desc": "NVIDIA Proprietary Driver (requires NVIDIA GPU)",
        "required": False,
        "tiers": ["skyair", "skygrid", "skystack"],
    },
    "0050-multilib": {
        "desc": "32-bit compatibility libraries (Steam, Wine)",
        "required": False,
        "tiers": ["skyair", "skygrid", "skystack"],
    },
    "05-devel": {
        "desc": "Development tools (gcc, make, git, python)",
        "required": False,
        "tiers": ["skygrid", "skystack"],
    },
    "003-skyshield": {
        "desc": "SkySHIELD-ATF (Attack Threat Foundation) — nftables firewall, encrypted DNS, SSH hardening",
        "required": True,
        "tiers": ["iot", "skyair", "skygrid", "skystack"],
    },
    "004-installer": {
        "desc": "Calamares installer (remove after install)",
        "required": False,
        "tiers": ["skyair", "skygrid", "skystack"],
    },
}

def get_available_modules(tier, repo_access):
    """Return modules available for this tier and repo access"""
    available = []
    for mod_id, mod_info in MODULE_CATALOG.items():
        if tier in mod_info["tiers"]:
            available.append({
                "id": mod_id,
                "desc": mod_info["desc"],
                "required": mod_info["required"],
            })
    return available

def deploy_modules(selected_modules, target_root, skymod_repo):
    """Copy selected .xzm modules to the installed system"""
    target_mods_dir = os.path.join(target_root, "skycair")
    os.makedirs(target_mods_dir, exist_ok=True)

    deployed = []
    for mod_id in selected_modules:
        # First check if module exists in live system
        live_path = f"{MODULES_DIR}/{mod_id}*.xzm"
        result = subprocess.run(
            f"ls {live_path} 2>/dev/null | head -1",
            shell=True, capture_output=True, text=True
        )
        live_xzm = result.stdout.strip()

        if live_xzm and os.path.exists(live_xzm):
            # Copy from live system
            subprocess.run(["cp", live_xzm, target_mods_dir], check=False)
            deployed.append(mod_id)
            libcalamares.utils.debug(f"Deployed {mod_id} from live system")
        else:
            # Download from SkyRepo (packages.123tech.net)
            libcalamares.utils.debug(
                f"Module {mod_id} not in live system — will download on first boot"
            )

    return deployed

def run():
    gs = libcalamares.globalstorage

    hw         = gs.value("skyHardware") or {}
    tier       = gs.value("skyApiTier") or hw.get("recommended_tier", "skyair")
    repo_access = gs.value("skyApiRepoAccess") or ["free"]

    # User-selected modules (from QML checkboxes)
    selected = gs.value("skySelectedModules") or hw.get("recommended_modules", [])

    # Available for this tier
    available = get_available_modules(tier, repo_access)

    # Always include required modules
    final_modules = [
        m["id"] for m in available if m["required"]
    ]
    # Add user-selected
    for mod_id in selected:
        if mod_id not in final_modules:
            final_modules.append(mod_id)

    libcalamares.utils.debug(f"Final module list: {final_modules}")
    gs.insert("skyFinalModules", final_modules)

    # Write module list for post-install
    gs.insert("skyModuleCount", len(final_modules))

    return None

def pretty_name():
    return "Selecting SkyCAIR OS modules for your hardware..."
