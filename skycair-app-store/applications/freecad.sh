#!/bin/bash
# FreeCAD — open source 3D parametric modeler and CAD/CAE application
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=freecad
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"
INSTALLDIR="${1:-/opt/freecad}"

[[ $INSTALLDIR = --* ]] && echo "Installation path can't be empty." && exit 1
[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/FreeCAD/FreeCAD/releases/latest \
    | grep '"tag_name"' | grep -oP '"\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="1.0.0"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR" "$INSTALLDIR"

if [[ "$ARCH" == "x86_64" ]]; then
    APPIMAGE_URL="https://github.com/FreeCAD/FreeCAD/releases/download/${VERSION}/FreeCAD_${VERSION}-conda-Linux-x86_64-py311.AppImage"
    echo "Downloading FreeCAD ${VERSION} (x86_64)..."
    wget -T 60 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
    chmod +x "$TEMPDIR"/FreeCAD_*.AppImage

    cd "$TEMPDIR"
    "$TEMPDIR"/FreeCAD_*.AppImage --appimage-extract > /dev/null 2>&1
    cp -a "$TEMPDIR/squashfs-root/." "$INSTALLDIR/"
    SQUASHDIR="$TEMPDIR/squashfs-root"
    EXEC_CMD="$INSTALLDIR/AppRun"
else
    # aarch64: FreeCAD does not have official AppImage — use Slackware/ARM build
    echo "FreeCAD aarch64: checking Slackware ARM packages..."
    SLKURL="https://slackware.uk/slackwarearm/slackwarearm-current/packages/extra/freecad/freecad-${VERSION}-aarch64-1.txz"
    wget -T 30 -P "$TEMPDIR" "$SLKURL" 2>/dev/null \
        || { echo "FreeCAD package not found for aarch64 ${VERSION}"; exit 1; }
    txz2dir "$TEMPDIR/freecad-${VERSION}-aarch64-1.txz" -o="$INSTALLDIR" -q || exit 1
    EXEC_CMD="freecad"
fi

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALLDIR"

mkdir -p "$MODULEDIR/usr/share/applications" "$MODULEDIR/usr/share/pixmaps"

cat > "$MODULEDIR/usr/share/applications/freecad.desktop" << DESKTOP
[Desktop Entry]
Name=FreeCAD
Comment=Open Source 3D CAD Modeler — mechanical design, engineering, architecture
Exec=$EXEC_CMD %F
Icon=freecad
Terminal=false
Type=Application
Categories=Engineering;Graphics;
MimeType=application/x-extension-fcstd;
DESKTOP

[ -f "${SQUASHDIR:-$INSTALLDIR}/freecad.png" ] \
    && cp "${SQUASHDIR:-$INSTALLDIR}/freecad.png" "$MODULEDIR/usr/share/pixmaps/"

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
