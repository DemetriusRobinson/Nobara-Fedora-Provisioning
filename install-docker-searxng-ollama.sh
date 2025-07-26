#!/bin/bash

# Exit on any error
set -e

echo "[1/8] Installing Docker..."
sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest \
    docker-latest-logrotate docker-logrotate docker-engine docker-compose-plugin || true

sudo dnf install -y dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
#sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[2/8] Starting Docker and enabling on boot..."
sudo systemctl enable --now docker

echo "[3/8] Adding user to docker group..."
sudo usermod -aG docker $USER

echo "[!] Please log out and back in or run 'newgrp docker' to apply group change."

echo "[4/8] Installing Open WebUI..."
mkdir -p ~/Applications
cd ~/Applications
rm -rf open-webui || true
git clone https://github.com/open-webui/open-webui.git
cd open-webui

cat > run.sh << 'EOF'
#!/bin/bash

image_name="open-webui"
container_name="open-webui"

docker build -t "$image_name" .
docker stop "$container_name" &>/dev/null || true
docker rm "$container_name" &>/dev/null || true

docker run -d \
    --network=host \
    -v "${image_name}:/app/backend/data" \
    --name "$container_name" \
    --restart always \
    "$image_name"

docker image prune -f
EOF

chmod +x run.sh
./run.sh

echo "[5/8] Installing SearXNG..."
mkdir -p ~/Applications/searxng/config
mkdir -p ~/Applications/searxng/data
cd ~/Applications/searxng

docker stop searxng &>/dev/null || true
docker rm searxng &>/dev/null || true

docker run --name searxng -d \
  -p 3001:8080 \
  -v "$(pwd)/config/:/etc/searxng/" \
  -v "$(pwd)/data/:/var/cache/searxng/" \
  docker.io/searxng/searxng:latest

echo "[6/8] Installing Ollama ROCm container..."
docker stop ollama &>/dev/null || true
docker rm ollama &>/dev/null || true

docker run -d \
  --device /dev/kfd \
  --device /dev/dri \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama \
  ollama/ollama:rocm

echo "[7/8] Pulling Ollama models..."
docker exec ollama ollama pull codellama:34b
docker exec ollama ollama pull deepseek-r1:32b
docker exec ollama ollama pull deepseek-r1:8b
docker exec ollama ollama pull codellama:13b
docker exec ollama ollama pull mistral:latest

echo "[8/8] Setup Complete!"
echo "Open WebUI: http://localhost:3000"
echo "SearXNG:   http://localhost:3001"
echo "Ollama API: http://localhost:11434"
echo ""
echo "Please log out and back in (or run 'newgrp docker') to finish enabling Docker group access."
