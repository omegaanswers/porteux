#!/bin/bash
# SkyCAIR OS — 004-installer: Build Calamares .xzm installer module
# Compiles Calamares from SlackBuilds source and packages as a signed .xzm
source "$BUILDERUTILSPATH/setflags.sh"
SetFlags "004-installer"

CALAMARES_VERSION="3.3.14"
CALAMARES_SRC="https://github.com/calamares/calamares/releases/download/v${CALAMARES_VERSION}/calamares-${CALAMARES_VERSION}.tar.gz"
INSTALL_DIR="$MODULEPATH/rootdir"

mkdir -p "$INSTALL_DIR"
cd "$MODULEPATH"

### Download Calamares source
echo "Downloading Calamares v${CALAMARES_VERSION}..."
wget -q "$CALAMARES_SRC" -O "calamares-${CALAMARES_VERSION}.tar.gz" || exit 1
tar xf "calamares-${CALAMARES_VERSION}.tar.gz"

### Build Calamares with Qt5/KDE Frameworks
cd "calamares-${CALAMARES_VERSION}"
mkdir build && cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_CXX_FLAGS="$GCCFLAGS" \
    -DCMAKE_C_FLAGS="$GCCFLAGS" \
    -DSKIP_MODULES="webview interactiveterminal" \
    -DBoost_NO_BOOST_CMAKE=ON \
    -DWITH_PYTHONQT=OFF \
    -DWITH_QT6=OFF

make -j"$NUMBERTHREADS"
make DESTDIR="$INSTALL_DIR" install

### Install SkyCAIR Calamares config
CALAMARES_CFG="$INSTALL_DIR/etc/calamares"
mkdir -p "$CALAMARES_CFG/branding/skycair"
mkdir -p "$CALAMARES_CFG/modules"

### Copy SkyCAIR branding and module configs from extras/
cp -r "$SKYCAIRBUILDERPATH/../extras/calamares/branding/skycair/"* "$CALAMARES_CFG/branding/skycair/"
cp    "$SKYCAIRBUILDERPATH/../extras/calamares/settings.conf"       "$CALAMARES_CFG/"
cp    "$SKYCAIRBUILDERPATH/../extras/calamares/modules/"*.conf      "$CALAMARES_CFG/modules/"

### Desktop launcher
APPS_DIR="$INSTALL_DIR/usr/share/applications"
mkdir -p "$APPS_DIR"
cp "$SKYCAIRBUILDERPATH/../extras/applications/install-skycair.desktop" "$APPS_DIR/"

### PolicyKit rule — allow Calamares to run elevated from desktop
POLKIT_DIR="$INSTALL_DIR/usr/share/polkit-1/actions"
mkdir -p "$POLKIT_DIR"
cat > "$POLKIT_DIR/com.github.calamares.calamares.policy" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="com.github.calamares.calamares.install">
    <description>Run Calamares installer</description>
    <message>Authentication is required to install SkyCAIR OS</message>
    <defaults>
      <allow_any>auth_admin</allow_any>
      <allow_inactive>auth_admin</allow_inactive>
      <allow_active>yes</allow_active>
    </defaults>
  </action>
</policyconfig>
EOF

### Package as .xzm signed module
cd "$MODULEPATH"
makepkg $MAKEPKGFLAGS "004-installer-${SKYCAIRVERSION}-noarch-1_skycair.txz" <<'EOF'
rootdir
EOF

dir2xzm "$INSTALL_DIR" "004-installer-${SKYCAIRVERSION}.xzm"

echo "✅ 004-installer module built: 004-installer-${SKYCAIRVERSION}.xzm"
