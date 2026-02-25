#!/usr/bin/env python3
# SkyCAIR OS — Calamares UUID Generation Module
# Generates and saves device UUID — NO cloud registration during install
#
# Activation model (Unraid-style, phone/email):
#   1. UUID generated here (TPM > DMI > MAC > random)
#   2. UUID saved to /etc/skycair/device-uuid
#   3. UUID displayed to user during install and on first boot
#   4. User activates via:
#        Phone: (608) 454-6660 (Central Time business hours)
#        Email: activate@123tech.net — include UUID in subject
#   5. 2XR LLC provides signed activation.key file
#   6. skymod-agent verifies key LOCALLY — no cloud polling ever
#
# This design builds trust through direct support contact.
# No telemetry. No 60-second polling. Full offline operation after activation.
#
# 2XR, LLC | Evolve2Linux | 123Tech.net | SkyCAIR@123Tech.net

import libcalamares
import subprocess
import uuid
import os

UUID_FILE = "/etc/skycair/device-uuid"

def generate_hardware_uuid():
    """Generate a stable hardware-based UUID (TPM > DMI > MAC > random)."""

    # 1. TPM2 NVRAM (hardware-bound, tamper-resistant)
    try:
        result = subprocess.run(
            ["tpm2_nvread", "0x1500016"],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (FileNotFoundError, Exception):
        pass

    # 2. DMI product UUID (BIOS-stable across reinstalls)
    try:
        result = subprocess.run(
            ["dmidecode", "-s", "system-uuid"],
            capture_output=True, text=True, timeout=5
        )
        hw_uuid = result.stdout.strip()
        if hw_uuid and hw_uuid not in ("", "Not Settable", "00000000-0000-0000-0000-000000000000"):
            return hw_uuid
    except Exception:
        pass

    # 3. MAC-based UUID (stable per NIC)
    try:
        result = subprocess.run(
            ["ip", "link", "show"],
            capture_output=True, text=True, timeout=5
        )
        for line in result.stdout.splitlines():
            if "link/ether" in line and "00:00:00:00:00:00" not in line:
                mac = line.split()[1]
                mac_int = int(mac.replace(":", ""), 16)
                return str(uuid.UUID(int=mac_int | (5 << 122)))
    except Exception:
        pass

    # 4. Random UUID (always works)
    return str(uuid.uuid4())


def run():
    gs = libcalamares.globalstorage

    hw   = gs.value("skyHardware") or {}
    tier = hw.get("recommended_tier", "skyair")

    # Generate device UUID
    device_uuid = generate_hardware_uuid()
    libcalamares.utils.debug(f"SkyCAIR UUID: {device_uuid[:8]}...{device_uuid[-4:]}")

    # Save UUID to the target system
    os.makedirs(os.path.dirname(UUID_FILE), exist_ok=True)
    with open(UUID_FILE, "w") as f:
        f.write(device_uuid + "\n")
    os.chmod(UUID_FILE, 0o600)

    # Display activation instructions in installer log
    libcalamares.utils.debug(
        f"\n"
        f"╔══════════════════════════════════════════════════════════════════╗\n"
        f"║  SkyCAIR OS — Activation Instructions                          ║\n"
        f"║  Your Device UUID:  {device_uuid:<44}  ║\n"
        f"║                                                                  ║\n"
        f"║  To activate after installation:                                ║\n"
        f"║    Phone: (608) 454-6660  (Central Time business hours)         ║\n"
        f"║    Email: activate@123tech.net  (include UUID in subject)       ║\n"
        f"║                                                                  ║\n"
        f"║  SkyCAIR runs in GRACE MODE until activated.                    ║\n"
        f"║  Grace mode: core modules available (kernel, security, GUI)     ║\n"
        f"╚══════════════════════════════════════════════════════════════════╝"
    )

    # Store in globalstorage for post-install steps
    gs.insert("skyApiUuid",       device_uuid)
    gs.insert("skyApiTier",       tier)
    gs.insert("skyApiRegistered", False)           # Activation done post-install by user
    gs.insert("skyApiRepoAccess", ["grace"])        # Grace until activation key received

    return None


def pretty_name():
    return "Generating device UUID — phone/email activation at (608) 454-6660..."
