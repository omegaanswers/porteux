#!/usr/bin/env python3
# SkyCAIR OS — Calamares SkyAPI UUID Registration Module
# Registers device with SkyAPI at skyapi.123tech.net or generates local UUID
# UUID unlocks licensed software repos at packages.123tech.net per tier
# 2XR, LLC | Evolve2Linux | 123Tech.net

import libcalamares
import subprocess
import uuid
import json
import os

SKYAPI_URL = "https://skyapi.123tech.net/api/v1/register"
UUID_FILE  = "/etc/skycair/device-uuid"

def generate_hardware_uuid():
    """Generate a stable hardware-based UUID from DMI product UUID or MAC address"""
    # Try DMI (BIOS product UUID — stable across reinstalls)
    try:
        result = subprocess.run(
            ["dmidecode", "-s", "system-uuid"],
            capture_output=True, text=True, timeout=5
        )
        hw_uuid = result.stdout.strip()
        if hw_uuid and hw_uuid != "Not Settable":
            return hw_uuid
    except:
        pass

    # Fallback: MAC-based UUID (stable per NIC)
    try:
        result = subprocess.run(
            ["ip", "link", "show"],
            capture_output=True, text=True, timeout=5
        )
        mac = None
        for line in result.stdout.splitlines():
            if "link/ether" in line and "00:00:00:00:00:00" not in line:
                mac = line.split()[1]
                break
        if mac:
            mac_int = int(mac.replace(":", ""), 16)
            return str(uuid.UUID(int=mac_int, version=1))
    except:
        pass

    return str(uuid.uuid4())

def register_with_skyapi(device_uuid, tier, email=None):
    """Attempt to register UUID with SkyAPI — returns True if successful"""
    try:
        payload = json.dumps({
            "uuid": device_uuid,
            "tier": tier,
            "email": email or "",
            "os": "SkyCAIR-EODv9",
            "installer_version": "9.0.0",
        })
        result = subprocess.run(
            ["curl", "-sf", "--max-time", "10",
             "-X", "POST", SKYAPI_URL,
             "-H", "Content-Type: application/json",
             "-d", payload],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode == 0:
            response = json.loads(result.stdout)
            return response.get("status") == "registered", response
    except:
        pass
    return False, {}

def run():
    gs = libcalamares.globalstorage

    hw = gs.value("skyHardware") or {}
    tier = hw.get("recommended_tier", "skyair")

    # Get user-entered values from the QML page (set by skyapi.qml)
    email      = gs.value("skyApiEmail") or ""
    account_id = gs.value("skyApiAccountId") or ""

    # Generate/use device UUID
    device_uuid = generate_hardware_uuid()
    libcalamares.utils.debug(f"SkyAPI UUID: {device_uuid}")

    # Attempt online registration
    registered, response = register_with_skyapi(device_uuid, tier, email)

    if registered:
        repo_access = response.get("repo_access", ["free"])
        libcalamares.utils.debug(f"SkyAPI registration OK — repos: {repo_access}")
    else:
        # Offline mode — UUID saved locally, registers on first boot
        libcalamares.utils.debug(
            "SkyAPI offline — UUID saved locally, will register on first boot"
        )
        repo_access = ["free"]

    # Store for post-install use
    gs.insert("skyApiUuid", device_uuid)
    gs.insert("skyApiRegistered", registered)
    gs.insert("skyApiRepoAccess", repo_access)
    gs.insert("skyApiEmail", email)
    gs.insert("skyApiAccountId", account_id)
    gs.insert("skyApiTier", tier)

    return None

def pretty_name():
    return "Registering device with SkyAPI (UUID entitlement)..."
