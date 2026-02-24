#!/bin/bash
# PrusaSlicer — 3D printing slicer (Prusa, BambuLab, generic FDM/SLA printers)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=prusaslicer
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/prusaslicer}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest \
    | grep '"tag_name"' | grep -oP '"version_\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="2.9.1"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

if [[ "$ARCH" == "x86_64" ]]; then
    APPIMAGE_URL="https://github.com/prusa3d/PrusaSlicer/releases/download/version_${VERSION}/PrusaSlicer-${VERSION}+linux-x64-GTK3-202*.AppImage"
    echo "Downloading PrusaSlicer ${VERSION} (x86_64)..."
    # Use GitHub API to find the actual AppImage filename
    APPIMAGE_URL=$(curl -s https://api.github.com/repos/prusa3d/PrusaSlicer/releases/latest \
        | grep '"browser_download_url"' | grep 'linux-x64.*\.AppImage' | grep -oP 'https://[^"]+' | head -1)
    [ -z "$APPIMAGE_URL" ] && APPIMAGE_URL="https://github.com/prusa3d/PrusaSlicer/releases/download/version_${VERSION}/PrusaSlicer-${VERSION}+linux-x64-GTK3.AppImage"
    wget -T 60 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
    chmod +x "$TEMPDIR"/PrusaSlicer-*.AppImage

    cd "$TEMPDIR"
    "$TEMPDIR"/PrusaSlicer-*.AppImage --appimage-extract > /dev/null 2>&1
    cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
    SQUASHDIR="$TEMPDIR/squashfs-root"
    EXEC_CMD="$INSTALLDIR/AppRun"
else
    # aarch64: PrusaSlicer does not have official AppImage — build from source or use arm64 deb
    echo "PrusaSlicer aarch64: no official binary — downloading source for manual build."
    echo "See: https://github.com/prusa3d/PrusaSlicer/blob/master/doc/How%20to%20build%20-%20Linux%20et%20al.md"
    # SuperSlicer has arm64 builds as an alternative
    echo "Alternatively, SuperSlicer has arm64 AppImages."
    exit 0
fi

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/prusaslicer.desktop" << DESKTOP
[Desktop Entry]
Name=PrusaSlicer
Comment=3D Printing Slicer — Prusa, BambuLab, generic FDM/SLA printer support
Exec=$EXEC_CMD %F
Icon=PrusaSlicer
Terminal=false
Type=Application
Categories=Engineering;Graphics;
MimeType=model/stl;application/sla;model/3mf;
DESKTOP

[ -f "$SQUASHDIR/PrusaSlicer.png" ] && cp "$SQUASHDIR/PrusaSlicer.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
