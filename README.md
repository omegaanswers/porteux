# SkyCAIR OS

> **Care About AI Readiness** — From IoT sensor to enterprise data center, one codebase.

[![Validate Build Scripts](https://github.com/omegaanswers/porteux/actions/workflows/validate.yml/badge.svg?branch=skycair-2.6-cosmic)](https://github.com/omegaanswers/porteux/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Source%20Available-blue)](LICENSE)
[![Version](https://img.shields.io/badge/version-v2.6.0-brightgreen)](https://github.com/omegaanswers/porteux/releases/tag/v2.6.0-skycair)
[![Platform](https://img.shields.io/badge/platform-x86__64-lightgrey)](https://github.com/omegaanswers/porteux)
[![Desktop](https://img.shields.io/badge/desktop-COSMIC-purple)](https://github.com/pop-os/cosmic-epoch)

**2XR, LLC | Evolve2Linux | 123Tech.net**

| | |
|---|---|
| Website | https://123tech.net |
| Contact | SkyCAIR@123Tech.net |
| Phone | (608) 454-6660 |
| Address | 855 Community Dr, Sauk City, WI 53583 |
| Branch | [`skycair-2.6-cosmic`](https://github.com/omegaanswers/porteux/tree/skycair-2.6-cosmic) |

---

## About

SkyCAIR OS is a high-performance, modular, Slackware-based Linux distribution purpose-built
for AI-ready infrastructure — from IoT edge devices to enterprise data centers.

- **Blazing fast**: squashfs modules load into RAM at boot; full system in seconds
- **Modular**: .xzm squashfs modules stack via overlayfs — add/remove features without reinstalling
- **Portable**: runs live from USB, SD, or NVMe; no installation required
- **Immutable option**: boot read-only with optional persistent save layer
- **Multimedia-ready**: hardware acceleration enabled by default (Intel / AMD / NVIDIA)
- **8 desktop environments**: COSMIC, Cinnamon, GNOME, KDE, LXDE, LXQt, MATE, Xfce

No browser is included by default — the **SkyCAIR App Store** provides browsers,
Steam, VirtualBox, NVIDIA drivers, Wine, office suites, messengers, emulators, and more.

---

## Quick Start

1. Download the ISO from [123tech.net](https://123tech.net)
2. Copy ISO content to your media storage
3. Run the installer from the `boot` folder:
   - Linux: `skycair-installer-for-linux.run`
   - Windows: `skycair-installer-for-windows.exe`
4. Boot and enjoy

> Avoid Rufus/Etcher — they set media read-only by default, which disables persistence.
> Full installation guide: [iso/boot/docs/install.txt](iso/boot/docs/install.txt)

### Default Credentials

```
username: guest    password: guest
username: root     password: toor
```

---

## Desktop Environments

| Spin | Description |
|------|-------------|
| **COSMIC** | System76's next-gen Wayland compositor (recommended) |
| Cinnamon | Traditional, Windows-like layout |
| GNOME | Clean, modern GNOME shell |
| KDE | Feature-rich, highly customizable |
| LXDE | Ultra-lightweight, older hardware |
| LXQt | Qt-based lightweight desktop |
| MATE | Classic GNOME 2 experience |
| Xfce | Fast and lightweight GTK |

---

## Installing Applications

**App Store** (recommended): Launch the SkyCAIR App Store for browsers, tools, and drivers.

**AppImage**: Drop-and-run, no installation needed.

**Slackware package → XZM module**:
```bash
getpkg -m <packageName>
activate <moduleName>
# Move to /skycair/modules/ for auto-load on boot
```

**Flatpak**: Available by default via the Flatpak runtime.

---

## Performance

- Runs on any SSE4.2-capable x86_64 machine
- Best performance: NVMe/SSD install, or **Copy To RAM** at boot (requires 2GB+ RAM)
- Boot configuration: [`iso/skycair/skycair.cfg`](iso/skycair/skycair.cfg)

---

## Building

Requires a **Slackware 64-bit current** or **SkyCAIR live** environment. Build as root:

```bash
# Build in this order:
sh 000-kernel/createModule.sh
sh 001-core/createModule.sh
sh 002-gui/createModule.sh
sh 002-xtra/createModule.sh
sh 003-cosmic/createModule.sh        # or other desktop
sh 05-devel/createModule.sh          # optional
sh 08-multilanguage/createModule.sh  # optional
sh 0050-multilib-lite/createModule.sh # optional
```

Output: `/tmp/skycair-builder-<version>/`

Build an ISO:
```bash
sh iso/skycair/create-iso.sh /tmp/skycair.iso
```

---

## Module System

SkyCAIR uses `.xzm` squashfs modules stacked via overlayfs at boot:

```
/skycair/base/      ← core modules (auto-loaded)
/skycair/modules/   ← optional modules (auto-loaded)
```

To activate a module in a live session:
```bash
activate mymodule.xzm
```

Module signing (ed25519):
```bash
openssl pkeyutl -sign -inkey signing.key -in mymodule.xzm -out mymodule.xzm.sig
```

---

## Repository Structure

```
.
├── 000-kernel/        ← Kernel build
├── 001-core/          ← Core Slackware packages
├── 002-gui/           ← GUI base (Wayland, graphics drivers)
├── 002-xtra/          ← Extra utilities (mpv, transmission)
├── 003-cosmic/        ← COSMIC desktop environment
├── 003-*/             ← Other desktop environments
├── 0050-multilib-lite/ ← 32-bit compatibility
├── 05-devel/          ← Development tools
├── 08-multilanguage/  ← Language packs
├── common/            ← Shared packages (fonts, LightDM)
├── iso/               ← Boot media structure & scripts
├── skycair-app-store/ ← App Store source
├── nvidia-driver/     ← NVIDIA driver module
└── builder-utils/     ← Build helper scripts
```

---

## Upstream

Based on [porteux/porteux](https://github.com/porteux/porteux) v2.6.
Upstream changes merge into `main`; SkyCAIR customizations live on `skycair-2.6-cosmic`.

```bash
# Sync upstream
git fetch upstream
git checkout main
git merge upstream/main

# Rebase SkyCAIR branch
git checkout skycair-2.6-cosmic
git rebase main
```

---

## Contributing & Security

- [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute
- [SECURITY.md](SECURITY.md) — report vulnerabilities
- [LICENSE](LICENSE) — source available license

---

*SkyCAIR OS — Care About AI Readiness — EOD (End of Days Edition)*
*© 2026 2XR, LLC | Evolve2Linux | 123Tech.net*
