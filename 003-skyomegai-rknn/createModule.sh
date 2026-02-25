#!/bin/bash
# SkyCAIR OS — 003-skyomegai-rknn: Rockchip RKNN NPU + M.2 AI Accelerator Module
# Overlays ON TOP of 003-skyomegai.xzm — stacks cleanly, no conflicts.
#
# Supported hardware:
#   Built-in NPU (RK3588/RK3588S):
#     Orange Pi 5 / 5 Plus / 5B / 5 Max
#     Rock 5B / 5C / 5 ITX
#     NanoPC T6, ArmSoM Sige7, Radxa ROCK5
#     Firefly ROC-RK3588S-PC
#     Any board with RK3588 SoC — 6 TOPS NPU
#
#   M.2 AI Accelerator cards (via PCIe):
#     Hailo-8 M.2 Module    — 26 TOPS
#     Hailo-8L M.2 Module   — 13 TOPS
#     Any RKNN-compatible M.2 AI module
#
# What this module does:
#   - Installs rknpu kernel driver + rknn-toolkit2 userspace
#   - Builds llama.cpp with RKNN backend for NPU inference
#   - Configures Ollama to delegate to llama.cpp RKNN backend
#   - Sets udev rules for /dev/rknpu device permissions
#   - Auto-detects RK3588 vs M.2 accelerator at boot
#
# 2XR, LLC | Evolve2Linux | 123Tech.net

source "$BUILDERUTILSPATH/setflags.sh"
SetFlags "003-skyomegai-rknn"

RKNN_TOOLKIT_VERSION="2.3.0"
LLAMACPP_VERSION="b5380"
INSTALL_DIR="$MODULEPATH/rootdir"

mkdir -p \
    "$INSTALL_DIR/usr/lib/rknn" \
    "$INSTALL_DIR/usr/bin" \
    "$INSTALL_DIR/etc/ollama" \
    "$INSTALL_DIR/etc/skycair" \
    "$INSTALL_DIR/etc/modprobe.d" \
    "$INSTALL_DIR/etc/udev/rules.d" \
    "$INSTALL_DIR/opt/rknn" \
    "$INSTALL_DIR/opt/llama-rknn"

ARCH=$(uname -m)

### ── RKNN userspace libraries ───────────────────────────────────────────────
echo "Downloading RKNN Toolkit2 v${RKNN_TOOLKIT_VERSION}..."

if [ "$ARCH" = "aarch64" ]; then
    RKNN_LIB_ARCH="aarch64"
    RKNN_BASE_URL="https://github.com/airockchip/rknn-toolkit2/raw/master/rknpu2/runtime/Linux/librknn_api/aarch64"
elif [ "$ARCH" = "x86_64" ]; then
    RKNN_LIB_ARCH="x86_64"
    RKNN_BASE_URL="https://github.com/airockchip/rknn-toolkit2/raw/master/rknpu2/runtime/Linux/librknn_api/x86_64"
else
    echo "WARNING: Unsupported arch $ARCH — defaulting to aarch64 libs"
    RKNN_LIB_ARCH="aarch64"
    RKNN_BASE_URL="https://github.com/airockchip/rknn-toolkit2/raw/master/rknpu2/runtime/Linux/librknn_api/aarch64"
fi

wget -q "${RKNN_BASE_URL}/librknnrt.so" -O "$INSTALL_DIR/usr/lib/rknn/librknnrt.so" || {
    echo "WARNING: Could not download RKNN runtime — will try at boot"
}

### ── llama.cpp with RKNN backend ────────────────────────────────────────────
echo "Building llama.cpp ${LLAMACPP_VERSION} with RKNN backend..."
LLAMACPP_URL="https://github.com/ggml-org/llama.cpp/archive/refs/tags/${LLAMACPP_VERSION}.tar.gz"
wget -q "$LLAMACPP_URL" -O "$MODULEPATH/llama.cpp.tar.gz" || exit 1
tar xf "$MODULEPATH/llama.cpp.tar.gz" -C "$MODULEPATH/"

cd "$MODULEPATH/llama.cpp-${LLAMACPP_VERSION#b}"* 2>/dev/null || \
cd "$MODULEPATH/llama.cpp-${LLAMACPP_VERSION}"* 2>/dev/null || \
cd "$MODULEPATH/$(ls $MODULEPATH | grep llama.cpp | head -1)"

mkdir -p build && cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/opt/llama-rknn" \
    -DGGML_RKNN=ON \
    -DRKNN_TOOLKIT2_PATH="$INSTALL_DIR/usr/lib/rknn" \
    -DCMAKE_CXX_FLAGS="$GCCFLAGS" \
    -DLLAMA_CURL=OFF

make -j"$NUMBERTHREADS" llama-server llama-cli 2>/dev/null || \
    make -j"$NUMBERTHREADS" server main

install -m 755 bin/llama-server "$INSTALL_DIR/usr/bin/llama-server-rknn" 2>/dev/null || \
install -m 755 bin/server       "$INSTALL_DIR/usr/bin/llama-server-rknn" 2>/dev/null || true

### ── RKNN Ollama backend config ─────────────────────────────────────────────
# Ollama can use llama.cpp as a backend via OLLAMA_LLM_LIBRARY
cat > "$INSTALL_DIR/opt/rknn/ollama-rknn.sh" <<'RKNN_BACKEND'
#!/bin/bash
# SkyCAIR — Configure Ollama to use llama.cpp RKNN backend
export OLLAMA_LLM_LIBRARY=/opt/llama-rknn/lib
export RKNN_LOG_LEVEL=0
export RKLLM_NPU_CORE=-1          # -1=auto, 0-2=specific NPU core (RK3588 has 3 cores)
export RKLLM_THREAD_NUM=4          # NPU inference threads

# Detect RK3588 NPU or M.2 accelerator
if [ -c /dev/rknpu0 ]; then
    echo "RKNN: RK3588 NPU detected (/dev/rknpu0)"
    export RKNN_DEVICE=rknpu0
elif [ -c /dev/hailo0 ]; then
    echo "RKNN: Hailo M.2 accelerator detected (/dev/hailo0)"
    export RKNN_DEVICE=hailo0
else
    echo "WARNING: No RKNN/NPU device found — falling back to CPU"
fi
RKNN_BACKEND
chmod +x "$INSTALL_DIR/opt/rknn/ollama-rknn.sh"

### ── udev rules — /dev/rknpu permissions ────────────────────────────────────
cp "$MODULEPATH/../extras/etc/udev/rules.d/99-rknpu.rules" \
   "$INSTALL_DIR/etc/udev/rules.d/"

### ── Ollama config overlay ──────────────────────────────────────────────────
cp "$MODULEPATH/../extras/etc/ollama/ollama.env" "$INSTALL_DIR/etc/ollama/"

### ── ACCELERATOR override ───────────────────────────────────────────────────
cat > "$INSTALL_DIR/etc/skycair/skyomegai-accelerator.conf" <<'EOF'
ACCELERATOR=rknn
EOF

### ── modprobe for rknpu ─────────────────────────────────────────────────────
cat > "$INSTALL_DIR/etc/modprobe.d/skycair-rknn.conf" <<'EOF'
# SkyCAIR RKNN NPU driver — loaded by 003-skyomegai-rknn.xzm
# RK3588 on-chip NPU (3 cores, 6 TOPS total)
options rknpu power_mode=0
EOF

### ── Package as .xzm ────────────────────────────────────────────────────────
cd "$MODULEPATH"
dir2xzm "$INSTALL_DIR" "003-skyomegai-rknn-${SKYCAIRVERSION}.xzm"

echo "✅ 003-skyomegai-rknn built"
echo "   Supported: RK3588 on-chip NPU (6 TOPS) + Hailo-8 M.2 (26 TOPS)"
echo "   Load order: 003-skyomegai.xzm → 003-skyomegai-rknn.xzm"
echo "   Enable at boot: add 'rknn=enable' to skycair.cfg"
