#!/bin/bash
# HandBrake — video transcoder and converter
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=handbrake
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/handbrake}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/HandBrake/HandBrake/releases/latest \
    | grep '"tag_name"' | grep -oP '[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="1.8.2"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

if [[ "$ARCH" == "x86_64" ]]; then
    APPIMAGE_URL="https://github.com/HandBrake/HandBrake/releases/download/${VERSION}/HandBrake-${VERSION}-x86_64.AppImage"
    echo "Downloading HandBrake ${VERSION} (x86_64)..."
    wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
    chmod +x "$TEMPDIR"/HandBrake-*.AppImage
    cd "$TEMPDIR"
    "$TEMPDIR"/HandBrake-*.AppImage --appimage-extract > /dev/null 2>&1
    cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
    SQUASHDIR="$TEMPDIR/squashfs-root"
else
    echo "HandBrake aarch64 AppImage not available — building CLI from source is recommended."
    echo "Alternatively install via Slackware aarch64 repository."
    exit 1
fi

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/handbrake.desktop" << DESKTOP
[Desktop Entry]
Name=HandBrake
Comment=Video Transcoder — convert, compress, and encode video
Exec=$INSTALLDIR/AppRun %U
Icon=handbrake
Terminal=false
Type=Application
Categories=AudioVideo;Video;
MimeType=video/mpeg;video/mp4;video/mkv;
DESKTOP

[ -f "$SQUASHDIR/handbrake.png" ] && cp "$SQUASHDIR/handbrake.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
