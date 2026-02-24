#!/bin/bash
# Vulkan Tools — vulkaninfo, vkcube, Vulkan validation layers for GPU/gaming
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=vulkan-tools
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/optional/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/KhronosGroup/Vulkan-Tools/releases/latest \
    | grep '"tag_name"' | grep -oP '"sdk-\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="1.4.304.1"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR"

# Vulkan tools are distributed via the LunarG SDK or Slackware packages
SLACKWARE_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "aarch64" || echo "x86_64")

# Try Slackware current first (Vulkan tools are in Slackware-current)
SLKURL="https://slackware.uk/slackware/slackware64-current/slackware/l/vulkan-sdk-${VERSION}-${SLACKWARE_ARCH}-1.txz"
echo "Downloading Vulkan Tools ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$SLKURL" 2>/dev/null

if ls "$TEMPDIR"/*.txz > /dev/null 2>&1; then
    txz2dir "$TEMPDIR"/*.txz -o="$MODULEDIR" -q || exit 1
    rm -fr "$MODULEDIR/usr/doc" "$MODULEDIR/usr/include" "$MODULEDIR/usr/man" 2>/dev/null
    find "$MODULEDIR" -name '*.a' -delete 2>/dev/null
else
    # Fallback: download LunarG Vulkan SDK tools binaries
    SDK_URL="https://sdk.lunarg.com/sdk/download/${VERSION}/linux/vulkan-sdk-${VERSION}-linux.tar.xz"
    echo "Trying LunarG SDK..."
    wget -T 60 -P "$TEMPDIR" "$SDK_URL" 2>/dev/null || {
        echo "Could not download Vulkan tools — GPU driver may include them."
        echo "Check: nvidia-driver, amdgpu-pro, or mesa packages."
        exit 1
    }
    mkdir -p "$TEMPDIR/sdk"
    tar -xJf "$TEMPDIR"/vulkan-sdk-*.tar.xz -C "$TEMPDIR/sdk"
    SDK_DIR=$(ls -d "$TEMPDIR/sdk"/*/ | head -1)
    # Copy only the tools binaries (not full SDK)
    mkdir -p "$MODULEDIR/usr/bin" "$MODULEDIR/usr/lib64"
    [ -f "${SDK_DIR}x86_64/bin/vulkaninfo" ] \
        && cp "${SDK_DIR}x86_64/bin/vulkaninfo" "$MODULEDIR/usr/bin/"
    [ -f "${SDK_DIR}x86_64/bin/vkcube" ] \
        && cp "${SDK_DIR}x86_64/bin/vkcube" "$MODULEDIR/usr/bin/"
fi

mkdir -p "$MODULEDIR/usr/share/applications"

cat > "$MODULEDIR/usr/share/applications/vulkaninfo.desktop" << DESKTOP
[Desktop Entry]
Name=Vulkan Info
Comment=Display Vulkan GPU capabilities and driver information
Exec=bash -c "vulkaninfo | less"
Icon=utilities-system-monitor
Terminal=true
Type=Application
Categories=System;
DESKTOP

cat > "$MODULEDIR/usr/share/applications/vkcube.desktop" << DESKTOP
[Desktop Entry]
Name=Vulkan Cube Demo
Comment=Test Vulkan GPU rendering with rotating cube demo
Exec=vkcube
Icon=applications-games
Terminal=false
Type=Application
Categories=System;Game;
DESKTOP

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "Vulkan tools installed. Run: vulkaninfo | head -50"
