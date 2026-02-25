#!/bin/bash
# SkyCAIR OS — 003-skyomegai: Build SkyOMEGAi AI Module
# Installs Ollama + Open WebUI + Claude API config as a .xzm module.
#
# AI ENGINE CHOICE (set in /etc/skycair/skyomegai.conf after install):
#   engine=ollama   → local inference on your hardware (default)
#   engine=claude   → Anthropic Claude API (requires ANTHROPIC_API_KEY)
#   engine=both     → Ollama local + Claude cloud — choose in Open WebUI
#
# HARDWARE ACCELERATION: load the matching sub-module alongside this one:
#   003-skyomegai-nvidia.xzm  → NVIDIA CUDA
#   003-skyomegai-amd.xzm     → AMD ROCm
#   003-skyomegai-rknn.xzm    → Rockchip NPU / M.2 AI accelerator
#
# 2XR, LLC | Evolve2Linux | 123Tech.net | SkyCAIR@123Tech.net

source "$BUILDERUTILSPATH/setflags.sh"
SetFlags "003-skyomegai"

OLLAMA_VERSION="0.7.3"
OPENWEBUI_VERSION="0.6.5"
INSTALL_DIR="$MODULEPATH/rootdir"
OLLAMA_BIN="$INSTALL_DIR/usr/bin"
OLLAMA_LIB="$INSTALL_DIR/usr/lib/ollama"
MODELS_DIR="$INSTALL_DIR/skycair/ai/models"

mkdir -p "$OLLAMA_BIN" "$OLLAMA_LIB" "$MODELS_DIR"

### ── Download Ollama ─────────────────────────────────────────────────────────
echo "Downloading Ollama v${OLLAMA_VERSION} (CPU fallback build)..."
OLLAMA_URL="https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64"
wget -q "$OLLAMA_URL" -O "$OLLAMA_BIN/ollama" || exit 1
chmod +x "$OLLAMA_BIN/ollama"

### ── Ollama service config ───────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/etc/ollama" "$INSTALL_DIR/etc/rc.d"
cp "$MODULEPATH/../extras/etc/ollama/ollama.env"    "$INSTALL_DIR/etc/ollama/"
cp "$MODULEPATH/../extras/etc/rc.d/rc.ollama"       "$INSTALL_DIR/etc/rc.d/"
chmod +x "$INSTALL_DIR/etc/rc.d/rc.ollama"

### ── Claude API proxy config ────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/etc/skycair"
cp "$MODULEPATH/../extras/etc/skycair/skyomegai.conf" "$INSTALL_DIR/etc/skycair/"

### ── Open WebUI ─────────────────────────────────────────────────────────────
echo "Installing Open WebUI ${OPENWEBUI_VERSION}..."
WEBUI_DIR="$INSTALL_DIR/opt/open-webui"
mkdir -p "$WEBUI_DIR"

# Download pre-built Open WebUI release (or pip install into module)
pip3 install \
    --target="$WEBUI_DIR/lib" \
    --no-deps \
    open-webui=="${OPENWEBUI_VERSION}" 2>/dev/null || {

    # Fallback: download from GitHub releases
    WEBUI_URL="https://github.com/open-webui/open-webui/releases/download/v${OPENWEBUI_VERSION}/open-webui-${OPENWEBUI_VERSION}.tar.gz"
    wget -q "$WEBUI_URL" -O "$MODULEPATH/open-webui.tar.gz" && \
    tar xf "$MODULEPATH/open-webui.tar.gz" -C "$WEBUI_DIR" --strip-components=1 || true
}

# Open WebUI startup script
cp "$MODULEPATH/../extras/opt/skycair-scripts/skyomegai-webui.sh" \
   "$INSTALL_DIR/opt/skycair-scripts/"
chmod +x "$INSTALL_DIR/opt/skycair-scripts/skyomegai-webui.sh"

# Open WebUI service
cp "$MODULEPATH/../extras/etc/rc.d/rc.open-webui" "$INSTALL_DIR/etc/rc.d/"
chmod +x "$INSTALL_DIR/etc/rc.d/rc.open-webui"

### ── Desktop launcher ───────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/usr/share/applications"
cat > "$INSTALL_DIR/usr/share/applications/skyomegai.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=SkyOMEGAi
Comment=Private AI — Ollama + Claude (SkyCAIR Care About AI Readiness)
Exec=xdg-open http://localhost:3001
Icon=skyomegai
Terminal=false
Categories=Network;Science;AI;
Keywords=ai;ollama;claude;llm;chatbot;skycair;
StartupNotify=false
EOF

### ── Model storage symlink ──────────────────────────────────────────────────
# Point Ollama model dir to persistent /skycair/ai/models/ (SkyFILES partition)
mkdir -p "$INSTALL_DIR/root/.ollama"
ln -sfn /skycair/ai/models "$INSTALL_DIR/root/.ollama/models"

### ── Package as .xzm ────────────────────────────────────────────────────────
cd "$MODULEPATH"
dir2xzm "$INSTALL_DIR" "003-skyomegai-${SKYCAIRVERSION}.xzm"

echo "✅ 003-skyomegai built: 003-skyomegai-${SKYCAIRVERSION}.xzm"
echo "   Load alongside hardware accelerator module:"
echo "   003-skyomegai-nvidia.xzm  OR  003-skyomegai-amd.xzm  OR  003-skyomegai-rknn.xzm"
