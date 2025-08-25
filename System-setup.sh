#!/bin/bash

echo "📦 Updating system..."
sudo dnf update -y

echo "📦 Installing fastfetch..."
sudo dnf install -y fastfetch

echo "🧰 Installing essential packages..."
sudo dnf install -y \
  fish konsole kate eog celluloid \
  firefox torbrowser-launcher \
  #gnome-tweaks gnome-extensions-app \
  dconf-editor flatpak curl


# echo "🧠 Restoring GNOME environment..."
# if [[ -f ~/Downloads/gnome-dconf-backup.txt ]]; then
#   dconf load / < ~/Downloads/gnome-dconf-backup.txt
#   echo "✅ GNOME settings restored."
# else
#   echo "⚠️ gnome-dconf-backup.txt not found in ~/Downloads. Skipping restore."
# fi

echo "🐟 Restoring Fish shell configuration..."

FISH_DIR="$HOME/.config/fish"
BACKUP_DIR="."

# Restore main config
if [[ -f "$BACKUP_DIR/config.fish.backup" ]]; then
    mkdir -p "$FISH_DIR"
    cp "$BACKUP_DIR/config.fish.backup" "$FISH_DIR/config.fish"
    echo "✅ config.fish restored."
else
    echo "⚠️ config.fish.backup not found. Skipping main config restore."
fi

# Restore functions
if [[ -d "$BACKUP_DIR/fish-functions.backup" ]]; then
    mkdir -p "$FISH_DIR/functions"
    cp -r "$BACKUP_DIR/fish-functions.backup/"* "$FISH_DIR/functions/"
    echo "✅ Fish functions restored."
fi

# Restore completions
if [[ -d "$BACKUP_DIR/fish-completions.backup" ]]; then
    mkdir -p "$FISH_DIR/completions"
    cp -r "$BACKUP_DIR/fish-completions.backup/"* "$FISH_DIR/completions/"
    echo "✅ Fish completions restored."
fi

# Set fish as the default shell
if command -v fish &> /dev/null; then
    echo "🔄 Setting fish as the default shell..."
    chsh -s "$(which fish)"
    echo "✅ Fish shell set as default. Please log out and back in for changes to take effect."
else
    echo "❌ Fish shell is not installed or not in PATH."
fi

echo "🧰 Starting full system setup on Nobara/Fedora GNOME..."

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_script() {
    local script="$1"
    if [[ -x "$script" ]]; then
        echo "▶ Running: $script"
        "$script"
    else
        echo "⚠️ Skipping $script (not found or not executable)"
    fi
}

# Mount drives first
run_script "$BASE_DIR/auto-mount-drives.sh"

# Install Vaultsoftware
run_script "$BASE_DIR/install-vault-with-nas.sh"

# Install general
run_script "$BASE_DIR/install-software.sh"

# Install web server stack
run_script "$BASE_DIR/install-apache-software.sh"

# Install Java JDK
run_script "$BASE_DIR/install-java-jdk.sh"

# Install QEMU/KVM for virtualization
run_script "$BASE_DIR/install-qemu-kvm.sh"

# Install Stability Matrix AI AppImage
run_script "$BASE_DIR/install-stabilitymatrix.sh"

# Install Twitch downloader
run_script "$BASE_DIR/install-twitch-downloader.sh"

# Install Flathub Apps
run_script "$BASE_DIR/install-flathub-apps.sh"

# Sort GNOME apps into folders
#run_script "$BASE_DIR/sort-gnome-apps.sh"

echo "✅ System setup complete!"
echo "⚠️ Restart your system"
