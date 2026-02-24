#!/bin/bash
# AMD ROCm — open GPU compute platform (OpenCL, HIP, AI/ML on AMD GPUs)
# SkyCAIR App Store | 2XR, LLC | 123Tech.net
# 64-bit only: x86_64 (ROCm is x86_64 only; ARM64 support is experimental)

CURRENTPACKAGE=amd-rocm
ARCH=$(uname -m)
OUTPUTDIR="$PORTDIR/optional/"
TEMPDIR="/tmp/$CURRENTPACKAGE-builder"
MODULEDIR="$TEMPDIR/$CURRENTPACKAGE-module"

[[ "$ARCH" != "x86_64" ]] && echo "AMD ROCm is x86_64 only. Use Mesa/OpenCL for aarch64 AMD GPUs." && exit 1

VERSION=$(curl -s https://api.github.com/repos/RadeonOpenCompute/ROCm/releases/latest \
    | grep '"tag_name"' | grep -oP '"rocm-\K[\d.]+' | head -1)
[ -z "$VERSION" ] && VERSION="6.3.4"

rm -fr "$TEMPDIR"
mkdir -p "$TEMPDIR" "$MODULEDIR/opt/rocm" "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE"

echo "AMD ROCm ${VERSION} — downloading userspace components..."
echo "NOTE: ROCm requires amdgpu kernel driver with ROCm support."
echo "Supported GPUs: RX 6000/7000 series (RDNA2/RDNA3), Vega, MI series"

# ROCm OpenCL runtime and tools (lighter than full ROCm suite)
OPENCL_URL=$(curl -s https://api.github.com/repos/RadeonOpenCompute/ROCm-OpenCL-Runtime/releases/latest \
    | grep '"browser_download_url"' | grep '\.tar' | grep -oP 'https://[^"]+' | head -1)

if [ -n "$OPENCL_URL" ]; then
    wget -T 60 -P "$TEMPDIR" "$OPENCL_URL" || exit 1
    tar -xf "$TEMPDIR"/*.tar* -C "$MODULEDIR/opt/rocm" 2>/dev/null || exit 1
else
    echo "Downloading ROCm from AMD repo..."
    # AMD provides .deb and .rpm packages
    RPM_URL="https://repo.radeon.com/rocm/rhel9/${VERSION}/main/amd64/rocm-opencl-${VERSION}-1.el9.x86_64.rpm"
    wget -T 60 -P "$TEMPDIR" "$RPM_URL" 2>/dev/null \
        || { echo "RPM download failed — check https://rocm.docs.amd.com for installation."; exit 1; }
    # Extract RPM contents
    cd "$MODULEDIR"
    rpm2cpio "$TEMPDIR"/*.rpm | cpio -idmv 2>/dev/null
fi

cat > "$MODULEDIR/usr/share/doc/$CURRENTPACKAGE/README.txt" << README
AMD ROCm ${VERSION} — GPU Compute Platform

Supported AMD GPUs:
  - RX 6000/7000 series (RDNA2/RDNA3) — Recommended
  - Vega, MI series (datacenter)

Requirements:
  - Linux kernel 5.15+ with AMDGPU driver
  - ROCm-capable GPU (see: https://rocm.docs.amd.com/projects/install-on-linux)

Verify GPU detection:
  rocm-smi          — GPU status and monitoring
  rocminfo          — GPU compute info
  clinfo            — OpenCL platforms and devices

Use with Ollama (AI acceleration):
  ROCR_VISIBLE_DEVICES=0 ollama serve

Environment setup:
  export PATH=/opt/rocm/bin:$PATH
  export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
README

# Environment setup module
mkdir -p "$MODULEDIR/etc/profile.d"
cat > "$MODULEDIR/etc/profile.d/rocm.sh" << ENV
# AMD ROCm environment
export PATH=/opt/rocm/bin:\$PATH
export LD_LIBRARY_PATH=/opt/rocm/lib:\$LD_LIBRARY_PATH
export HIP_PLATFORM=amd
ENV

MODULEFILENAME="$CURRENTPACKAGE-${VERSION}-${ARCH}_skycair.xzm"
ACTIVATEMODULE=$([[ "$@" == *"--activate-module"* ]] && echo "--activate-module")

/opt/skycair-scripts/skycair-app-store/module-builder.sh "$MODULEDIR" "$OUTPUTDIR/$MODULEFILENAME" "$ACTIVATEMODULE"

rm -fr "$TEMPDIR" 2>/dev/null
echo "AMD ROCm installed. Verify: rocm-smi && clinfo"
