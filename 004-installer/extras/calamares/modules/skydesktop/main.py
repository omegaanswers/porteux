#!/usr/bin/env python3
# =============================================================================
#  SkyCAIR OS — Calamares Module: skydesktop
#  Desktop/Boot Mode Selection
#
#  Presents three boot mode options during install:
#    server  (DEFAULT) — headless, WebRTC COSMIC accessible from any browser
#    full               — kiosk physical display → Mission Control + WebRTC
#    cli                — no GUI, tty/SSH only
#
#  Writes SKYDESKTOP_MODE to /etc/skycair/skydesktop.env on target system.
#  Also enables/disables the appropriate systemd services.
#
#  2XR, LLC | Evolve2Linux | 123Tech.net
# =============================================================================

import libcalamares
import os
import subprocess

# Mode definitions — displayed in Calamares QML page
DESKTOP_MODES = {
    "server": {
        "label":       "Server (Recommended)",
        "subtitle":    "Headless — WebRTC COSMIC Desktop from any browser",
        "description": (
            "SkyCAIR OS boots as a headless server. "
            "No physical display required. "
            "Mission Control and the COSMIC Desktop are accessible from "
            "any browser on your network at https://<host>:8443/mc/ "
            "and the COSMIC Desktop tab streams via WebRTC. "
            "Best for: dedicated servers, mini PCs without monitors, "
            "virtual machines, remote management deployments."
        ),
        "icon":        "server",
        "default":     True,
    },
    "full": {
        "label":       "Full Kiosk",
        "subtitle":    "Physical display boots directly to Mission Control",
        "description": (
            "SkyCAIR OS boots to a full-screen Mission Control dashboard "
            "on the physical display (Sway kiosk → Chromium). "
            "The COSMIC Desktop tab is accessible via WebRTC in the browser. "
            "Best for: dedicated SkyCAIR workstations, reception kiosks, "
            "digital signage, always-on displays."
        ),
        "icon":        "monitor",
        "default":     False,
    },
    "cli": {
        "label":       "CLI Only",
        "subtitle":    "Text mode — no GUI, no WebRTC, tty/SSH access only",
        "description": (
            "SkyCAIR OS boots to a terminal login prompt. "
            "No graphical interface, no WebRTC desktop stream. "
            "Containers and services still run (SkyOMEGAi, SkyVAULT, etc.). "
            "Best for: data center servers, embedded systems, "
            "advanced users who manage via SSH only."
        ),
        "icon":        "terminal",
        "default":     False,
    },
}

# Slackware BSD init: rc.d scripts enabled = chmod 755, disabled = chmod 644
# No systemd. No .service files. No systemctl.
MODE_RC_SCRIPTS = {
    "server": {
        "enable":  ["rc.skydesktop"],   # headless WebRTC stream
        "disable": ["rc.skykiosk"],     # no physical kiosk display
    },
    "full": {
        "enable":  ["rc.skykiosk", "rc.skydesktop"],  # kiosk + WebRTC
        "disable": [],
    },
    "cli": {
        "enable":  [],
        "disable": ["rc.skykiosk", "rc.skydesktop"],  # no GUI at all
    },
}


def write_skydesktop_env(target_root: str, mode: str, config: dict) -> None:
    """Write /etc/skycair/skydesktop.env to the target system."""
    env_dir = os.path.join(target_root, "etc", "skycair")
    os.makedirs(env_dir, exist_ok=True)
    env_path = os.path.join(env_dir, "skydesktop.env")

    lines = [
        "# SkyDESKTOP — configured by Calamares installer",
        f"# Mode selected during install: {mode}",
        "",
        f"SKYDESKTOP_MODE={mode}",
        f"SKYDESKTOP_PORT={config.get('port', 8700)}",
        f"SKYDESKTOP_WIDTH={config.get('width', 1920)}",
        f"SKYDESKTOP_HEIGHT={config.get('height', 1080)}",
        f"SKYDESKTOP_FPS={config.get('fps', 30)}",
        f"SKYDESKTOP_ENCODER={config.get('encoder', 'auto')}",
        f"SKYDESKTOP_DPMS_TIMEOUT={config.get('dpms_timeout', 300)}",
        f"MISSION_CONTROL_URL=https://localhost:8443/mc/",
        f"WESTON_SOCKET=weston-0",
        "",
    ]

    with open(env_path, "w") as f:
        f.write("\n".join(lines))

    libcalamares.utils.debug(f"skydesktop: wrote {env_path} (mode={mode})")


def apply_rc_services(target_root: str, mode: str) -> None:
    """Enable/disable Slackware BSD init rc.d scripts for the selected mode.

    Slackware init: executable = enabled at boot, non-executable = disabled.
    NO systemd. NO .service files. NO systemctl.
    Scripts live in /etc/rc.d/ and are called from rc.local or rc.4.
    """
    rc_config = MODE_RC_SCRIPTS.get(mode, MODE_RC_SCRIPTS["server"])
    rc_dir = os.path.join(target_root, "etc", "rc.d")

    for script in rc_config["enable"]:
        script_path = os.path.join(rc_dir, script)
        if os.path.exists(script_path):
            os.chmod(script_path, 0o755)   # chmod 755 = enabled
            libcalamares.utils.debug(f"skydesktop: enabled {script} (chmod 755)")
        else:
            libcalamares.utils.warning(f"skydesktop: rc script not found: {script_path}")

    for script in rc_config["disable"]:
        script_path = os.path.join(rc_dir, script)
        if os.path.exists(script_path):
            os.chmod(script_path, 0o644)   # chmod 644 = disabled
            libcalamares.utils.debug(f"skydesktop: disabled {script} (chmod 644)")


def apply_greetd_config(target_root: str, mode: str) -> None:
    """Point /etc/greetd/config.toml to the correct greetd template for mode."""
    greetd_dir = os.path.join(target_root, "etc", "greetd")
    os.makedirs(greetd_dir, exist_ok=True)

    if mode == "full":
        # Kiosk greetd: autologin → start-kiosk.sh → Sway → Chromium
        template_src = os.path.join(
            target_root, "usr", "lib", "skycair", "greetd-kiosk.toml"
        )
        if os.path.exists(template_src):
            subprocess.run(
                ["cp", template_src,
                 os.path.join(greetd_dir, "config.toml")],
                check=False
            )
    elif mode == "server":
        # Server greetd: autologin → bash (no graphical session on local display)
        server_toml = os.path.join(greetd_dir, "config.toml")
        with open(server_toml, "w") as f:
            f.write(
                "[terminal]\nvt = 1\n\n"
                "[default_session]\n"
                "command = \"/bin/bash --login\"\n"
                "user = \"skycair\"\n"
            )
    # cli mode: greetd not used (getty handles tty login)

    libcalamares.utils.debug(f"skydesktop: greetd configured for mode={mode}")


def run():
    gs = libcalamares.globalstorage
    target_root = gs.value("rootMountPoint") or "/tmp/calamares-root"

    # Read user selection from QML page (set by skydesktop QML component)
    mode = gs.value("skyDesktopMode") or "server"

    # Validate
    if mode not in DESKTOP_MODES:
        libcalamares.utils.warning(
            f"skydesktop: unknown mode '{mode}', defaulting to 'server'"
        )
        mode = "server"

    # Hardware-detected config (resolution, encoder from skyhardware module)
    hw = gs.value("skyHardware") or {}
    config = {
        "port":         8700,
        "width":        hw.get("display_width", 1920),
        "height":       hw.get("display_height", 1080),
        "fps":          30,
        "encoder":      hw.get("recommended_encoder", "auto"),
        "dpms_timeout": 300,
    }

    libcalamares.utils.debug(
        f"skydesktop: applying mode='{mode}' "
        f"resolution={config['width']}x{config['height']} "
        f"encoder={config['encoder']}"
    )

    # 1. Write /etc/skycair/skydesktop.env
    write_skydesktop_env(target_root, mode, config)

    # 2. Enable/disable Slackware rc.d scripts (chmod 755/644 — no systemd)
    apply_rc_services(target_root, mode)

    # 3. Configure greetd
    apply_greetd_config(target_root, mode)

    # 4. Store selection for downstream modules
    gs.insert("skyDesktopModeApplied", mode)
    gs.insert("skyDesktopModeLabel", DESKTOP_MODES[mode]["label"])

    return None


def pretty_name():
    mode = libcalamares.globalstorage.value("skyDesktopMode") or "server"
    return f"Configuring SkyDESKTOP — {DESKTOP_MODES.get(mode, {}).get('label', mode)} mode..."
