#!/bin/bash
# VLC Media Player — universal media player
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=vlc
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/vlc}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

# VLC AppImage — x86_64 (aarch64 via Slackware AArch64 build below)
VERSION=$(curl -s https://api.github.com/repos/videolan/vlc/releases/latest \
    | grep '"tag_name"' | grep -oP '[\d.]+' | head -1 2>/dev/null)
[ -z "$VERSION" ] && VERSION="3.0.21"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

if [[ "$ARCH" == "x86_64" ]]; then
    APPIMAGE_URL="https://get.videolan.org/vlc/${VERSION}/linux/vlc-${VERSION}-intel64.AppImage"
    echo "Downloading VLC ${VERSION} AppImage (x86_64)..."
    wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" \
        || wget -T 30 -P "$TEMPDIR" "https://github.com/videolan/vlc-3.0-appimage/releases/download/continuous/VLC-${VERSION}-x86_64.AppImage" \
        || exit 1
    chmod +x "$TEMPDIR"/VLC*.AppImage "$TEMPDIR"/vlc*.AppImage 2>/dev/null
    cd "$TEMPDIR"
    APPIMAGE=$(ls "$TEMPDIR"/*.AppImage | head -1)
    "$APPIMAGE" --appimage-extract > /dev/null 2>&1
    cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
    SQUASHDIR="$TEMPDIR/squashfs-root"
else
    # aarch64: use Slackware package from slackware-current (contrib)
    echo "Downloading VLC (aarch64)..."
    SLKURL="https://slackware.uk/slackwarearm/slackwarearm-current/packages/xap/vlc-${VERSION}-aarch64-1.txz"
    wget -T 30 -P "$TEMPDIR" "$SLKURL" \
        || { echo "VLC aarch64 not available in this version, trying latest"; exit 1; }
    txz2dir "$TEMPDIR/vlc-${VERSION}-aarch64-1.txz" -o="$INSTALLDIR" -q || exit 1
    SQUASHDIR="$INSTALLDIR"
fi

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/vlc.desktop" << DESKTOP
[Desktop Entry]
Name=VLC Media Player
Comment=Read, capture, broadcast your multimedia streams
Exec=$INSTALLDIR/AppRun %U
Icon=vlc
Terminal=false
Type=Application
Categories=AudioVideo;Player;
MimeType=video/mpeg;video/x-mpeg;audio/mpeg;audio/mp4;video/mp4;
DESKTOP

[ -f "$SQUASHDIR/vlc.png" ] && cp "$SQUASHDIR/vlc.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
