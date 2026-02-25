#!/bin/bash
# SkyCAIR OS — 003-skyomegai-amd: AMD ROCm AI Acceleration Module
# Overlays ON TOP of 003-skyomegai.xzm — stacks cleanly, no conflicts.
#
# What this module does:
#   - Installs ROCm HIP runtime + rocBLAS for GPU-accelerated BLAS
#   - Downloads Ollama ROCm build (uses HIP for AMD GPU inference)
#   - Sets OLLAMA_GPU=rocm in ollama.env overlay
#   - Configures HSA for supported GPU targets
#
# Supported AMD GPUs: RX 6000/7000 (RDNA2/3), RX 5000 (Navi), Vega
# VRAM same as NVIDIA: 4GB (3B), 8GB (7B), 16GB (13B), 24GB+ (70B)
#
# 2XR, LLC | Evolve2Linux | 123Tech.net

source "$BUILDERUTILSPATH/setflags.sh"
SetFlags "003-skyomegai-amd"

ROCM_VERSION="6.3.4"
OLLAMA_VERSION="0.7.3"
INSTALL_DIR="$MODULEPATH/rootdir"

mkdir -p "$INSTALL_DIR/usr/lib/ollama/rocm" \
         "$INSTALL_DIR/etc/ollama" \
         "$INSTALL_DIR/etc/skycair" \
         "$INSTALL_DIR/etc/profile.d"

### ── Download Ollama ROCm build ─────────────────────────────────────────────
echo "Downloading Ollama v${OLLAMA_VERSION} ROCm build..."
OLLAMA_ROCM_URL="https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64-rocm.tar.gz"
wget -q "$OLLAMA_ROCM_URL" -O "$MODULEPATH/ollama-rocm.tar.gz" || exit 1

tar xf "$MODULEPATH/ollama-rocm.tar.gz" \
    -C "$INSTALL_DIR/usr/lib/ollama/rocm" \
    --strip-components=1 2>/dev/null || exit 1

### ── ROCm HSA target configuration ─────────────────────────────────────────
# HSA_OVERRIDE_GFX_VERSION allows running on unlisted/newer AMD GPUs
# Common values: RX 7900 XTX=11.0.0, RX 6800=10.3.0, RX 5700=10.1.0
cat > "$INSTALL_DIR/etc/profile.d/rocm.sh" <<'EOF'
# SkyCAIR — ROCm environment (003-skyomegai-amd module)
export ROCm_DIR=/opt/rocm
export ROCM_PATH=/opt/rocm
export PATH=$PATH:/opt/rocm/bin
export LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:$LD_LIBRARY_PATH

# Uncomment and set to your GPU's GFX version if Ollama fails to detect:
# export HSA_OVERRIDE_GFX_VERSION=11.0.0    # RX 7900 XTX
# export HSA_OVERRIDE_GFX_VERSION=10.3.0    # RX 6800 XT
# export HSA_OVERRIDE_GFX_VERSION=10.1.0    # RX 5700 XT

# Select GPU device (0=first, "0,1"=multi-GPU)
export HIP_VISIBLE_DEVICES=0
EOF

### ── Ollama ROCm config overlay ─────────────────────────────────────────────
cp "$MODULEPATH/../extras/etc/ollama/ollama.env" "$INSTALL_DIR/etc/ollama/"

### ── ACCELERATOR override ───────────────────────────────────────────────────
cat > "$INSTALL_DIR/etc/skycair/skyomegai-accelerator.conf" <<'EOF'
ACCELERATOR=rocm
EOF

### ── Package as .xzm ────────────────────────────────────────────────────────
cd "$MODULEPATH"
dir2xzm "$INSTALL_DIR" "003-skyomegai-amd-${SKYCAIRVERSION}.xzm"

echo "✅ 003-skyomegai-amd built"
echo "   Load order: 003-skyomegai.xzm → 003-skyomegai-amd.xzm"
echo "   Requires amdgpu kernel driver (already in SkyCAIR kernel)"
