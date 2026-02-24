#!/bin/bash
# SkyCAIR v2.6 -- Create Persistent Save Data File
# 2XR, LLC | Evolve2Linux | 123Tech.net
# SkyCAIR@123Tech.net | (608) 454-6660
#
# Creates a persistent .dat save file for use with the
# "Persistent 16GB" boot option (changes=/skycair/skycair-save.dat).
#
# Usage:
#   sh create-save-data.sh              # creates 16 GB (default)
#   sh create-save-data.sh 8            # creates 8 GB
#   sh create-save-data.sh 32           # creates 32 GB
#   sh create-save-data.sh 16 /mnt/sdb1 # creates 16 GB on /mnt/sdb1

DEFAULT_SIZE_GB=16
OUTPUT_DIR="/skycair"
FILENAME="skycair-save.dat"

# Parse arguments
SIZE_GB="${1:-$DEFAULT_SIZE_GB}"
if [ -n "$2" ]; then
    OUTPUT_DIR="$2/skycair"
fi

OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

# Validate size
if ! echo "$SIZE_GB" | grep -qE '^[0-9]+$' || [ "$SIZE_GB" -lt 1 ]; then
    echo "Error: size must be a positive number (in GB)."
    echo "Usage: sh $0 [size_gb] [output_dir]"
    exit 1
fi

SIZE_MB=$((SIZE_GB * 1024))

# Check for root
if [ "$(id -u)" != "0" ]; then
    echo "Error: this script must be run as root."
    echo "Run: su -c \"sh $0 $*\""
    exit 1
fi

# Check for required tools
for tool in dd mkfs.ext4; do
    if ! command -v $tool > /dev/null 2>&1; then
        echo "Error: '$tool' not found. Cannot create save file."
        exit 1
    fi
done

# Check if output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR" || { echo "Error: cannot create $OUTPUT_DIR"; exit 1; }
fi

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Warning: $OUTPUT_FILE already exists."
    printf "Overwrite it? [y/N] "
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

# Check available disk space
AVAIL_MB=$(df -m "$OUTPUT_DIR" 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "$AVAIL_MB" ] && [ "$AVAIL_MB" -lt "$SIZE_MB" ]; then
    echo "Error: not enough space. Need ${SIZE_GB} GB, have $((AVAIL_MB / 1024)) GB available."
    exit 1
fi

echo "================================================"
echo "  SkyCAIR -- Create Persistent Save Data File"
echo "================================================"
echo ""
echo "  Output:  $OUTPUT_FILE"
echo "  Size:    ${SIZE_GB} GB  (${SIZE_MB} MB)"
echo ""
echo "  This may take a few minutes..."
echo ""

# Create the raw file
dd if=/dev/zero of="$OUTPUT_FILE" bs=1M count="$SIZE_MB" status=progress 2>&1
if [ $? -ne 0 ]; then
    echo "Error: failed to create $OUTPUT_FILE"
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# Format as ext4
echo ""
echo "Formatting as ext4..."
mkfs.ext4 -F -L skycair-save "$OUTPUT_FILE"
if [ $? -ne 0 ]; then
    echo "Error: failed to format $OUTPUT_FILE"
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# Set ownership so guest can write to it
chown guest:users "$OUTPUT_FILE" 2>/dev/null

echo ""
echo "================================================"
echo "  Done! Save file created:"
echo "  $OUTPUT_FILE  (${SIZE_GB} GB)"
echo ""
echo "  To use it, select 'Persistent 16GB' at boot,"
echo "  or add this to /skycair/skycair.cfg:"
echo "    changes=$OUTPUT_FILE"
echo "================================================"
