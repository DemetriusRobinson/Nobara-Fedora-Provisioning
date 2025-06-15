#!/bin/bash

# === CONFIGURATION ===
TKG_DIR=~/Applications/BuildProjects/linux-tkg
TKG_REPO="https://github.com/Frogging-Family/linux-tkg.git"

# === STEP 1: Check current kernel ===
CURRENT_KERNEL=$(uname -r)
if [[ "$CURRENT_KERNEL" != *"tkg"* ]]; then
    echo "[INFO] Not running a TKG kernel. Proceeding to clean old TKG kernel files."

    # Remove old TKG kernel entries from /boot
    sudo rm -v /boot/*tkg*

    # Remove old TKG modules
    for dir in /lib/modules/*tkg*/; do
        [[ -d "$dir" ]] && sudo rm -rfv "$dir"
    done
else
    echo "[INFO] Currently running TKG kernel: $CURRENT_KERNEL — skipping deletion."
fi

# === STEP 2: Remove existing linux-tkg directory if present ===
if [ -d "$TKG_DIR" ]; then
    echo "[INFO] Removing old TKG source directory at $TKG_DIR"
    rm -rf "$TKG_DIR"
fi

# === STEP 3: Clone TKG source repo ===
echo "[INFO] Cloning TKG kernel from GitHub..."
git clone --depth=1 "$TKG_REPO" "$TKG_DIR"

# === STEP 4: Run the install script ===
cd "$TKG_DIR" || exit 1

echo "[INFO] Creating logs folder to prevent move error..."
mkdir -p logs

echo "[INFO] Starting TKG build and install process..."
chmod +x install.sh
sudo dnf install util-linux
sudo dnf install util-linux-script
./install.sh install

# === STEP 5: Set default kernel via grubby ===
echo "[INFO] Locating latest TKG kernel image..."
TKG_KERNEL_PATH=$(ls -1t /boot/vmlinuz-*tkg* 2>/dev/null | head -n1)

if [[ -f "$TKG_KERNEL_PATH" ]]; then
    echo "[INFO] Setting $TKG_KERNEL_PATH as default using grubby..."
    sudo grubby --set-default="$TKG_KERNEL_PATH"
    echo "[SUCCESS] TKG kernel set as default boot entry."
else
    echo "[ERROR] No TKG kernel image found in /boot! Build might have failed."
    exit 1
fi

echo "[DONE] Reboot to use your newly built TKG kernel."
