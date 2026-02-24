#!/bin/bash
# MangoHud — Vulkan/OpenGL overlay for GPU/CPU/FPS monitoring in games
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=mangohud
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/optional/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/flightlessmango/MangoHud/releases/latest \
    | grep '"tag_name"' | grep -oP '"\Kv[\d.]+' | head -1 | tr -d 'v')
[ -z "$VERSION" ] && VERSION="0.7.2"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR"

if [[ "$ARCH" == "x86_64" ]]; then
    TARBALL_URL="https://github.com/flightlessmango/MangoHud/releases/download/v${VERSION}/MangoHud-v${VERSION}-1-x86_64.tar.zst"
    echo "Downloading MangoHud ${VERSION} (x86_64)..."
    wget -T 30 -P "$TEMPDIR" "$TARBALL_URL" || exit 1

    # MangoHud uses tar.zst — extract to a staging area
    mkdir -p "$TEMPDIR/extract"
    tar -I zstd -xf "$TEMPDIR"/MangoHud-*.tar.zst -C "$TEMPDIR/extract" 2>/dev/null \
        || tar --use-compress-program=zstdmt -xf "$TEMPDIR"/MangoHud-*.tar.zst -C "$TEMPDIR/extract" || exit 1

    # Run MangoHud installer in prefix mode to get files
    if [ -f "$TEMPDIR/extract/usr/lib/mangohud/mangohud-setup.sh" ]; then
        MANGOHUD_INSTALL_PREFIX="$MODULEDIR" bash "$TEMPDIR/extract/usr/lib/mangohud/mangohud-setup.sh" install
    else
        cp -a "$TEMPDIR/extract/." "$MODULEDIR/"
    fi
else
    # aarch64: build from source or use distro package stub
    echo "MangoHud aarch64: building from Slackware-compatible sources..."
    # Pull source and build
    SRC_URL="https://github.com/flightlessmango/MangoHud/archive/refs/tags/v${VERSION}.tar.gz"
    wget -T 30 -P "$TEMPDIR" "$SRC_URL" -O "$TEMPDIR/mangohud-src.tar.gz" || exit 1
    echo "Source downloaded to $TEMPDIR — manual build required for aarch64."
    echo "See: https://github.com/flightlessmango/MangoHud/blob/master/INSTALL.md"
    exit 0
fi

# Create module overlay directory
mkdir -p "$MODULEDIR/usr/share/applications"

cat > "$MODULEDIR/usr/share/applications/mangohud-config.desktop" << DESKTOP
[Desktop Entry]
Name=MangoHud Config
Comment=Configure MangoHud GPU/FPS overlay for Vulkan and OpenGL games
Exec=bash -c "MANGOHUD=1 mangohud glxgears"
Icon=utilities-system-monitor
Terminal=true
Type=Application
Categories=Game;System;
DESKTOP

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "MangoHud installed. Use MANGOHUD=1 before any game or Vulkan/OpenGL app."
