#!/bin/bash
# Streamlink — pipe streams from Twitch, YouTube, etc. to local player (VLC, MPV)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64

CURRENTPACKAGE=streamlink
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/streamlink/streamlink/releases/latest \
    | grep '"tag_name"' | grep -oP '"\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="7.3.0"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR/usr/local/bin" \
    "$MODULEDIR/usr/share/applications" \
    "$MODULEDIR/usr/lib/python3/dist-packages"

echo "Downloading Streamlink ${VERSION} (${ARCH})..."

# Streamlink has a standalone binary for Linux
APPIMAGE_URL=$(curl -s https://api.github.com/repos/streamlink/streamlink/releases/latest \
    | grep '"browser_download_url"' | grep 'linux' | grep -oP 'https://[^"]+' | head -1)

if [ -n "$APPIMAGE_URL" ]; then
    wget -T 30 -P "$TEMPDIR" "$APPIMAGE_URL" || exit 1
    DOWNLOADED=$(ls "$TEMPDIR"/ | head -1)

    if [[ "$DOWNLOADED" == *.AppImage ]]; then
        chmod +x "$TEMPDIR/$DOWNLOADED"
        cd "$TEMPDIR"
        "$TEMPDIR/$DOWNLOADED" --appimage-extract > /dev/null 2>&1
        cp -a "$TEMPDIR/squashfs-root/." "$MODULEDIR/"
        EXEC_CMD="$MODULEDIR/AppRun"
    else
        cp "$TEMPDIR/$DOWNLOADED" "$MODULEDIR/usr/local/bin/streamlink"
        chmod +x "$MODULEDIR/usr/local/bin/streamlink"
        EXEC_CMD="/usr/local/bin/streamlink"
    fi
else
    # Fallback: download Python wheel and extract
    echo "Downloading Streamlink via pip wheel..."
    pip3 download --no-deps --dest "$TEMPDIR" streamlink=="${VERSION}" 2>/dev/null \
        || { echo "ERROR: Could not download streamlink"; exit 1; }
    pip3 install --target "$MODULEDIR/usr/lib/python3/dist-packages" \
        --no-index --find-links "$TEMPDIR" streamlink=="${VERSION}" 2>/dev/null

    # Create wrapper script
    cat > "$MODULEDIR/usr/local/bin/streamlink" << 'WRAPPER'
#!/bin/bash
PYTHONPATH=/usr/lib/python3/dist-packages:$PYTHONPATH python3 -m streamlink "$@"
WRAPPER
    chmod +x "$MODULEDIR/usr/local/bin/streamlink"
    EXEC_CMD="/usr/local/bin/streamlink"
fi

cat > "$MODULEDIR/usr/share/applications/streamlink.desktop" << DESKTOP
[Desktop Entry]
Name=Streamlink
Comment=Stream Twitch, YouTube, and other live streams to VLC or MPV player
Exec=bash -c "$EXEC_CMD --player vlc twitch.tv/\$(zenity --entry --title='Streamlink' --text='Enter stream URL or Twitch channel:' 2>/dev/null)"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=AudioVideo;Network;
DESKTOP

# Also add a terminal launcher
cat > "$MODULEDIR/usr/share/applications/streamlink-cli.desktop" << DESKTOP
[Desktop Entry]
Name=Streamlink (Terminal)
Comment=Pipe Twitch/YouTube streams to VLC/MPV from command line
Exec=bash -c "echo 'Usage: streamlink <URL> best' && bash"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=AudioVideo;Network;
DESKTOP

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "Streamlink installed. Example: streamlink twitch.tv/channel best"
