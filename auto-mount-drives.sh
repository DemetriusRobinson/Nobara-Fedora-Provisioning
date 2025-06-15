#!/bin/bash

MOUNT_BASE="/mnt"

echo "[INFO] Scanning available mountable drives..."
echo

# Collect potential mountable drives
DRIVES=()
lsblk -o NAME,UUID,LABEL,FSTYPE -nr | while read -r NAME UUID LABEL FSTYPE; do
    [[ -z "$UUID" || -z "$FSTYPE" ]] && continue
    echo "Device: /dev/$NAME | UUID=$UUID | LABEL=${LABEL:-<none>} | FSTYPE=$FSTYPE"
    DRIVES+=("$NAME")
done

echo
read -p "[INPUT] Enter device names to exclude (space-separated): " -a EXCLUDE

echo "[INFO] Backing up /etc/fstab to /etc/fstab.bak..."
sudo cp /etc/fstab /etc/fstab.bak

echo "[INFO] Processing drives..."

# Iterate again for mounting
lsblk -o NAME,UUID,LABEL,FSTYPE -nr | while read -r NAME UUID LABEL FSTYPE; do
    DEV="/dev/$NAME"

    [[ -z "$UUID" || -z "$FSTYPE" ]] && continue

    # Skip excluded devices
    for EXCL in "${EXCLUDE[@]}"; do
        [[ "$NAME" == "$EXCL" ]] && continue 2
    done

    # Sanitize label or fallback to device name
    LABEL_SANITIZED=$(echo "$LABEL" | sed 's/ /_/g')
    [[ -z "$LABEL_SANITIZED" ]] && LABEL_SANITIZED="$NAME"
    MOUNT_POINT="$MOUNT_BASE/$LABEL_SANITIZED"

    # Check if UUID is already in fstab
    if grep -q "$UUID" /etc/fstab; then
        echo "[SKIP] $DEV already in fstab."
        continue
    fi

    echo "[ADD] $DEV -> $MOUNT_POINT"

    # Create the mount point
    sudo mkdir -p "$MOUNT_POINT"

    # Select filesystem-specific options
    case "$FSTYPE" in
        ext4|xfs|btrfs)
            OPTIONS="defaults,rw,exec"
            ;;
        ntfs)
            OPTIONS="defaults,ntfs-3g"
            ;;
        vfat|exfat)
            OPTIONS="defaults,uid=$(id -u),gid=$(id -g),dmask=0022,fmask=0133"
            ;;
        *)
            OPTIONS="defaults"
            ;;
    esac

    # Write to fstab and mount
    echo "UUID=$UUID $MOUNT_POINT $FSTYPE $OPTIONS 0 2" | sudo tee -a /etc/fstab
    sudo mount "$MOUNT_POINT"
done

echo "[DONE] Drives mounted and /etc/fstab updated."
