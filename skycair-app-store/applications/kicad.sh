#!/bin/bash
# KiCad — professional EDA (Electronic Design Automation) suite
# Schematic capture, PCB layout, Gerber export
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=kicad
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/kicad}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/KiCad/kicad-source-mirror/releases/latest \
    | grep '"tag_name"' | grep -oP '"\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="8.0.8"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

if [[ "$ARCH" == "x86_64" ]]; then
    # KiCad provides a Linux AppImage
    APPIMAGE_URL=$(curl -s https://api.github.com/repos/KiCad/kicad-source-mirror/releases/latest \
        | grep '"browser_download_url"' | grep 'x86_64.*AppImage\|amd64.*AppImage\|linux.*AppImage' \
        | grep -oP 'https://[^"]+' | head -1)
    [ -z "$APPIMAGE_URL" ] && \
        APPIMAGE_URL="https://downloads.kicad.org/kicad/${VERSION}/linux/kicad-${VERSION}-linux-x86_64.AppImage"

    echo "Downloading KiCad ${VERSION} (x86_64)..."
    wget -T 60 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
    chmod +x "$TEMPDIR"/kicad-*.AppImage "$TEMPDIR"/KiCad-*.AppImage 2>/dev/null

    cd "$TEMPDIR"
    APPIMAGE=$(ls "$TEMPDIR"/*.AppImage | head -1)
    "$APPIMAGE" --appimage-extract > /dev/null 2>&1
    cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
    SQUASHDIR="$TEMPDIR/squashfs-root"
    EXEC_CMD="$INSTALLDIR/AppRun"
else
    # aarch64: Slackware ARM packages or build from source
    echo "KiCad aarch64 — checking Slackware ARM..."
    SLKURL="https://slackware.uk/slackwarearm/slackwarearm-current/packages/extra/kicad/kicad-${VERSION}-aarch64-1.txz"
    wget -T 30 -P "$TEMPDIR" "$SLKURL" 2>/dev/null \
        || { echo "KiCad aarch64 binary not available. Manual build required."; exit 1; }
    txz2dir "$TEMPDIR"/kicad-*.txz -o="$MODULEDIR" -q || exit 1
    EXEC_CMD="kicad"
fi

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/kicad.desktop" << DESKTOP
[Desktop Entry]
Name=KiCad EDA
Comment=Electronics Design Automation — schematic capture, PCB layout, Gerber export
Exec=$EXEC_CMD %F
Icon=kicad
Terminal=false
Type=Application
Categories=Engineering;Electronics;
MimeType=application/x-kicad-project;
DESKTOP

[ -f "${SQUASHDIR:-$INSTALLDIR}/kicad.png" ] \
    && cp "${SQUASHDIR:-$INSTALLDIR}/kicad.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
