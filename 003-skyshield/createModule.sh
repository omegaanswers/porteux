#!/bin/bash
# SkyCAIR OS — 003-skyshield Module Builder
# SkySHIELD ATF: nftables firewall + encrypted DNS + SSH hardening
# FIPS/CIS/HIPAA/Government closed-loop security defaults
# 2XR, LLC | Evolve2Linux | 123Tech.net

MODULENAME="003-skyshield"
MODULEDIR="$(dirname "$(realpath "$0")")"
OUTPUTDIR="${MODULEDIR}/../tmp/modules"
BUILDDIR="/tmp/skyshield-build"

source "${MODULEDIR}/../builder-utils/setflags.sh"

echo "Building ${MODULENAME}.xzm — SkySHIELD ATF security module"

mkdir -p "$BUILDDIR" "$OUTPUTDIR"

# ── 1. Download dnscrypt-proxy binary ────────────────────────────────────────
# dnscrypt-proxy 2.x — Go binary, no external dependencies
DNSCRYPT_VERSION="2.1.5"
DNSCRYPT_URL="https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${DNSCRYPT_VERSION}/dnscrypt-proxy-linux_x86_64-${DNSCRYPT_VERSION}.tar.gz"
DNSCRYPT_DIR="${BUILDDIR}/dnscrypt"

mkdir -p "$DNSCRYPT_DIR"
echo "Downloading dnscrypt-proxy ${DNSCRYPT_VERSION}..."
if curl -fL --max-time 120 "$DNSCRYPT_URL" -o "${DNSCRYPT_DIR}/dnscrypt-proxy.tar.gz"; then
    tar -xzf "${DNSCRYPT_DIR}/dnscrypt-proxy.tar.gz" -C "$DNSCRYPT_DIR" --strip-components=1
    install -Dm755 "${DNSCRYPT_DIR}/dnscrypt-proxy" "${BUILDDIR}/usr/sbin/dnscrypt-proxy"
    echo "  dnscrypt-proxy installed: /usr/sbin/dnscrypt-proxy"
else
    echo "  WARNING: dnscrypt-proxy download failed — will configure but binary missing"
    echo "  Run: pkg-add dnscrypt-proxy from SkyRepo to install"
fi

# ── 2. Install nftables (should be present in Slackware current) ─────────────
# nftables is included in Slackware current; just ensure config is in place
mkdir -p "${BUILDDIR}/etc/nftables.d"

# ── 3. Copy extras/ (configs, rc.d scripts, sshd, sysctl) ────────────────────
if [ -d "${MODULEDIR}/extras" ]; then
    cp -a "${MODULEDIR}/extras/." "${BUILDDIR}/"
    echo "  Extras copied"
fi

# ── 4. Set permissions ────────────────────────────────────────────────────────
chmod 750  "${BUILDDIR}/etc/rc.d/"             2>/dev/null || true
chmod +x   "${BUILDDIR}/etc/rc.d/rc.skycair-firewall" 2>/dev/null || true
chmod +x   "${BUILDDIR}/etc/rc.d/rc.dnscrypt-proxy"   2>/dev/null || true
chmod 640  "${BUILDDIR}/etc/nftables.d/"*.nft  2>/dev/null || true
chmod 640  "${BUILDDIR}/etc/dnscrypt-proxy/dnscrypt-proxy.toml" 2>/dev/null || true
chmod 600  "${BUILDDIR}/etc/ssh/sshd_config.d/"*.conf 2>/dev/null || true
chmod 644  "${BUILDDIR}/etc/sysctl.d/"*.conf   2>/dev/null || true

# ── 5. Build .xzm squashfs module ────────────────────────────────────────────
mksquashfs "$BUILDDIR" "${OUTPUTDIR}/${MODULENAME}.xzm" \
    -comp xz -b 512K -noappend \
    -e "${BUILDDIR}/tmp" \
    2>/dev/null

if [ -f "${OUTPUTDIR}/${MODULENAME}.xzm" ]; then
    SIZE=$(du -sh "${OUTPUTDIR}/${MODULENAME}.xzm" | cut -f1)
    echo "Built: ${OUTPUTDIR}/${MODULENAME}.xzm (${SIZE})"
else
    echo "ERROR: Module build failed"
    exit 1
fi

rm -rf "$BUILDDIR"
echo "003-skyshield build complete"
