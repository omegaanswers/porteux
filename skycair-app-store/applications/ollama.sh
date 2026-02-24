#!/bin/bash
# Ollama — local LLM inference server (offgrid private AI)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64
# Works fully offline after model download

CURRENTPACKAGE=ollama
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest \
    | grep '"tag_name"' | grep -oP '"\Kv[\d.]+' | head -1 | tr -d 'v')
[ -z "$VERSION" ] && VERSION="0.6.2"

OLLAMA_ARCH=$([[ "$ARCH" == "aarch64" ]] && echo "arm64" || echo "amd64")
BINARY_URL="https://github.com/ollama/ollama/releases/download/v${VERSION}/ollama-linux-${OLLAMA_ARCH}"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR/usr/local/bin" \
    "$MODULEDIR/etc/systemd/system" \
    "$MODULEDIR/usr/share/applications" \
    "$MODULEDIR/opt/skycair/ai/models"

echo "Downloading Ollama ${VERSION} (${ARCH})..."
wget -T 30 -O "$MODULEDIR/usr/local/bin/ollama" "$BINARY_URL" || exit 1
chmod +x "$MODULEDIR/usr/local/bin/ollama"

# User-level systemd service (rootless)
cat > "$MODULEDIR/etc/systemd/system/ollama-user.service" << SERVICE
[Unit]
Description=Ollama — Local LLM Server (SkyCAIR Private AI)
After=network.target
Documentation=https://ollama.com

[Service]
ExecStart=/usr/local/bin/ollama serve
Environment=OLLAMA_MODELS=/opt/skycair/ai/models
Environment=OLLAMA_HOST=127.0.0.1:11434
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SERVICE

# Desktop launcher to open terminal with ollama
cat > "$MODULEDIR/usr/share/applications/ollama.desktop" << DESKTOP
[Desktop Entry]
Name=Ollama AI Chat
Comment=Private local AI — run LLMs offline (llama3, mistral, phi3, qwen2.5)
Exec=bash -c "ollama run llama3.2:3b; read -p 'Press Enter to close...'"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=AI;Science;
DESKTOP

# Install info
mkdir -p "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE"
cat > "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE/QUICKSTART.txt" << README
Ollama v${VERSION} — SkyCAIR Private AI (Offline)

Start server:  ollama serve
Pull a model:  ollama pull llama3.2:3b     (2.0GB)
               ollama pull phi3:mini       (2.3GB)
               ollama pull qwen2.5:3b      (1.9GB)
               ollama pull mistral:7b      (4.1GB — needs 8GB+ RAM)
Chat CLI:      ollama run llama3.2:3b
Web UI:        Install open-webui from SkyCAIR App Store (port 3001)
Models stored: /opt/skycair/ai/models/
API:           http://localhost:11434/api/

Works fully OFFLINE — no internet needed after model download.
Rockchip RK3588: enable ai=rknn in skycair.cfg for NPU acceleration.
README

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "Ollama installed. Run: ollama serve && ollama pull llama3.2:3b"
