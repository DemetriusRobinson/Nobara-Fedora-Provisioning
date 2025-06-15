#!/bin/bash

set -e

INSTALL_DIR="/opt/Twitch-Downloader"
FISH_CONFIG="$HOME/.config/fish/config.fish"
TEMP_DIR="/tmp/twitchdl-extract"

echo "📁 Creating install directory at $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER:$USER" "$INSTALL_DIR"

cd /tmp
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

echo "🌐 Fetching latest Twitch Downloader release..."
RELEASE_URL=$(curl -s https://api.github.com/repos/jybp/twitch-downloader/releases/latest | \
  grep "browser_download_url" | grep "twitch" | grep "linux" | grep ".tar.gz" | cut -d '"' -f 4 | head -n 1)

if [[ -z "$RELEASE_URL" ]]; then
  echo "❌ Could not retrieve the Twitch Downloader release tarball URL."
  exit 1
fi

FILENAME=$(basename "$RELEASE_URL")

echo "📦 Downloading $FILENAME..."
curl -L "$RELEASE_URL" -o "$FILENAME"

echo "📂 Extracting to $TEMP_DIR..."
tar -xzf "$FILENAME" -C "$TEMP_DIR"

echo "🔍 Searching for twitchdl binary..."
FOUND_BIN=$(find "$TEMP_DIR" -type f -name "twitchdl" -executable | head -n 1)

if [[ -z "$FOUND_BIN" ]]; then
  echo "❌ twitchdl binary not found or not executable."
  exit 1
fi

echo "🚚 Moving twitchdl to $INSTALL_DIR..."
mv "$FOUND_BIN" "$INSTALL_DIR/twitchdl"
chmod +x "$INSTALL_DIR/twitchdl"

echo "🐟 Updating Fish environment for twitchdl..."
if ! grep -q "Twitch Downloader" "$FISH_CONFIG"; then
  echo -e "\n# Twitch Downloader" >> "$FISH_CONFIG"
  echo "set -x TWITCHDL $INSTALL_DIR/twitchdl" >> "$FISH_CONFIG"
  echo "set -x PATH $INSTALL_DIR \$PATH" >> "$FISH_CONFIG"
  echo "✅ Fish shell config updated."
else
  echo "ℹ️ Fish shell config already contains Twitch Downloader settings."
fi

sed -i -e '$a\' "$FISH_CONFIG"

echo "✅ Twitch Downloader is ready to use from anywhere!"
echo "🔁 Run: source ~/.config/fish/config.fish"
