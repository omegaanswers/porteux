#!/bin/bash
# llama.cpp — CPU/GPU LLM inference in pure C++ (lightweight private AI, offgrid)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64, aarch64
# Runs GGUF models — offline, no internet required after model download

CURRENTPACKAGE=llama-cpp
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/modules/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] && echo "ERROR: 64-bit only (x86_64 or aarch64)." && exit 1

VERSION=$(curl -s https://api.github.com/repos/ggerganov/llama.cpp/releases/latest \
    | grep '"tag_name"' | grep -oP '"\Kb[\d]+' | head -1)
[ -z "$VERSION" ] && VERSION="b5004"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" \
    "$MODULEDIR/usr/local/bin" \
    "$MODULEDIR/usr/share/applications" \
    "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE" \
    "$MODULEDIR/opt/skycair/ai/models"

# llama.cpp provides prebuilt binaries on GitHub releases
if [[ "$ARCH" == "x86_64" ]]; then
    TARBALL_URL=$(curl -s https://api.github.com/repos/ggerganov/llama.cpp/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'linux-x64\|linux-amd64\|ubuntu-x64' \
        | grep -v 'cuda\|vulkan\|opencl' \
        | grep 'tar\|zip' \
        | grep -oP 'https://[^"]+' | head -1)
    [ -z "$TARBALL_URL" ] && \
        TARBALL_URL="https://github.com/ggerganov/llama.cpp/releases/download/${VERSION}/llama-${VERSION}-bin-ubuntu-x64.zip"
else
    TARBALL_URL=$(curl -s https://api.github.com/repos/ggerganov/llama.cpp/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'linux-arm64\|linux-aarch64' \
        | grep -v 'cuda\|vulkan' \
        | grep 'tar\|zip' \
        | grep -oP 'https://[^"]+' | head -1)
    [ -z "$TARBALL_URL" ] && \
        TARBALL_URL="https://github.com/ggerganov/llama.cpp/releases/download/${VERSION}/llama-${VERSION}-bin-ubuntu-arm64.zip"
fi

echo "Downloading llama.cpp ${VERSION} (${ARCH})..."
wget -T 30 -P "$TEMPDIR" "$TARBALL_URL" || exit 1

# Extract binaries
cd "$TEMPDIR"
if ls "$TEMPDIR"/*.zip > /dev/null 2>&1; then
    unzip -q "$TEMPDIR"/*.zip -d "$TEMPDIR/llama-bins"
elif ls "$TEMPDIR"/*.tar* > /dev/null 2>&1; then
    mkdir "$TEMPDIR/llama-bins"
    tar -xf "$TEMPDIR"/*.tar* -C "$TEMPDIR/llama-bins"
fi

# Copy key binaries
for BIN in llama-cli llama-server llama-bench llama-quantize llama-run; do
    find "$TEMPDIR/llama-bins" -name "$BIN" -type f -exec cp {} "$MODULEDIR/usr/local/bin/" \;
    chmod +x "$MODULEDIR/usr/local/bin/$BIN" 2>/dev/null
done

cat > "$MODULEDIR/usr/share/applications/llama-cpp.desktop" << DESKTOP
[Desktop Entry]
Name=llama.cpp Chat
Comment=Lightweight local AI inference (CPU/GPU) — runs GGUF models offline
Exec=bash -c "llama-cli --model /opt/skycair/ai/models/\$(ls /opt/skycair/ai/models/*.gguf 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'model.gguf') --interactive --n-predict 512; read"
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=AI;Science;
DESKTOP

cat > "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE/README.txt" << README
llama.cpp ${VERSION} — SkyCAIR Private AI Inference

Download a GGUF model to /opt/skycair/ai/models/:
  wget -P /opt/skycair/ai/models/ \\
    https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf

Interactive chat:
  llama-cli -m /opt/skycair/ai/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf -i

OpenAI-compatible API server (port 8080):
  llama-server -m /opt/skycair/ai/models/model.gguf --host 0.0.0.0 --port 8080

Works OFFLINE — no internet needed after model download.
Rockchip RK3588: use Ollama with ai=rknn for NPU acceleration.
README

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "llama.cpp installed. Place .gguf models in /opt/skycair/ai/models/"
