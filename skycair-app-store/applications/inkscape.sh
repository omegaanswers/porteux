#!/bin/bash
# Inkscape — professional vector graphics editor
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=inkscape
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/inkscape}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://inkscape.org/release/inkscape-latest/gnulinux/appimage/ 2>/dev/null \
    | grep -oP 'Inkscape-[\d.]+-x86_64.AppImage' | grep -oP '[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="1.4.2"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

APPIMAGE_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "aarch64" || echo "x86_64")
APPIMAGE_URL="https://inkscape.org/gallery/item/46495/Inkscape-${VERSION}-${APPIMAGE_ARCH}.AppImage"

echo "Downloading Inkscape ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" \
    || wget -T 30 -O "$TEMPDIR/Inkscape.AppImage" \
        "https://media.inkscape.org/dl/resources/file/Inkscape-${VERSION}-x86_64.AppImage" \
    || exit 1
chmod +x "$TEMPDIR"/Inkscape-*.AppImage "$TEMPDIR"/Inkscape.AppImage 2>/dev/null

cd "$TEMPDIR"
APPIMAGE=$(ls "$TEMPDIR"/*.AppImage | head -1)
"$APPIMAGE" --appimage-extract > /dev/null 2>&1
cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
SQUASHDIR="$TEMPDIR/squashfs-root"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/inkscape.desktop" << DESKTOP
[Desktop Entry]
Name=Inkscape
Comment=Vector Graphics Editor — SVG drawing, illustration, design
Exec=$INSTALLDIR/AppRun %F
Icon=inkscape
Terminal=false
Type=Application
Categories=Graphics;
MimeType=image/svg+xml;application/pdf;
DESKTOP

[ -f "$SQUASHDIR/inkscape.png" ] && cp "$SQUASHDIR/inkscape.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
