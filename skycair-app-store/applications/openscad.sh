#!/bin/bash
# OpenSCAD — programmable 3D solid modeler (script-based CAD)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=openscad
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/openscad}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/openscad/openscad/releases/latest \
    | grep '"tag_name"' | grep -oP '"openscad-\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="2024.12.06"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

APPIMAGE_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "aarch64" || echo "x86_64")
APPIMAGE_URL=$(curl -s https://api.github.com/repos/openscad/openscad/releases/latest \
    | grep '"browser_download_url"' | grep "${APPIMAGE_ARCH}.*AppImage" | grep -oP 'https://[^"]+' | head -1)
[ -z "$APPIMAGE_URL" ] && \
    APPIMAGE_URL="https://github.com/openscad/openscad/releases/download/openscad-${VERSION}/OpenSCAD-${VERSION}-${APPIMAGE_ARCH}.AppImage"

echo "Downloading OpenSCAD ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
chmod +x "$TEMPDIR"/OpenSCAD-*.AppImage

cd "$TEMPDIR"
"$TEMPDIR"/OpenSCAD-*.AppImage --appimage-extract > /dev/null 2>&1
cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
SQUASHDIR="$TEMPDIR/squashfs-root"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/openscad.desktop" << DESKTOP
[Desktop Entry]
Name=OpenSCAD
Comment=Script-based 3D CAD Modeler — parametric design, engineering parts
Exec=$INSTALLDIR/AppRun %F
Icon=openscad
Terminal=false
Type=Application
Categories=Engineering;Graphics;3DGraphics;
MimeType=application/x-openscad;model/stl;
DESKTOP

[ -f "$SQUASHDIR/openscad.png" ] && cp "$SQUASHDIR/openscad.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
