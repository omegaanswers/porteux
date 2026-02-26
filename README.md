# SkyCAIR OS

> **Care About AI Readiness**
> *A TimeCapsule for Every Human — Home or Business*

[![Validate Build Scripts](https://github.com/omegaanswers/skycair-os/actions/workflows/validate.yml/badge.svg?branch=skycair-2.6-cosmic)](https://github.com/omegaanswers/skycair-os/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Source%20Available-blue)](LICENSE)
[![Version](https://img.shields.io/badge/version-v2.6.0-brightgreen)](https://github.com/omegaanswers/skycair-os/releases/tag/v2.6.0-skycair)
[![Platform](https://img.shields.io/badge/platform-x86__64%20%7C%20arm64-lightgrey)](#)
[![Desktop](https://img.shields.io/badge/desktop-COSMIC-purple)](https://github.com/pop-os/cosmic-epoch)
[![SkyNetSSL](https://img.shields.io/badge/SkyNetSSL-Safe%20Secure%20Linux-green)](https://github.com/omegaanswers/SkySTACK/blob/main/docs/skynetssl/README.md)
[![Slackware](https://img.shields.io/badge/foundation-Slackware%201993-orange)](#built-on-33-years-of-slackware)

**2XR, LLC | Evolve2Linux | 123Tech.net**

| | |
|---|---|
| Website | https://123tech.net |
| Contact | SkyCAIR@123Tech.net |
| Phone | (608) 454-6660 |
| Address | 855 Community Dr, Sauk City, WI 53583 |
| YouTube | [Evolve2Linux](https://youtube.com/@Evolve2Linux) · [OmegaAnswers](https://youtube.com/@OmegaAnswers) |
| Social | Facebook/Instagram: Evolve2Linux · X/TikTok: OmegaAnswers |
| Branch | [`skycair-2.6-cosmic`](https://github.com/omegaanswers/skycair-os/tree/skycair-2.6-cosmic) |
| Stack Repo | [omegaanswers/SkySTACK](https://github.com/omegaanswers/SkySTACK) |

---

## What Is SkyCAIR OS

**SkyCAIR OS** is the operating system layer of the SkySTACK platform — a high-performance,
modular, **Slackware-based Linux distribution** purpose-built for AI-ready infrastructure:
from IoT edge devices and Raspberry Pi 5 clusters to enterprise data centers and off-grid homesteads.

SkyCAIR OS is a **complete technology platform** — not just an OS:

| What It Includes | Description |
|-----------------|-------------|
| **SkyCAIR OS** | Fast portable OS — boots in 3–5s from USB, full desktop from RAM |
| **SkyVAULT-OffGrid** | Personal NAS — Samba, Syncthing, Filebrowser (arm64 + x86_64) |
| **SkyVAULT-Business** | Enterprise NAS/SAN — OpenZFS, JBOD, RAID, Samba, NFS, iSCSI |
| **SkySHIELD-ATF** | Security — firewall, Suricata IDS/IPS, WireGuard VPN, SkyBLOCKER DNS |
| **SkyCUBES** | Virtualization — GNOME Boxes + libvirt, `skycube` CLI, SkyLightAI Windows 10 VM |
| **SkyOMEGAi** | Private offline AI — Ollama LLM, Open WebUI, Kiwix knowledge base |
| **SkyK12Ai** | Private Education AI — Faith & Knowledge United — K-12, Seminary, Homeschool |
| **SkyDASH** | Mission Control home page — all portals, any device, port 8080 |
| **SkyNetSSL** | Safe Secure Linux certification — trust mark for all shipped software |
| **SkyCAIR App Store** | 53+ applications, SkyNetSSL-reviewed, AppImage + .xzm modules |

---

## Built on 33 Years of Slackware

SkyCAIR OS is a fork of **PorteuX**, which is built on **Slackware Linux** — created by
**Patrick Volkerding in 1993**. Slackware is the **oldest continuously maintained Linux
distribution in the world** — outlasting every trend, every corporate acquisition, every
"next generation" Linux experiment for over three decades.

**Why this matters:**

- **Stability over trends** — Slackware's architecture hasn't changed in 33 years
- **Minimal attack surface** — only what you explicitly install is present
- **POSIX compliance** — software written decades ago still runs today
- **Auditable** — plain shell init scripts, no hidden complexity
- **Community** — the same community, the same documentation, for 33 years

> SkyCAIR OS boots in **3–5 seconds** from a USB drive — faster than Ubuntu boots
> from an NVMe SSD. This is what Slackware's minimal philosophy delivers.

---

## SkyNetSSL — Safe Secure Linux

**SkyNetSSL™** is the SkyCAIR trust and certification program — every application and
module shipped in SkyCAIR OS has been reviewed for security, privacy, and integrity.

```
╔══════════════════════════════════════════╗
║  ✅  SkyNetSSL — Safe Secure Linux       ║
║  Certified by 2XR, LLC | 123Tech.net    ║
║  Module integrity · Privacy reviewed    ║
║  AI safe · Network audited              ║
╚══════════════════════════════════════════╝
```

**SkyNetSSL criteria for every approved application:**
- ed25519-signed .xzm modules verified at boot
- No unauthorized telemetry or data exfiltration
- Build reproducibility confirmed
- All network connections documented
- AI components: local model weights never sent externally

The **SkyNetSSL name and certification mark** are protected trademarks of 2XR, LLC.
See [omegaanswers/SkySTACK — SKYNETSSL-LICENSE.md](https://github.com/omegaanswers/SkySTACK/blob/main/SKYNETSSL-LICENSE.md).

---

## Features

- **Blazing fast**: squashfs modules load into RAM at boot — full system in 3–5 seconds
- **Modular**: .xzm squashfs modules stack via overlayfs — add/remove without reinstalling
- **Portable**: runs live from USB, SD, or NVMe — no installation required
- **Immutable option**: boot read-only; optional SkyFILES persistent save layer
- **64-bit only**: x86_64 and arm64 — Raspberry Pi 5, Rockchip RK3588, modern x86 PCs
- **AI-ready**: private Ollama LLM inference, RKNN NPU for Rockchip boards
- **Virtualization**: SkyCUBES (GNOME Boxes + libvirt/KVM) — VMs with `skycube` CLI
- **Desktop**: COSMIC (primary) — written in Rust, Wayland-native, memory-safe
- **Mission Control**: SkyDASH home page — all services on one page, any device
- **Offline-first**: works completely without internet — the SkyCAIR TimeCapsule
- **SkyNetSSL**: every shipped app is security-reviewed and privacy-audited

---

## Quick Start

1. Download the ISO from [123tech.net](https://123tech.net)
2. Flash to USB using the SkyCAIR installer:
   - Linux: `skycair-installer-for-linux.run`
   - Windows: `skycair-installer-for-windows.exe`
3. Boot — select from the GRUB menu
4. Log in as `guest` / `guest`
5. Open the **SkyCAIR App Store** for browsers, tools, AI, and drivers
6. After SkySTACK services start, open **SkyDASH** at `http://home.skycair.local:8080`

> **Avoid Rufus/Etcher** — they set media read-only, which disables persistence.
> Full guide: [iso/boot/docs/install.txt](iso/boot/docs/install.txt)

### Default Credentials

```
username: guest    password: guest
username: root     password: toor
```

**Change root password immediately** before enabling network services.

---

## SkyDASH — Mission Control

The **home page for your private cloud** — access every SkySTACK portal from any device
on your LAN — phone, tablet, smart TV, laptop — all in one place.

```
Access:  http://<host>:8080
         http://home.skycair.local:8080  (with SkyBLOCKER DNS)
```

Features: live service health (Ping), SkyNetSSL trust badges, SkyCUBES VDI launcher,
SkyCAIR brand theme, mobile-first layout, hot-reload config.

---

## SkyVAULT — Storage Tiers

SkyVAULT is the integrated NAS/SAN platform, activated by SkyMod module.

### SkyVAULT-OffGrid (Personal / Off-Grid)
*~100MB RAM · Solar-friendly · Raspberry Pi 5 ready*

```
Web File Manager:  http://localhost:8082  (Filebrowser)
Syncthing UI:      http://localhost:8384  (P2P device sync)
Samba share:       \\<hostname>\SkyFILES  (Windows compatible)
NFS:               Available for Linux/Unix clients
```

Activate via App Store or: `skyair module activate skymod-skyfiles.xzm`

### SkyVAULT-Business (Enterprise)
*OpenZFS · JBOD (mergerfs) · mdadm RAID · Samba · NFS · iSCSI · SkyControl*

```
SkyControl UI:  http://localhost:9090  (System + storage management)
Samba:          \\<hostname>\<share>
NFS / iSCSI:    Available for Linux/enterprise clients
```

Activate via: `skyair module activate skymod-070-skyvault.xzm`

---

## SkySHIELD-ATF — Security

SkySHIELD ATF (Attack Threat Foundation) integrates into SkyCAIR OS:

| Tool | Purpose |
|------|---------|
| nftables | Closed-loop stateful packet filtering (DROP external, ACCEPT RFC1918 LAN) |
| Suricata | IDS/IPS — network intrusion detection + prevention |
| WireGuard | Zero-config peer-to-peer encrypted VPN |
| dnscrypt-proxy | DoH encrypted DNS (Cloudflare 1.1.1.1 + Quad9 9.9.9.9 — no Google DNS) |
| **SkyBLOCKER** | Pi-hole DNS ad/tracker/malware blocking (network-wide, any device) |
| Nmap, Nikto, testssl.sh | Network and web security scanning |
| Lynis | NIST/DISA STIG system hardening audit |
| rkhunter | Rootkit detection |

**SkyBLOCKER** provides network-wide DNS-level ad and tracker blocking:
- Curated 5-tier blocklist: Steven Black, OISD Big, Hagezi Pro, URLhaus, Quad9
- DNSSEC validated, no Google DNS
- Web admin: `http://localhost:8053/admin`  |  DNS server: `<host>:5300`
- `*.skycair.local` — all portals accessible by hostname from any LAN device

Activate: `skyair module activate skymod-skyshield.xzm`

---

## SkyCUBES — Virtualization

GNOME Boxes is already in SkyCAIR OS base. SkyCUBES adds libvirt configuration,
storage pool setup (`/skycair/cubes/`), and the `skycube` CLI.

```bash
skycube list                             # show all VMs
skycube create --from skycair.iso --name myvm --cpu 4 --ram 4096 --disk 50
skycube start myvm                       # start VM
skycube console myvm                     # open GNOME Boxes to this VM
skycube snapshot myvm                    # instant snapshot
skycube stop myvm                        # graceful shutdown
```

**SkyLightAI** — Windows 10 Atlas SkyCUBE:
- Privacy-respecting Windows 10 (Atlas debloated) as a ready-to-use QCOW2
- Steam, Firefox + DuckDuckGo, Chocolatey package manager pre-installed
- VDI for up to 30 concurrent users via SPICE + RDP
- Pre-loaded with all SkySTACK portal bookmarks (SkyDASH first)
- Distributed via SkyRepo (`packages.123tech.net`)

---

## SkyOMEGAi — Private Offline AI

Everything runs **completely offline** after initial model download.

```bash
# After module activation:
ollama pull phi3:mini            # 2.3GB — general assistant, CPU capable
ollama run phi3:mini             # Chat from terminal
# Web interface:    http://localhost:3001 (Open WebUI — SkyOMEGAi)
# Knowledge base:  http://localhost:8888 (Kiwix — Wikipedia, Bible, survival)
# Image gen:       http://localhost:7860 (ComfyUI — Stable Diffusion / FLUX)
```

**Rockchip RK3588 NPU**: add `rknn=enable` to `skycair.cfg` for hardware-accelerated inference.

---

## SkyK12Ai — Faith & Knowledge United

**Private Education Learning System** for homeschool families, private religious schools,
Sunday school, seminary, and faith-based universities.

```
Secular: Math, Science, History, Language, Arts (K-12 + University)
Faith:   Scripture, theology, religious history, values formation
AI tutor: kind, patient, values-aligned, never contradicts the family's faith
Privacy: FERPA + COPPA — all data stays on-device, 100% offline
Discount: 20% for schools, churches, libraries, non-profits
```

Activate: `skyair module activate skymod-065-skyk12ai.xzm`

---

## SkyLEGO parameters (skycair.cfg)

Configure SkyCAIR OS at boot via [`iso/skycair/skycair.cfg`](iso/skycair/skycair.cfg):

```ini
# Persistence
changes=LABEL:SkyFILES:/skycair    # Use dedicated SkyFILES partition

# System
timezone=America/Chicago
kmap=us

# DNS
dns=cloudflare    # 1.1.1.1/1.0.0.1 — privacy-first
dns=quad9         # 9.9.9.9 — malware-blocking

# AI
ai=local          # Start Ollama at boot
ai=webui          # + Open WebUI at http://localhost:3001
ai=knowledge      # + Kiwix knowledge base at http://localhost:8888
ai=full           # Full AI stack (16GB+ RAM recommended)

# Hardware
rknn=enable       # Rockchip RK3588 NPU acceleration
nvmeswap=enable   # PCIe 5.0 NVMe swap tier

# Performance
copy2ram          # Load all modules to RAM (2GB+ RAM required)
zram=33%          # Compressed RAM swap
```

---

## Desktop Environment

| Desktop | Status | Description |
|---------|--------|-------------|
| **COSMIC** | ✅ Primary | Written in Rust, Wayland-native, memory-safe, SkyNetSSL Approved |
| Cinnamon | Available | Windows-like traditional layout |
| GNOME | Available | Modern GNOME Shell |
| KDE | Available | Feature-rich, highly customizable |
| LXDE | Available | Ultra-lightweight (older hardware, low RAM) |
| LXQt | Available | Qt-based lightweight |
| MATE | Available | Classic GNOME 2 |
| Xfce | Available | Fast, lightweight GTK |

**EODv10**: Fedora 43 Atomic + COSMIC bootc — one OS, one desktop, immutable infrastructure.

---

## SkyCAIR App Store

53+ applications, all **SkyNetSSL-reviewed**, available in the App Store:

| Category | Applications |
|----------|-------------|
| **Browsers** | Brave, LibreWolf, Firefox, Chromium, Vivaldi, Tor Browser |
| **Productivity** | LibreOffice, OnlyOffice, NotepadNext |
| **Media & Streaming** | OBS Studio, VLC, Kdenlive, HandBrake, Audacity, Streamlink |
| **Graphics & 3D** | GIMP, Inkscape, Blender |
| **Gaming** | Steam, Proton-GE, MangoHud, PCSX2, CEMU |
| **AI & Private Computing** | Ollama, Open WebUI, llama.cpp |
| **Engineering & CAD** | FreeCAD, KiCad EDA, OpenSCAD, PrusaSlicer |
| **GPU & Hardware** | NVIDIA Driver, AMD ROCm, Vulkan Tools |
| **Development** | VSCodium, NeoVim, Deno, Wine |
| **Security** | KeePassXC, yt-dlp |

Install applications:
```bash
# Via App Store GUI (recommended)
# Via command line:
sh /opt/skycair-scripts/skycair-app-store/applications/obs-studio.sh --activate-module
```

---

## Installing Applications

**App Store** (recommended): Launch the SkyCAIR App Store for browsers, tools, drivers, and AI.

**AppImage**: Drop and run — no installation needed.

**Slackware package → XZM module**:
```bash
getpkg -m <packageName>
activate <moduleName>
# Move to /skycair/modules/ for auto-load on boot
```

**Flatpak**: Available by default via the Flatpak runtime.

---

## Building

Requires a **Slackware 64-bit current** or **SkyCAIR live** environment. Build as root:

```bash
# Build modules in order:
sh 000-kernel/createModule.sh
sh 001-core/createModule.sh
sh 002-gui/createModule.sh
sh 002-xtra/createModule.sh
sh 003-cosmic/createModule.sh        # COSMIC desktop
sh 05-devel/createModule.sh          # optional
sh 08-multilanguage/createModule.sh  # optional
sh 0050-multilib-lite/createModule.sh # optional
```

Build an ISO:
```bash
SKYCAIRVERSION=2.6.0 SKYCAIRBUILD=1 sh iso/skycair/create-iso.sh /tmp/skycair.iso
```

---

## Repository Structure

```
.
├── 000-kernel/           ← Kernel build
├── 001-core/             ← Core Slackware packages
├── 002-gui/              ← GUI base (Wayland, graphics drivers)
├── 002-xtra/             ← Extra utilities (mpv, transmission)
├── 003-cosmic/           ← COSMIC desktop environment
├── 003-skycube/          ← SkyCUBES (libvirt + skycube CLI)
├── 003-*/                ← Other desktop environments
├── 0050-multilib-lite/   ← 32-bit compatibility
├── 05-devel/             ← Development tools
├── 08-multilanguage/     ← Language packs
├── common/               ← Shared packages (fonts, LightDM)
├── iso/
│   ├── skycair/
│   │   └── skycair.cfg   ← Boot skylego (AI, DNS, SkyTimeMachine, RKNN)
│   └── boot/docs/        ← install.txt, skylego.txt
├── skycair-app-store/
│   ├── applications/     ← 53+ installer scripts (SkyNetSSL reviewed)
│   └── skycair-app-store-db.json
├── nvidia-driver/        ← NVIDIA driver module
└── builder-utils/        ← Build helper scripts (setflags.sh → SkyRepo first)
```

---

## Module System

SkyCAIR uses `.xzm` squashfs modules stacked via overlayfs at boot:

```
/skycair/base/      ← core modules (auto-loaded)
/skycair/modules/   ← optional modules (auto-loaded)
/skycair/optional/  ← available but not auto-loaded
/skycair/cubes/     ← SkyCUBES VM storage (libvirt default pool)
```

Activate a module in a live session:
```bash
activate mymodule.xzm
```

Module signing (ed25519 — required for SkyNetSSL certification):
```bash
openssl pkeyutl -sign -inkey signing.key -in mymodule.xzm -out mymodule.xzm.sig
```

---

## Performance

| Metric | SkyCAIR OS | Ubuntu 24.04 | Fedora 41 | Windows 11 |
|--------|-----------|-------------|-----------|-----------|
| Boot (USB → desktop) | **3–5s** | 25–40s | 20–35s | N/A |
| Boot (NVMe → desktop) | **1–2s** | 8–15s | 6–12s | 20–45s |
| Idle RAM (desktop) | **~350MB** | ~1.2GB | ~1.1GB | ~3.5GB |
| Runs fully from USB | ✅ | Partial | ❌ | ❌ |
| Offline (no internet) | ✅ Full | Partial | Partial | Degraded |

*Best performance: NVMe/SSD or **Copy To RAM** at boot (`copy2ram` SkyLEGO parameter, requires 2GB+ RAM).*

---

## Upstream

Based on [porteux/porteux](https://github.com/porteux/porteux) v2.6,
which is based on [Slackware Linux](https://www.slackware.com) (Patrick Volkerding, 1993).

```bash
# Sync upstream
git fetch upstream
git checkout main
git merge upstream/main

# Rebase SkyCAIR branch
git checkout skycair-2.6-cosmic
git rebase main

# Push to SkyCAIR OS fork
git push fork skycair-2.6-cosmic
```

---

## Contributing & Security

- [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute
- [SECURITY.md](SECURITY.md) — report vulnerabilities to SkyCAIR@123Tech.net
- [LICENSE](LICENSE) — Source Available license (personal/educational use free)

All contributions must follow SkyNetSSL principles: no telemetry, no unauthorized
network calls, source-verifiable builds.

---

## Acknowledgements

SkyCAIR OS is built on the work of extraordinary open-source communities.
Full credits: [omegaanswers/SkySTACK — ACKNOWLEDGEMENTS.md](https://github.com/omegaanswers/SkySTACK/blob/main/ACKNOWLEDGEMENTS.md)

**Key foundations**: Slackware (P. Volkerding, 1993) · PorteuX · Porteus · Linux kernel ·
COSMIC Desktop (System76) · GNOME Boxes · libvirt · Samba · Syncthing · Filebrowser ·
Ollama · Open WebUI · Kiwix · Wikimedia Foundation · Pi-hole · Homer · OBS Studio ·
Blender · KiCad · FreeCAD · and many more.

---

*SkyCAIR OS v2.6.0 — Care About AI Readiness — EOD (End of Days Edition)*
*A TimeCapsule for Every Human — Home or Business*
*© 2026 2XR, LLC | Evolve2Linux | 123Tech.net*
*Built on 33 years of Slackware Linux. Secured by SkyNetSSL.*
