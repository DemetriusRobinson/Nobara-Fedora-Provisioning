#!/bin/bash

set -e

echo "🌐 Setting up Docker Engine repositories"
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

echo "🌐 Installing Latest Docker Engine"
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "⚙️ Starting Docker Engine"
sudo systemctl enable --now docker

echo "📄 Verifying Docker installation..."
docker --version
sudo docker run hello-world

# 1. Install Native SearXNG (Meta Search Engine)
echo "🔧 Installing native SearXNG to avoid Docker overhead"
APP_DIR="$HOME/Applications/searxng"
PORT=8888
VENV_DIR="$APP_DIR/venv"
SRC_DIR="$APP_DIR/src"

mkdir -p "$APP_DIR"

echo "📦 Installing dependencies for SearXNG"
sudo dnf install -y python3 python3-pip python3-venv python3-devel git openssl \
  @development-tools python3-lxml python3-babel

echo "📁 Cloning SearXNG repo"
git clone https://github.com/searxng/searxng "$SRC_DIR"

echo "🐍 Creating virtual environment"
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate.fish

echo "📥 Installing SearXNG in editable mode"
cd "$SRC_DIR"
pip install --upgrade pip setuptools wheel
make install

echo "⚙️ Updating settings.yml"
set SETTINGS_FILE $SRC_DIR/searx/settings.yml

echo "🔑 Generating secret_key"
SECRET_KEY=$(openssl rand -hex 32)
# Only make changes if file exists
if test -f $SETTINGS_FILE
    sed -i "s/^secret_key:.*/secret_key: \"$SECRET_KEY\"/" $SETTINGS_FILE
    sed -i "s/^port:.*/port: $PORT/" $SETTINGS_FILE
    sed -i "s/^bind_address:.*/bind_address: \"127.0.0.1\"/" $SETTINGS_FILE
else
    echo "❌ $SETTINGS_FILE not found!"
    exit 1
end

echo "✅ SearXNG installed natively!"
echo "📄 You can run it manually with:"
echo "cd \"$SRC_DIR\" && source \"$VENV_DIR/bin/activate\" && python searx/webapp.py"

# 2. Install Ollama with AMD ROCm Support
echo "🤖 Installing Ollama (with AMD GPU ROCm support)"
# Add your Ollama setup steps here

# 3. Install Open WebUI
echo "🧠 Installing Open WebUI frontend"
# Add your Open WebUI setup steps here

echo "✅ All services are installed!"
echo "🌍 Open WebUI: http://localhost:3000"
echo "🔎 SearXNG: http://localhost:$PORT"
