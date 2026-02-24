#!/bin/bash
# Open WebUI — browser-based chat UI for Ollama (Claude-like interface, fully offline)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64
# Requires Ollama to be running first

CURRENTPACKAGE=open-webui
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/open-webui/open-webui/releases/latest \
    | grep '"tag_name"' | grep -oP '"\Kv[\d.]+' | head -1 | tr -d 'v')
[ -z "$VERSION" ] && VERSION="0.6.5"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" \
    "$MODULEDIR/opt/open-webui" \
    "$MODULEDIR/etc/systemd/system" \
    "$MODULEDIR/usr/share/applications" \
    "$MODULEDIR/usr/local/bin"

# Open WebUI is distributed as a Python package — install to module directory
echo "Installing Open WebUI ${VERSION}..."

# Download the pip package
pip3 download --no-deps --dest "$TEMPDIR" "open-webui==${VERSION}" 2>/dev/null \
    || pip3 download --no-deps --dest "$TEMPDIR" "open-webui" 2>/dev/null \
    || {
        echo "Downloading Open WebUI wheel from GitHub..."
        WHEEL_URL=$(curl -s https://api.github.com/repos/open-webui/open-webui/releases/latest \
            | grep '"browser_download_url"' | grep '\.whl' | grep -oP 'https://[^"]+' | head -1)
        [ -n "$WHEEL_URL" ] && wget -T 60 -P "$TEMPDIR" "$WHEEL_URL"
    }

# Install to module opt dir
pip3 install --target "$MODULEDIR/opt/open-webui" \
    --no-index --find-links "$TEMPDIR" "open-webui==${VERSION}" 2>/dev/null \
    || pip3 install --target "$MODULEDIR/opt/open-webui" "open-webui==${VERSION}" || exit 1

# Wrapper script
cat > "$MODULEDIR/usr/local/bin/open-webui" << 'WRAPPER'
#!/bin/bash
export PYTHONPATH=/opt/open-webui:$PYTHONPATH
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"
export PORT="${OPEN_WEBUI_PORT:-3001}"
python3 -m open_webui.main "$@"
WRAPPER
chmod +x "$MODULEDIR/usr/local/bin/open-webui"

# User systemd service
cat > "$MODULEDIR/etc/systemd/system/open-webui-user.service" << SERVICE
[Unit]
Description=Open WebUI — Private AI Chat Interface (SkyCAIR)
After=ollama-user.service
Requires=ollama-user.service
Documentation=https://docs.openwebui.com

[Service]
ExecStart=/usr/local/bin/open-webui
Environment=PYTHONPATH=/opt/open-webui
Environment=OLLAMA_BASE_URL=http://localhost:11434
Environment=PORT=3001
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SERVICE

# Desktop launcher
cat > "$MODULEDIR/usr/share/applications/open-webui.desktop" << DESKTOP
[Desktop Entry]
Name=SkyCAIR AI Chat
Comment=Private AI chat interface — requires Ollama running locally
Exec=bash -c "open-webui & sleep 3 && xdg-open http://localhost:3001"
Icon=internet-web-browser
Terminal=false
Type=Application
Categories=AI;Network;
DESKTOP

mkdir -p "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE"
cat > "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE/README.txt" << README
Open WebUI v${VERSION} — SkyCAIR Private AI Web Interface

Access: http://localhost:3001
Requires: ollama serve (start Ollama first)

Quick start:
  1. Start Ollama: ollama serve
  2. Pull a model: ollama pull llama3.2:3b
  3. Start Open WebUI: open-webui
  4. Open: http://localhost:3001

Works completely OFFLINE. No cloud/internet required after setup.
README

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "Open WebUI installed. Start: open-webui then visit http://localhost:3001"
