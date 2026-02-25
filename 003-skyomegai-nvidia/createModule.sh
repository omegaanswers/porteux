#!/bin/bash
# SkyCAIR OS — 003-skyomegai-nvidia: NVIDIA CUDA AI Acceleration Module
# Overlays ON TOP of 003-skyomegai.xzm — stacks cleanly, no conflicts.
# Requires: nvidia-driver.xzm loaded first (from nvidia-driver/ module)
#
# What this module does:
#   - Installs CUDA runtime libraries (libcuda, libcublas, etc.)
#   - Replaces /etc/ollama/ollama.env with CUDA-enabled version
#   - Sets OLLAMA_GPU=cuda so Ollama uses NVIDIA GPU for inference
#   - Configures GPU memory management for LLM workloads
#
# Supported GPUs: NVIDIA RTX 30xx/40xx, GTX 1080+, Tesla/A100/H100
# VRAM requirements: 4GB (3B models), 8GB (7B), 16GB (13B), 24GB+ (70B)
#
# 2XR, LLC | Evolve2Linux | 123Tech.net

source "$BUILDERUTILSPATH/setflags.sh"
SetFlags "003-skyomegai-nvidia"

CUDA_VERSION="12.4"
INSTALL_DIR="$MODULEPATH/rootdir"
CUDA_LIB="$INSTALL_DIR/usr/lib64/cuda"
OLLAMA_CUDA_VERSION="0.7.3"

mkdir -p "$CUDA_LIB" "$INSTALL_DIR/etc/ollama" "$INSTALL_DIR/etc/profile.d"

### ── Download Ollama with CUDA backend ──────────────────────────────────────
echo "Downloading Ollama v${OLLAMA_CUDA_VERSION} with CUDA backend..."
OLLAMA_CUDA_URL="https://github.com/ollama/ollama/releases/download/v${OLLAMA_CUDA_VERSION}/ollama-linux-amd64-cuda12.tar.gz"
wget -q "$OLLAMA_CUDA_URL" -O "$MODULEPATH/ollama-cuda.tar.gz" || exit 1

mkdir -p "$INSTALL_DIR/usr/lib/ollama/cuda"
tar xf "$MODULEPATH/ollama-cuda.tar.gz" \
    -C "$INSTALL_DIR/usr/lib/ollama/cuda" \
    --strip-components=1 2>/dev/null || exit 1

### ── CUDA environment overlay ───────────────────────────────────────────────
cat > "$INSTALL_DIR/etc/profile.d/cuda.sh" <<'EOF'
# SkyCAIR — CUDA environment (003-skyomegai-nvidia module)
export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib64/cuda:$LD_LIBRARY_PATH
export PATH=$PATH:/usr/local/cuda/bin
EOF

### ── Ollama CUDA config (overlays base module's ollama.env) ─────────────────
cp "$MODULEPATH/../extras/etc/ollama/ollama.env" "$INSTALL_DIR/etc/ollama/"

### ── skyomegai.conf ACCELERATOR override ───────────────────────────────────
mkdir -p "$INSTALL_DIR/etc/skycair"
cat > "$INSTALL_DIR/etc/skycair/skyomegai-accelerator.conf" <<'EOF'
# SkyCAIR — Loaded by 003-skyomegai-nvidia.xzm overlay
# Overrides ACCELERATOR setting in skyomegai.conf
ACCELERATOR=cuda
EOF

### ── Package as .xzm ────────────────────────────────────────────────────────
cd "$MODULEPATH"
dir2xzm "$INSTALL_DIR" "003-skyomegai-nvidia-${SKYCAIRVERSION}.xzm"

echo "✅ 003-skyomegai-nvidia built"
echo "   Load order: nvidia-driver.xzm → 003-skyomegai.xzm → 003-skyomegai-nvidia.xzm"
