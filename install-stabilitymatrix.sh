#!/bin/bash

set -e

INSTALL_DIR="$HOME/Applications/AI_Software/StabilityMatrix"
DESKTOP_FILE="$HOME/.local/share/applications/StabilityMatrix.desktop"

echo "📁 Creating install directory..."
mkdir -p "$INSTALL_DIR"
cd /tmp

echo "🌐 Fetching latest StabilityMatrix release URL..."
ZIP_URL=$(curl -s https://api.github.com/repos/LykosAI/StabilityMatrix/releases/latest | \
  grep "browser_download_url" | grep "linux-x64.zip" | cut -d '"' -f 4)

if [[ -z "$ZIP_URL" ]]; then
  echo "❌ Could not find a suitable StabilityMatrix release zip."
  exit 1
fi

ZIP_FILE=$(basename "$ZIP_URL")

echo "📦 Downloading $ZIP_FILE..."
curl -LO "$ZIP_URL"

echo "📂 Extracting to $INSTALL_DIR..."
unzip -o "$ZIP_FILE" -d "$INSTALL_DIR"

cd "$INSTALL_DIR"

APPIMAGE=$(find . -type f -name "*.AppImage" | head -n 1)

if [[ -z "$APPIMAGE" ]]; then
  echo "❌ AppImage not found."
  exit 1
fi

echo "🛠️ Making AppImage executable..."
chmod +x "$APPIMAGE"

echo "🧩 Extracting AppImage contents..."
"./$APPIMAGE" --appimage-extract > /dev/null

ICON_PATH=$(find squashfs-root -type f -name "*.png" | head -n 1)

if [[ -z "$ICON_PATH" ]]; then
  echo "⚠️ PNG icon not found. .desktop entry will use fallback icon."
  ICON_PATH="/usr/share/icons/hicolor/48x48/apps/utilities-terminal.png"
else
  # Convert to absolute path
  ICON_PATH="$INSTALL_DIR/$ICON_PATH"
fi

echo "🖼️ Creating .desktop launcher..."
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Stability Matrix
Exec=$INSTALL_DIR/$APPIMAGE
Icon=$ICON_PATH
Terminal=false
Categories=Graphics;AI;Utility;
EOF

chmod +x "$DESKTOP_FILE"

echo "✅ Stability Matrix installed and .desktop entry created!"
