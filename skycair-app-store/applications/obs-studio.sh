#!/bin/bash
# OBS Studio — Open Broadcaster Software (streaming + recording)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=obs-studio
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/obs-studio}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

# Fetch latest release version from GitHub
VERSION=$(curl -s https://api.github.com/repos/obsproject/obs-studio/releases/latest \
    | grep '"tag_name"' | grep -oP '[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="31.0.3"

APPIMAGE_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "aarch64" || echo "x86_64")
APPIMAGE_URL="https://github.com/obsproject/obs-studio/releases/download/${VERSION}/OBS-Studio-${VERSION}-Linux-${APPIMAGE_ARCH}.AppImage"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

echo "Downloading OBS Studio ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
chmod +x "$TEMPDIR"/OBS-Studio-*.AppImage

# Extract AppImage
cd "$TEMPDIR"
"$TEMPDIR"/OBS-Studio-*.AppImage --appimage-extract > /dev/null 2>&1

SQUASHDIR="$TEMPDIR/squashfs-root"
cp -a "$SQUASHDIR/." "$INSTALLDIR/"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

# Build .xzm module with launcher
mkdir -p "$MODULEDIR/usr/share/applications"
mkdir -p "$MODULEDIR/usr/share/pixmaps"

[ -f "$SQUASHDIR/obs.desktop" ] && cp "$SQUASHDIR/obs.desktop" "$MODULEDIR/usr/share/applications/" \
    && sed -i "s|Exec=.*|Exec=$INSTALLDIR/AppRun %U|g" "$MODULEDIR/usr/share/applications/obs.desktop"

[ -z "$(ls "$MODULEDIR/usr/share/applications/" 2>/dev/null)" ] && cat > "$MODULEDIR/usr/share/applications/obs-studio.desktop" << DESKTOP
[Desktop Entry]
Name=OBS Studio
Comment=Open Broadcaster Software — streaming and recording
Exec=$INSTALLDIR/AppRun %U
Icon=obs
Terminal=false
Type=Application
Categories=AudioVideo;Video;Recorder;
DESKTOP

[ -f "$SQUASHDIR/obs.png" ] && cp "$SQUASHDIR/obs.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
