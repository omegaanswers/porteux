#!/bin/bash
# SkyCAIR OS — 003-skycube Module Builder
# SkyCUBES: GNOME Boxes + libvirt + KVM/QEMU virtualization
# GNOME Boxes is already in PorteuX base — this module configures it.
# 2XR, LLC | Evolve2Linux | 123Tech.net

MODULENAME="003-skycube"
MODULEDIR="$(dirname "$(realpath "$0")")"
OUTPUTDIR="${MODULEDIR}/../tmp/modules"
BUILDDIR="/tmp/skycube-build"

source "${MODULEDIR}/../builder-utils/setflags.sh"

echo "Building ${MODULENAME}.xzm — SkyCUBES virtualization module"

mkdir -p "$BUILDDIR" "$OUTPUTDIR"

# ── 1. Configure libvirt default storage pool ─────────────────────────────────
# Storage at /skycair/cubes/ backed by SkyVAULT ZFS (or local disk fallback)
mkdir -p "${BUILDDIR}/etc/libvirt"

cat > "${BUILDDIR}/etc/libvirt/skycube-pool.xml" << 'EOF'
<pool type='dir'>
  <name>skycubes</name>
  <target>
    <path>/skycair/cubes</path>
    <permissions>
      <mode>0711</mode>
      <owner>-1</owner>
      <group>-1</group>
    </permissions>
  </target>
</pool>
EOF

# ── 2. KVM/QEMU permissions ────────────────────────────────────────────────────
# udev rule: kvm group access for non-root KVM virtualization
mkdir -p "${BUILDDIR}/lib/udev/rules.d"
cat > "${BUILDDIR}/lib/udev/rules.d/60-skycube-kvm.rules" << 'EOF'
# SkyCUBES — KVM device access for kvm group
KERNEL=="kvm", GROUP="kvm", MODE="0660"
KERNEL=="vhost-net", GROUP="kvm", MODE="0660"
KERNEL=="vhost-vsock", GROUP="kvm", MODE="0660"
EOF

# ── 3. skycube.conf — default configuration ───────────────────────────────────
mkdir -p "${BUILDDIR}/etc/skycube"
cp "${MODULEDIR}/extras/etc/skycube/skycube.conf" \
   "${BUILDDIR}/etc/skycube/skycube.conf" 2>/dev/null || \
cat > "${BUILDDIR}/etc/skycube/skycube.conf" << 'EOF'
# SkyCUBES Configuration
# 2XR, LLC | Evolve2Linux | 123Tech.net

# Default storage pool (backed by SkyVAULT ZFS when available)
SKYCUBE_POOL_PATH="/skycair/cubes"

# Default VM settings
SKYCUBE_DEFAULT_CPU=2
SKYCUBE_DEFAULT_RAM=2048
SKYCUBE_DEFAULT_DISK=20

# VDI backend: gnome-boxes (default) or cockpit (browser SPICE)
SKYCUBE_VDI_BACKEND="gnome-boxes"

# SPICE display for remote access
SKYCUBE_SPICE_PORT=5900

# Cockpit-Machines web UI port
SKYCUBE_COCKPIT_PORT=9090
EOF

# ── 4. Install skycube CLI ─────────────────────────────────────────────────────
mkdir -p "${BUILDDIR}/usr/bin"
cp "${MODULEDIR}/extras/usr/bin/skycube" "${BUILDDIR}/usr/bin/skycube"
chmod 755 "${BUILDDIR}/usr/bin/skycube"

# ── 5. libvirt network config — NAT bridge for VMs ────────────────────────────
cat > "${BUILDDIR}/etc/libvirt/skycube-network.xml" << 'EOF'
<network>
  <name>skycube-nat</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.100' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

# ── 6. rc.d startup script ────────────────────────────────────────────────────
mkdir -p "${BUILDDIR}/etc/rc.d"
cat > "${BUILDDIR}/etc/rc.d/rc.skycube" << 'RCEOF'
#!/bin/bash
# SkyCUBES — libvirt pool + network initialization
# Runs at SkyCAIR OS startup to configure virtualization

start() {
    echo "SkyCUBES: Initializing virtualization environment..."

    # Create storage pool directory
    mkdir -p /skycair/cubes
    chmod 711 /skycair/cubes

    # Start libvirt daemon if present
    if command -v libvirtd >/dev/null 2>&1; then
        if ! pgrep libvirtd >/dev/null 2>&1; then
            libvirtd -d
            sleep 2
        fi

        # Define and start storage pool if not exists
        if ! virsh pool-info skycubes >/dev/null 2>&1; then
            virsh pool-define /etc/libvirt/skycube-pool.xml 2>/dev/null
            virsh pool-start skycubes 2>/dev/null
            virsh pool-autostart skycubes 2>/dev/null
            echo "  Pool 'skycubes' defined at /skycair/cubes"
        fi

        # Define NAT network if not exists
        if ! virsh net-info skycube-nat >/dev/null 2>&1; then
            virsh net-define /etc/libvirt/skycube-network.xml 2>/dev/null
            virsh net-start skycube-nat 2>/dev/null
            virsh net-autostart skycube-nat 2>/dev/null
            echo "  Network 'skycube-nat' defined (192.168.122.0/24)"
        fi
    else
        echo "  WARNING: libvirtd not found — install libvirt from SkyRepo"
        echo "  pkg-add libvirt qemu"
    fi

    # Add current user to kvm group
    if getent group kvm >/dev/null 2>&1; then
        CURRENT_USER="${SUDO_USER:-$(logname 2>/dev/null || echo skycair)}"
        usermod -aG kvm "$CURRENT_USER" 2>/dev/null && \
            echo "  Added $CURRENT_USER to kvm group"
    fi

    echo "SkyCUBES: Ready. Use 'skycube list' or open GNOME Boxes."
}

stop() {
    echo "SkyCUBES: Stopping..."
    virsh net-destroy skycube-nat 2>/dev/null
    virsh pool-destroy skycubes 2>/dev/null
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; start ;;
    status)
        echo "--- SkyCUBES Status ---"
        virsh list --all 2>/dev/null || echo "libvirtd not running"
        virsh pool-info skycubes 2>/dev/null || echo "Pool not configured"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
RCEOF
chmod 755 "${BUILDDIR}/etc/rc.d/rc.skycube"

# ── 7. Copy any extras ────────────────────────────────────────────────────────
if [ -d "${MODULEDIR}/extras" ]; then
    cp -a "${MODULEDIR}/extras/." "$BUILDDIR/" 2>/dev/null
fi

# ── 8. Build .xzm module ──────────────────────────────────────────────────────
echo "Creating squashfs module..."
mksquashfs "$BUILDDIR" "${OUTPUTDIR}/${MODULENAME}.xzm" \
    -comp xz -b 256K -no-progress -noappend -quiet 2>/dev/null || \
mksquashfs "$BUILDDIR" "${OUTPUTDIR}/${MODULENAME}.xzm" \
    -comp xz -b 256K -noappend

echo "Module built: ${OUTPUTDIR}/${MODULENAME}.xzm"

# ── 9. Sign the module (if signing key present) ───────────────────────────────
SIGN_KEY="/etc/skycair/module-signing.key"
if [ -f "$SIGN_KEY" ]; then
    openssl pkeyutl -sign \
        -inkey "$SIGN_KEY" \
        -in "${OUTPUTDIR}/${MODULENAME}.xzm" \
        -out "${OUTPUTDIR}/${MODULENAME}.xzm.sig" \
        -pkeyopt digest:sha256
    echo "Module signed: ${OUTPUTDIR}/${MODULENAME}.xzm.sig"
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$BUILDDIR"
echo "Done."
