#!/bin/bash

set -e

INSTALL_DIR="/opt/java"
FISH_CONFIG="$HOME/.config/fish/config.fish"

echo "📁 Creating $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER:$USER" "$INSTALL_DIR"
cd /tmp

echo "🌐 Fetching latest Oracle JDK URL..."
ORACLE_JDK_URL=$(curl -s https://www.oracle.com/java/technologies/downloads/ | grep -oP 'https://download.oracle.com/java/[^"]+/jdk-[0-9._]+_linux-x64_bin.tar.gz' | head -n 1)

if [[ -z "$ORACLE_JDK_URL" ]]; then
  echo "❌ Could not retrieve the Oracle JDK download URL. Oracle may have changed the site layout."
  exit 1
fi

JDK_TAR=$(basename "$ORACLE_JDK_URL")

echo "📦 Downloading $JDK_TAR..."
curl -LO "$ORACLE_JDK_URL"

echo "📂 Extracting to $INSTALL_DIR..."
tar -xzf "$JDK_TAR" -C "$INSTALL_DIR"

# Detect the actual extracted directory
EXTRACTED_DIR=$(tar -tf "$JDK_TAR" | head -n 1 | cut -d/ -f1)
JDK_PATH="$INSTALL_DIR/$EXTRACTED_DIR"

# Create symlink to "latest"
ln -sfn "$JDK_PATH" "$INSTALL_DIR/latest"

echo "🐟 Updating Fish shell config..."
if ! grep -q "Oracle JDK" "$FISH_CONFIG"; then
  echo -e "\n# Oracle JDK" >> "$FISH_CONFIG"
  echo "set -x JAVA_HOME \"$JDK_PATH\"" >> "$FISH_CONFIG"
  echo "set -x PATH \"\$JAVA_HOME/bin\" \$PATH" >> "$FISH_CONFIG"
  echo "✅ Fish config updated."
else
  echo "ℹ️ Oracle JDK is already configured in config.fish"
fi

echo "⚙️ Registering Oracle JDK with alternatives..."
sudo alternatives --install /usr/bin/java java "$JDK_PATH/bin/java" 2000
sudo alternatives --install /usr/bin/javac javac "$JDK_PATH/bin/javac" 2000

echo "🛠️ Setting Oracle JDK as system default..."
sudo alternatives --set java "$JDK_PATH/bin/java"
sudo alternatives --set javac "$JDK_PATH/bin/javac"

echo "🔁 Refreshing current Fish shell environment..."
echo "     source ~/.config/fish/config.fish"

echo "📄 Verifying Java version..."
java -version

echo "✅ Oracle JDK installation complete and active at $JDK_PATH"
