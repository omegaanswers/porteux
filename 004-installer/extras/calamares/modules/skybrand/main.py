#!/usr/bin/env python3
# =============================================================================
#  SkyCAIR OS — skybrand_personalization™ Calamares Module
#  © 2018–2026 2XR, LLC | SkySTACK™ | 123Tech.net
#
#  LICENSABLE FEATURE — skybrand_personalization™
#
#  Runs during Calamares post-install exec phase.
#  Reads brand variables from globalstorage (set by installer UI) OR
#  from /skycair/skybrand.conf (SkyLEGO parameter-loaded custom brand file).
#  Writes final skybrand.conf to target system and calls skybrand-apply.sh.
#
#  globalstorage keys consumed:
#    skybrand_company_name       — Reseller/white-label company name
#    skybrand_domain             — Custom domain (replaces 123tech.net)
#    skybrand_email              — Support email
#    skybrand_phone              — Support phone
#    skybrand_local_domain       — LAN DNS suffix (replaces skycair.local)
#    skybrand_host_ip            — Host IP (replaces 192.168.1.100)
#    skybrand_timezone           — Timezone (replaces America/Chicago)
#    skybrand_system_user        — Primary OS user (replaces skycair)
#    skybrand_product_suite      — Suite name (replaces SkySTACK)
#    skybrand_os_name            — OS name (replaces SkyCAIR)
#    skybrand_tagline            — Tagline
#    skybrand_conf_path          — Optional: path to pre-loaded .conf file
#    skybrand_license_tier       — Activation tier (SkyAIR-E2L, SkyGRID-E2L, etc.)
#
#  2XR, LLC | Evolve2Linux | 123Tech.net | SkyCAIR@123Tech.net
# =============================================================================

import libcalamares
import os
import subprocess
import shutil

# Factory defaults — must match skybrand.conf and skybrand-apply.sh
FACTORY = {
    "company_name":       "2XR, LLC",
    "brand_name":         "Evolve2Linux",
    "trademark":          "Evolve2Linux™",
    "copyright_year":     "2018–2026",
    "tagline":            "Knowledge Without Fear",
    "philosophy":         "Truth and Morality is Jesus Mentality — Follow Jesus!",
    "product_suite":      "SkySTACK",
    "os_name":            "SkyCAIR",
    "os_full":            "SkyCAIR OS",
    "os_version":         "EODv9",
    "component_name":     "skycair",
    "domain":             "123tech.net",
    "email":              "SkyCAIR@123Tech.net",
    "phone":              "(608) 454-6660",
    "address":            "855 Community Dr, Sauk City, WI 53583",
    "activation_email":   "activate@123tech.net",
    "alerts_email":       "skyalerts@123tech.net",
    "support_url":        "https://123tech.net/support",
    "product_url":        "https://123tech.net",
    "local_domain":       "skycair.local",
    "secondary_domain":   "skystack.local",
    "host_ip":            "192.168.1.100",
    "internal_subnet":    "192.168.1.0/24",
    "internal_gateway":   "192.168.1.1",
    "dns1":               "1.1.1.1",
    "dns2":               "9.9.9.9",
    "timezone":           "America/Chicago",
    "system_user":        "skycair",
    "system_uid":         "1000",
    "system_gid":         "1000",
    "samba_workgroup":    "SKYCAIR",
    "nas_name":           "SkyVAULT OffGrid NAS",
    "activation_url":     "https://skyapi.123tech.net/v1/entitlement",
    "license_tier":       "SkySTACK-E2L",
    "uuid_dir":           "/etc/skycair",
    "packages_url":       "packages.123tech.net",
    "container_prefix":   "skycair",
    "network_internal":   "skystack-internal",
    "compose_label_ns":   "com.skystack",
    "git_domain":         "git.skycair.local",
    "git_org":            "omegaanswers",
    "ntp_primary":        "tick.usno.navy.mil",
    "ntp_secondary":      "time.nist.gov",
}

SKYBRAND_APPLY = "/opt/skybrand/skybrand-apply.sh"
SKYBRAND_CONF_TARGET = "/opt/skybrand/skybrand.conf"
CHEATCODE_CONF = "/skycair/skybrand.conf"


def _gs(key, default=None):
    """Read from Calamares globalstorage with fallback."""
    val = libcalamares.globalstorage.value(f"skybrand_{key}")
    if val is None and default is not None:
        return default
    return val if val is not None else FACTORY.get(key, "")


def _load_conf_file(path):
    """Parse a skybrand.conf file into a dict."""
    conf = {}
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("#") or "=" not in line:
                    continue
                k, _, v = line.partition("=")
                v = v.strip('"').strip("'")
                # Strip SKYBRAND_ prefix, lowercase
                key = k.replace("SKYBRAND_", "").lower()
                conf[key] = v
    except OSError:
        pass
    return conf


def build_conf(brand):
    """Generate skybrand.conf content from brand dict."""
    lines = [
        "# =============================================================================",
        "#  skybrand.conf — Applied by skybrand_personalization™ Calamares Module",
        f"#  Applied: Calamares install",
        "#  © 2018–2026 2XR, LLC | SkySTACK™",
        "# =============================================================================",
        "",
        "# ── IDENTITY ────────────────────────────────────────────────────────────────",
        f'SKYBRAND_COMPANY_NAME="{brand.get("company_name", FACTORY["company_name"])}"',
        f'SKYBRAND_BRAND_NAME="{brand.get("brand_name", FACTORY["brand_name"])}"',
        f'SKYBRAND_TRADEMARK="{brand.get("trademark", FACTORY["trademark"])}"',
        f'SKYBRAND_COPYRIGHT_YEAR="{brand.get("copyright_year", FACTORY["copyright_year"])}"',
        f'SKYBRAND_TAGLINE="{brand.get("tagline", FACTORY["tagline"])}"',
        f'SKYBRAND_PHILOSOPHY="{brand.get("philosophy", FACTORY["philosophy"])}"',
        "",
        "# ── PRODUCT SUITE ───────────────────────────────────────────────────────────",
        f'SKYBRAND_PRODUCT_SUITE="{brand.get("product_suite", FACTORY["product_suite"])}"',
        f'SKYBRAND_OS_NAME="{brand.get("os_name", FACTORY["os_name"])}"',
        f'SKYBRAND_OS_FULL="{brand.get("os_full", FACTORY["os_full"])}"',
        f'SKYBRAND_OS_VERSION="{brand.get("os_version", FACTORY["os_version"])}"',
        f'SKYBRAND_COMPONENT_NAME="{brand.get("component_name", FACTORY["component_name"])}"',
        "",
        "# ── CONTACT ────────────────────────────────────────────────────────────────",
        f'SKYBRAND_DOMAIN="{brand.get("domain", FACTORY["domain"])}"',
        f'SKYBRAND_EMAIL="{brand.get("email", FACTORY["email"])}"',
        f'SKYBRAND_PHONE="{brand.get("phone", FACTORY["phone"])}"',
        f'SKYBRAND_ADDRESS="{brand.get("address", FACTORY["address"])}"',
        f'SKYBRAND_ACTIVATION_EMAIL="{brand.get("activation_email", FACTORY["activation_email"])}"',
        f'SKYBRAND_ALERTS_EMAIL="{brand.get("alerts_email", FACTORY["alerts_email"])}"',
        f'SKYBRAND_SUPPORT_URL="{brand.get("support_url", FACTORY["support_url"])}"',
        f'SKYBRAND_PRODUCT_URL="{brand.get("product_url", FACTORY["product_url"])}"',
        "",
        "# ── NETWORK / DNS ──────────────────────────────────────────────────────────",
        f'SKYBRAND_LOCAL_DOMAIN="{brand.get("local_domain", FACTORY["local_domain"])}"',
        f'SKYBRAND_SECONDARY_DOMAIN="{brand.get("secondary_domain", FACTORY["secondary_domain"])}"',
        f'SKYBRAND_HOST_IP="{brand.get("host_ip", FACTORY["host_ip"])}"',
        f'SKYBRAND_INTERNAL_SUBNET="{brand.get("internal_subnet", FACTORY["internal_subnet"])}"',
        f'SKYBRAND_INTERNAL_GATEWAY="{brand.get("internal_gateway", FACTORY["internal_gateway"])}"',
        f'SKYBRAND_DNS1="{brand.get("dns1", FACTORY["dns1"])}"',
        f'SKYBRAND_DNS2="{brand.get("dns2", FACTORY["dns2"])}"',
        f'SKYBRAND_TIMEZONE="{brand.get("timezone", FACTORY["timezone"])}"',
        "",
        "# ── SYSTEM USER ────────────────────────────────────────────────────────────",
        f'SKYBRAND_SYSTEM_USER="{brand.get("system_user", FACTORY["system_user"])}"',
        f'SKYBRAND_SYSTEM_UID="{brand.get("system_uid", FACTORY["system_uid"])}"',
        f'SKYBRAND_SYSTEM_GID="{brand.get("system_gid", FACTORY["system_gid"])}"',
        f'SKYBRAND_SAMBA_WORKGROUP="{brand.get("samba_workgroup", FACTORY["samba_workgroup"])}"',
        f'SKYBRAND_NAS_NAME="{brand.get("nas_name", FACTORY["nas_name"])}"',
        "",
        "# ── ACTIVATION ─────────────────────────────────────────────────────────────",
        f'SKYBRAND_ACTIVATION_URL="{brand.get("activation_url", FACTORY["activation_url"])}"',
        f'SKYBRAND_LICENSE_TIER="{brand.get("license_tier", FACTORY["license_tier"])}"',
        f'SKYBRAND_UUID_DIR="{brand.get("uuid_dir", FACTORY["uuid_dir"])}"',
        f'SKYBRAND_PACKAGES_URL="{brand.get("packages_url", FACTORY["packages_url"])}"',
        "",
        "# ── INFRASTRUCTURE ─────────────────────────────────────────────────────────",
        f'SKYBRAND_CONTAINER_PREFIX="{brand.get("container_prefix", FACTORY["container_prefix"])}"',
        f'SKYBRAND_NETWORK_INTERNAL="{brand.get("network_internal", FACTORY["network_internal"])}"',
        f'SKYBRAND_COMPOSE_LABEL_NS="{brand.get("compose_label_ns", FACTORY["compose_label_ns"])}"',
        f'SKYBRAND_GIT_DOMAIN="{brand.get("git_domain", FACTORY["git_domain"])}"',
        f'SKYBRAND_GIT_ORG="{brand.get("git_org", FACTORY["git_org"])}"',
        f'SKYBRAND_NTP_PRIMARY="{brand.get("ntp_primary", FACTORY["ntp_primary"])}"',
        f'SKYBRAND_NTP_SECONDARY="{brand.get("ntp_secondary", FACTORY["ntp_secondary"])}"',
    ]
    return "\n".join(lines) + "\n"


def run():
    """Main Calamares job entry point."""
    libcalamares.utils.debug("skybrand_personalization™: starting")

    target = libcalamares.globalstorage.value("rootMountPoint") or "/"

    # Priority 1: SkyLEGO parameter file on boot media
    brand = {}
    SkyLEGO parameter_path = libcalamares.globalstorage.value("skybrand_conf_path") or CHEATCODE_CONF
    if os.path.exists(SkyLEGO parameter_path):
        libcalamares.utils.debug(f"skybrand: loading custom conf from {SkyLEGO parameter_path}")
        brand = _load_conf_file(SkyLEGO parameter_path)

    # Priority 2: values set by Calamares UI pages (override file)
    gs_keys = [
        "company_name", "domain", "email", "phone", "local_domain",
        "host_ip", "timezone", "system_user", "product_suite", "os_name",
        "tagline", "license_tier", "dns1", "dns2",
    ]
    for key in gs_keys:
        val = libcalamares.globalstorage.value(f"skybrand_{key}")
        if val:
            brand[key] = val

    # Write skybrand.conf to target system
    conf_dir = os.path.join(target, "opt", "skybrand")
    os.makedirs(conf_dir, exist_ok=True)

    conf_path = os.path.join(conf_dir, "skybrand.conf")
    conf_content = build_conf(brand)
    with open(conf_path, "w") as f:
        f.write(conf_content)
    libcalamares.utils.debug(f"skybrand: wrote {conf_path}")

    # Copy apply script to target
    apply_src = os.path.join(
        os.path.dirname(__file__), "..", "..", "..", "..",
        "config", "skybrand", "skybrand-apply.sh"
    )
    apply_src = os.path.normpath(apply_src)
    apply_dst = os.path.join(conf_dir, "skybrand-apply.sh")
    if os.path.exists(apply_src):
        shutil.copy2(apply_src, apply_dst)
        os.chmod(apply_dst, 0o755)

    # Run skybrand-apply.sh inside chroot target
    if os.path.exists(apply_dst) and any(v != FACTORY.get(k) for k, v in brand.items()):
        libcalamares.utils.debug("skybrand: running apply script in chroot")
        try:
            subprocess.run(
                ["chroot", target, "/opt/skybrand/skybrand-apply.sh",
                 "--conf", "/opt/skybrand/skybrand.conf",
                 "--scope", "all"],
                check=True, timeout=120
            )
        except subprocess.CalledProcessError as e:
            libcalamares.utils.warning(f"skybrand-apply.sh failed: {e}")
        except subprocess.TimeoutExpired:
            libcalamares.utils.warning("skybrand-apply.sh timed out")
    else:
        libcalamares.utils.debug("skybrand: factory defaults — no changes needed")

    return None  # Success
