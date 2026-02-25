#!/bin/bash
# SkyCAIR OS — Write Bootable USB + Persistence Partition
# Writes the SkyCAIR OS ISO to USB drives with optional SkyFILES persistence.
#
# Usage:
#   sudo bash write-to-usb.sh [ISO_PATH] [DEVICE]
#   sudo bash write-to-usb.sh                     # interactive mode
#   sudo bash write-to-usb.sh /tmp/skycair.iso /dev/sdb
#   sudo bash write-to-usb.sh /tmp/skycair.iso /dev/sdb,/dev/sdc  # both USB drives
#
# WARNING: THIS WILL COMPLETELY ERASE THE TARGET USB DRIVES.
# Only use on USB drives you don't mind wiping.
#
# 2XR, LLC | Evolve2Linux | 123Tech.net | SkyCAIR@123Tech.net

set -euo pipefail

SKYCAIR_LABEL="SkyCAIR"
SKYFILES_LABEL="SkyFILES"
SKYFILES_SIZE="16G"   # Persistent save partition size (adjust as needed)
ISO_DEFAULT="/tmp/skycair.iso"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()     { echo -e "${GREEN}[SkyCAIR]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
step()    { echo -e "\n${CYAN}▶ $*${NC}"; }
confirm() {
    read -rp "$(echo -e "${YELLOW}$* [y/N]: ${NC}")" ans
    [[ "${ans,,}" == "y" ]]
}

# ── Root check ────────────────────────────────────────────────────────────────
[ "$(id -u)" -ne 0 ] && error "Run as root: sudo bash $0"

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BLUE}"
cat << 'EOF'
   _____ _           ______    ___ ____     ____  _____
  / ____| |         / ____/   /   |_  _|   / __ \/ ____|
 | (___ | | ___   | |       / /| | | |   | |  | | (___
  \___ \| |/ / | | | |      / /_| | | |   | |  | |\___ \
  ____) |   <| |_| | |____ / ___  |_| |_  | |__| |____) |
 |_____/|_|\_\\__, |\____/_/   |_|_____|  \____/|_____/
               __/ |     Care About AI Readiness
              |___/      USB Writer — EODv9
EOF
echo -e "  2XR, LLC | Evolve2Linux | 123Tech.net${NC}"
echo ""

# ── ISO detection ─────────────────────────────────────────────────────────────
ISO_PATH="${1:-}"
if [ -z "$ISO_PATH" ]; then
    if [ -f "$ISO_DEFAULT" ]; then
        ISO_PATH="$ISO_DEFAULT"
        log "Found ISO: $ISO_PATH"
    else
        echo "Enter path to SkyCAIR OS ISO (or press Enter for $ISO_DEFAULT):"
        read -rp "ISO path: " ISO_PATH
        ISO_PATH="${ISO_PATH:-$ISO_DEFAULT}"
    fi
fi

[ -f "$ISO_PATH" ] || error "ISO not found: $ISO_PATH\n  Build the ISO first: cd iso/skycair && bash create-iso.sh"
ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
log "ISO: $ISO_PATH ($ISO_SIZE)"

# ── Device selection ──────────────────────────────────────────────────────────
DEVICES_RAW="${2:-}"
if [ -z "$DEVICES_RAW" ]; then
    step "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,MODEL,TRAN | grep -E "disk|usb" | grep -v "loop"
    echo ""
    echo "Target USBs (comma-separated, e.g. /dev/sdb,/dev/sdc):"
    echo "  Your USB drives: /dev/sdb (SanDisk 128GB), /dev/sdc (FlashDrive 128GB)"
    read -rp "Device(s): " DEVICES_RAW
fi

IFS=',' read -ra DEVICES <<< "$DEVICES_RAW"

# ── Verify devices ────────────────────────────────────────────────────────────
for DEV in "${DEVICES[@]}"; do
    DEV=$(echo "$DEV" | tr -d ' ')
    [ -b "$DEV" ] || error "$DEV is not a block device"
    TYPE=$(lsblk -no TRAN "$DEV" 2>/dev/null || echo "")
    SIZE=$(lsblk -no SIZE "$DEV" 2>/dev/null || echo "?")
    MODEL=$(lsblk -no MODEL "$DEV" 2>/dev/null || echo "")
    warn "Target: $DEV — $MODEL ($SIZE) [bus: $TYPE]"
done
echo ""

warn "═══════════════════════════════════════════════════════"
warn "  THIS WILL ERASE ALL DATA ON THE ABOVE DEVICE(S)!"
warn "  SkyCAIR OS ISO ($ISO_SIZE) will be written to:"
for DEV in "${DEVICES[@]}"; do echo "    $DEV"; done
warn "═══════════════════════════════════════════════════════"
echo ""

confirm "Are you ABSOLUTELY SURE you want to continue?" || { log "Aborted."; exit 0; }

# ── Write ISO to each device ──────────────────────────────────────────────────
write_iso() {
    local DEV="$1"
    step "Writing ISO to $DEV..."

    # Unmount any mounted partitions
    umount "${DEV}"* 2>/dev/null || true
    sync

    dd if="$ISO_PATH" of="$DEV" bs=4M status=progress oflag=sync conv=fsync
    sync

    log "ISO written to $DEV ✓"

    # ── Optional: Add SkyFILES persistence partition ──────────────────────────
    echo ""
    if confirm "Add SkyFILES persistence partition ($SKYFILES_SIZE ext4) to $DEV?"; then

        step "Creating SkyFILES persistence partition on $DEV..."

        # Find end of ISO partition (start after ISO data)
        ISO_SECTORS=$(du -sb "$ISO_PATH" | awk '{print $1}')
        ISO_SECTORS=$(( (ISO_SECTORS / 512) + 2048 ))  # Round up + alignment

        # Use parted to add a new partition after the ISO
        parted -s "$DEV" -- \
            mkpart primary ext4 "${ISO_SECTORS}s" "${SKYFILES_SIZE}" 2>/dev/null || {
            warn "Could not add persistence partition (ISO may use full drive layout)"
            warn "To add persistence manually: parted $DEV mkpart primary ext4 <start> 100%"
            return
        }

        # Format the new partition
        sleep 1
        NEW_PART=$(lsblk -ln -o NAME "$DEV" | tail -1)
        mkfs.ext4 -L "$SKYFILES_LABEL" "/dev/$NEW_PART"
        log "SkyFILES partition created: /dev/$NEW_PART (label: $SKYFILES_LABEL) ✓"
        log "To use: uncomment in skycair.cfg: changes=LABEL:SkyFILES:/skycair"
    fi
}

for DEV in "${DEVICES[@]}"; do
    DEV=$(echo "$DEV" | tr -d ' ')
    write_iso "$DEV"
done

# ── Verify ────────────────────────────────────────────────────────────────────
step "Verifying writes..."
for DEV in "${DEVICES[@]}"; do
    DEV=$(echo "$DEV" | tr -d ' ')
    WRITTEN=$(lsblk -ln -o LABEL "$DEV" 2>/dev/null | grep -c "$SKYCAIR_LABEL" || echo "0")
    if [ "$WRITTEN" -gt 0 ]; then
        log "$DEV — SkyCAIR label found ✓"
    else
        warn "$DEV — label not detected (may still be OK, try booting)"
    fi
done

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  SkyCAIR OS USB(s) ready for testing!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  Boot order on target machine:"
echo "    1. Enter BIOS/UEFI → set USB as first boot device"
echo "    2. Select boot entry:"
echo "       • 'SkyCAIR OS — Desktop (COSMIC)' → live desktop"
echo "       • 'Install to Hard Drive' → Calamares graphical installer"
echo "       • 'SkyCAIR OS — Server (Headless)' → server mode"
echo ""
echo "  USB drives written:"
for DEV in "${DEVICES[@]}"; do
    DEV=$(echo "$DEV" | tr -d ' ')
    echo "    $DEV → $(lsblk -no MODEL "$DEV" 2>/dev/null | head -1)"
done
echo ""
echo "  Build environment reminder:"
echo "    ISO must be built in a Slackware current environment."
echo "    See: iso/skycair/create-iso.sh"
echo ""
