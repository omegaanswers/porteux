#!/bin/bash
# GIMP — GNU Image Manipulation Program
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=gimp
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/gimp}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/GNOME/gimp/tags \
    | grep '"name"' | grep -oP '"name":\s*"\K[^"]+' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -Vr | head -1)
[ -z "$VERSION" ] && VERSION="3.0.2"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

APPIMAGE_URL="https://download.gimp.org/gimp/v${VERSION%.*}/linux/GIMP-${VERSION}-Linux-${ARCH}-$([[ "$ARCH" == "aarch64" ]] && echo aarch64 || echo x86_64).AppImage"

echo "Downloading GIMP ${VERSION} (${ARCH})..."
# Try GNOME FTP first, fallback to GitHub release
wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" \
    || wget -T 30 -P "$TEMPDIR" \
        "https://github.com/nicowillis/gimp-appimage/releases/latest/download/GIMP-latest-x86_64.AppImage" \
    || exit 1
chmod +x "$TEMPDIR"/GIMP-*.AppImage

cd "$TEMPDIR"
"$TEMPDIR"/GIMP-*.AppImage --appimage-extract > /dev/null 2>&1
cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
SQUASHDIR="$TEMPDIR/squashfs-root"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/gimp.desktop" << DESKTOP
[Desktop Entry]
Name=GIMP Image Editor
Comment=GNU Image Manipulation Program — photo editing, painting, compositing
Exec=$INSTALLDIR/AppRun %U
Icon=gimp
Terminal=false
Type=Application
Categories=Graphics;
MimeType=image/png;image/jpeg;image/bmp;image/tiff;image/gif;
DESKTOP

[ -f "$SQUASHDIR/gimp.png" ] && cp "$SQUASHDIR/gimp.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
