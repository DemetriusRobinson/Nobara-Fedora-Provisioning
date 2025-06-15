#!/bin/bash

# === CONFIGURATION ===
ZEN_DIR=~/Applications/BuildProjects/zen-kernel
ZEN_REPO="https://github.com/zen-kernel/zen-kernel.git"

# === STEP 1: Check current kernel ===
CURRENT_KERNEL=$(uname -r)
if [[ "$CURRENT_KERNEL" != *"zen"* ]]; then
    echo "[INFO] Not running Zen kernel. Proceeding to clean old Zen kernel files."

    # Remove old Zen kernel images from /boot
    sudo rm -v /boot/*zen*

    # Remove old Zen kernel modules
    for dir in /lib/modules/*zen*/; do
        [[ -d "$dir" ]] && sudo rm -rfv "$dir"
    done
else
    echo "[INFO] Currently running Zen kernel: $CURRENT_KERNEL — keeping existing boot and module files."
fi

# === STEP 2: Remove old Zen kernel source if it exists ===
if [ -d "$ZEN_DIR" ]; then
    echo "[INFO] Removing existing Zen kernel source directory at $ZEN_DIR"
    rm -rf "$ZEN_DIR"
fi

# === STEP 3: Clone the Zen kernel repository ===
echo "[INFO] Cloning Zen kernel from GitHub..."
git clone --depth=1 "$ZEN_REPO" "$ZEN_DIR"

# === STEP 4: Compile the Zen kernel ===
cd "$ZEN_DIR" || exit 1

echo "[INFO] Preparing kernel config..."
make mrproper
cp /boot/config-"$(uname -r)" .config
yes "" | make oldconfig

echo "[INFO] Compiling the kernel — this may take some time..."
make -j"$(nproc)"
sudo make modules_install
sudo make install

# === STEP 5: Use grubby to manage default boot entry ===
echo "[INFO] Locating Zen kernel for grubby..."
ZEN_KERNEL_PATH=$(ls -1t /boot/vmlinuz-*zen* | head -n1)

if [[ -f "$ZEN_KERNEL_PATH" ]]; then
    echo "[INFO] Setting $ZEN_KERNEL_PATH as default using grubby..."
    sudo grubby --set-default="$ZEN_KERNEL_PATH"
    echo "[SUCCESS] Zen kernel set as default boot entry."
else
    echo "[ERROR] Could not find Zen kernel image in /boot!"
    exit 1
fi

echo "[DONE] Reboot when ready to boot into the new Zen kernel."
