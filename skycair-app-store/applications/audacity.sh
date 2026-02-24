#!/bin/bash
# Audacity — multi-track audio editor and recorder
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=audacity
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/audacity}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/audacity/audacity/releases/latest \
    | grep '"tag_name"' | grep -oP '[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="3.7.3"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

APPIMAGE_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "arm64" || echo "amd64")
APPIMAGE_URL="https://github.com/audacity/audacity/releases/download/Audacity-${VERSION}/audacity-linux-${VERSION}-${APPIMAGE_ARCH}.AppImage"

echo "Downloading Audacity ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
chmod +x "$TEMPDIR"/audacity-*.AppImage

cd "$TEMPDIR"
"$TEMPDIR"/audacity-*.AppImage --appimage-extract > /dev/null 2>&1
cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
SQUASHDIR="$TEMPDIR/squashfs-root"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/audacity.desktop" << DESKTOP
[Desktop Entry]
Name=Audacity
Comment=Multi-track audio editor and recorder
Exec=$INSTALLDIR/AppRun %F
Icon=audacity
Terminal=false
Type=Application
Categories=AudioVideo;Audio;
MimeType=audio/wav;audio/mp3;audio/flac;audio/ogg;
DESKTOP

[ -f "$SQUASHDIR/audacity.png" ] && cp "$SQUASHDIR/audacity.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
