#!/bin/bash
# Blender — 3D creation suite (modeling, animation, rendering, compositing)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=blender
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/blender}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/blender/blender/tags \
    | grep '"name"' | grep -oP '"name":\s*"\Kv[^"]+' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -Vr | head -1 | tr -d 'v')
[ -z "$VERSION" ] && VERSION="4.3.2"

BLENDER_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "linux-arm64" || echo "linux-x64")
SHORTVER="${VERSION%.*}"
TARBALL_URL="https://download.blender.org/release/Blender${SHORTVER}/blender-${VERSION}-${BLENDER_ARCH}.tar.xz"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

echo "Downloading Blender ${VERSION} (${ARCH})..."
wget -T 60 -P "$TEMPDIR" "$TARBALL_URL" || exit 1

tar -xJf "$TEMPDIR"/blender-*.tar.xz -C "$TEMPDIR"
BLENDER_DIR=$(ls -d "$TEMPDIR"/blender-*/ | grep -v '\.tar' | head -1)
cp -a "${BLENDER_DIR}." "$INSTALLDIR/"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/blender.desktop" << DESKTOP
[Desktop Entry]
Name=Blender
Comment=3D Creation Suite — modeling, animation, rendering, VFX, compositing
Exec=$INSTALLDIR/blender %f
Icon=blender
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;
MimeType=application/x-blender;
DESKTOP

[ -f "$INSTALLDIR/blender.svg" ] && cp "$INSTALLDIR/blender.svg" "$MODULEDIR/usr/share/pixmaps/blender.svg"
[ -f "$INSTALLDIR/blender.png" ] && cp "$INSTALLDIR/blender.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
