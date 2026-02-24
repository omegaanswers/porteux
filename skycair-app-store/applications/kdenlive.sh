#!/bin/bash
# Kdenlive — KDE non-linear video editor
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=kdenlive
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/kdenlive}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/KDE/kdenlive/releases/latest \
    | grep '"tag_name"' | grep -oP '[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="24.12.3"

APPIMAGE_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "aarch64" || echo "x86_64")
APPIMAGE_URL="https://download.kde.org/stable/kdenlive/${VERSION%.*}/linux/kdenlive-${VERSION}-linux-${APPIMAGE_ARCH}.AppImage"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

echo "Downloading Kdenlive ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
chmod +x "$TEMPDIR"/kdenlive-*.AppImage

cd "$TEMPDIR"
"$TEMPDIR"/kdenlive-*.AppImage --appimage-extract > /dev/null 2>&1
cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/kdenlive.desktop" << DESKTOP
[Desktop Entry]
Name=Kdenlive
Comment=KDE Non-Linear Video Editor
Exec=$INSTALLDIR/AppRun %U
Icon=kdenlive
Terminal=false
Type=Application
Categories=AudioVideo;Video;
MimeType=video/mpeg;video/quicktime;
DESKTOP

[ -f "$TEMPDIR/squashfs-root/kdenlive.png" ] \
    && cp "$TEMPDIR/squashfs-root/kdenlive.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
