## SkyCAIR Lite

SkyCAIR Lite is a high-performance, modular, minimalist Linux distribution built on Slackware by **2XR, LLC | Evolve2Linux | 123Tech.net**.

- Contact: SkyCAIR@123Tech.net | (608) 454-6660
- Address: 855 Community Dr, Sauk City, WI 53583
- Product Page: https://123tech.net

SkyCAIR customizations: https://github.com/omegaanswers/porteux/tree/skycair-2.6-cosmic

---

## About

SkyCAIR Lite is a high-performance, modular, Slackware-based Linux distribution. Its main goal is to be super fast, small, portable, modular, and immutable (if the user wants so).

It's already pre-configured for basic usage, including lightweight applications for each of the 8 desktop environments available. No browser is included by default, but the SkyCAIR App Store provides the most popular browsers, Steam, VirtualBox, NVIDIA drivers, Wine, office suite, multilib (32-bit compatibility), messengers, emulators, and more.

Out of the box, SkyCAIR Lite can open basically any multimedia file. Hardware acceleration is enabled by default for machines with Intel, AMD, or NVIDIA cards (for NVIDIA cards, download the driver from the App Store).

---

## How To Use

SkyCAIR Lite is based on Slackware 64-bit current/rolling (bleeding edge). ISOs are available in 8 spins:

- Cinnamon
- COSMIC
- GNOME
- KDE
- LXDE
- LXQt
- MATE
- Xfce

SkyCAIR Lite is a modular system — no traditional installer required. Copy the ISO content to your media storage and run from the `boot` folder either `skycair-installer-for-linux.run` or `skycair-installer-for-windows.exe` to make the unit bootable. Avoid ISO installer applications like Rufus or Etcher as they set the media to read-only by default. More details: [/boot/docs/install.txt](iso/boot/docs/install.txt).

To use SkyCAIR Lite in a language other than English, download the multilanguage package and use the Language Switcher application.

---

## Installing New Applications

To install applications not in the App Store or Slackware repository, AppImage format is recommended. Flatpak is available by default for accessing Flatpak repositories.

To download a Slackware package and convert it to an XZM module:
```
getpkg -m [packageName]
```
After the XZM module is created, double-click or run `activate [moduleName]` to activate it. Move the module to `/skycair/modules` to auto-load on boot.

---

## Default Username and Password

```
username: guest    password: guest
username: root     password: toor
```

---

## Performance

SkyCAIR Lite is lightweight and snappy. Although it runs on older machines (SSE4.2 required), high-end machines will experience full performance potential. ISOs are small and RAM consumption is highly optimized.

For best performance, install on SSD/NVMe rather than USB flash, or select **Copy To RAM** at boot.

---

## Building

SkyCAIR Lite can be built in a live session of Slackware 64-bit or SkyCAIR Lite 64-bit. Run `createModule.sh` as root in this order:

1. 000-kernel
2. 001-core
3. 002-gui
4. 002-xtra
5. 003-\<desktopenv\> (e.g. `003-cosmic`)
6. (optional) 05-devel
7. (optional) 08-multilanguage
8. (optional) 0050-multilib-lite

All modules will be output to `/tmp/skycair-builder-[version]/`.

---

## Upstream

This project is a customization branch of [porteux/porteux](https://github.com/porteux/porteux).
Upstream is maintained independently — pull upstream updates into `main`, then rebase the `skycair-2.6-cosmic` branch as needed.
