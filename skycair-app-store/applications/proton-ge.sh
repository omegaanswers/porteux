#!/bin/bash
# Proton-GE — GloriousEggroll's custom Proton build for Steam on Linux
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64 (Steam is x86_64 only on Linux)

CURRENTPACKAGE=proton-ge
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/optional/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" ]] && echo "Proton-GE is x86_64 only (Steam requirement)." && exit 1

# Fetch latest GE-Proton release
VERSION=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
    | grep '"tag_name"' | grep -oP '"\K[^"]+' | tail -1)
[ -z "$VERSION" ] && VERSION="GE-Proton9-27"

TARBALL_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${VERSION}/${VERSION}.tar.gz"

# Proton-GE installs into Steam's compatibilitytools.d directory
STEAM_COMPAT_DIR="$HOME/.steam/root/compatibilitytools.d"
STEAM_COMPAT_DIR_ALT="$HOME/.local/share/Steam/compatibilitytools.d"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR"

echo "Downloading ${VERSION}..."
wget -T 60 -P "$TEMPDIR" "$TARBALL_URL" || exit 1

# Install to user's Steam compatibilitytools.d
if [ -d "$STEAM_COMPAT_DIR" ]; then
    INSTALL_TARGET="$STEAM_COMPAT_DIR"
elif [ -d "$STEAM_COMPAT_DIR_ALT" ]; then
    INSTALL_TARGET="$STEAM_COMPAT_DIR_ALT"
else
    mkdir -p "$STEAM_COMPAT_DIR_ALT"
    INSTALL_TARGET="$STEAM_COMPAT_DIR_ALT"
fi

echo "Installing ${VERSION} to $INSTALL_TARGET..."
tar -xzf "$TEMPDIR/${VERSION}.tar.gz" -C "$INSTALL_TARGET"

CURRENTUSER=$(loginctl user-status 2>/dev/null | head -n 1 | cut -d" " -f1)
[ -z "$CURRENTUSER" ] && CURRENTUSER=guest
CURRENTGROUP=$(id -gn "$CURRENTUSER" 2>/dev/null || echo "$CURRENTUSER")
chown -R "$CURRENTUSER":"$CURRENTGROUP" "$INSTALL_TARGET/$VERSION"

# Build a minimal .xzm module with just a readme/activation notice
mkdir -p "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE"
cat > "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE/README.txt" << README
${VERSION} installed to: $INSTALL_TARGET

To use Proton-GE in Steam:
1. Open Steam → Settings → Compatibility
2. Enable "Steam Play for all other titles"
3. Select "${VERSION}" from the dropdown

Requires Steam to be installed first.
README

MODULEFILENAME="${CURRENTPACKAGE}-${VERSION}-x86_64_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "Done! Restart Steam and select ${VERSION} in Compatibility settings."
