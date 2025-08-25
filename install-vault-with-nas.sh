#!/usr/bin/env bash

set -euo pipefail

create_vault_unseal_service() {
  echo "⚙️ Creating auto-unseal script and systemd service..."

  sudo tee /usr/local/bin/vault-unseal-on-boot.sh > /dev/null <<'EOF'
#!/usr/bin/env bash

# Auto-unseal Vault using stored unseal keys (for local/dev only)

VAULT_UNSEAL_FILE="/opt/vault/data/vault.un"

# Check if file exists
if [ ! -f "$VAULT_UNSEAL_FILE" ]; then
  echo "❌ Unseal file not found: $VAULT_UNSEAL_FILE"
  exit 1
fi

# Wait until Vault is ready to accept unseal requests
echo "⏳ Waiting for Vault API to become ready..."
until curl -s http://127.0.0.1:8200/v1/sys/seal-status | grep -q '"sealed":'; do
  sleep 1
done

# Extract unseal keys
UNSEAL_KEYS=($(grep 'Unseal Key' "$VAULT_UNSEAL_FILE" | awk '{print $4}'))

# Run unseal commands
if [ "${#UNSEAL_KEYS[@]}" -lt 3 ]; then
  echo "❌ Less than 3 unseal keys found."
  exit 1
fi


for i in {0..2}; do
  echo "🔓 Unsealing with key #$((i+1))..."
  vault operator unseal "${UNSEAL_KEYS[$i]}"
done

# Optionally log in with root token
ROOT_TOKEN=$(grep 'Initial Root Token' "$VAULT_UNSEAL_FILE" | awk '{print $4}')
echo "🔑 Logging in with root token..."
vault login "$ROOT_TOKEN"

echo "✔️ Auto-unseal and login complete."
EOF

  sudo chmod +x /usr/local/bin/vault-unseal-on-boot.sh

  sudo tee /etc/systemd/system/vault-unseal.service > /dev/null <<EOF
[Unit]
Description=Vault Auto Unseal Script
After=vault.service
Requires=vault.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vault-unseal-on-boot.sh
Environment=VAULT_ADDR=http://127.0.0.1:8200

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reexec
  sudo systemctl enable vault-unseal.service
}

echo "🔧 Installing Vault and setting up repository..."
sudo dnf install -y dnf-plugins-core

if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
  sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
else
  echo "📦 HashiCorp repo already exists. Skipping addrepo."
fi

sudo dnf install -y vault

echo "📁 Creating Vault data directory..."
if [ ! -d /opt/vault/data ]; then
  sudo mkdir -p /opt/vault/data
  sudo chown "$USER":"$USER" /opt/vault/data
fi

echo "⚙️ Writing Vault config to /etc/vault.d/vault.hcl..."
sudo mkdir -p /etc/vault.d
sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF
ui = true
disable_mlock = true

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}

storage "file" {
  path = "/opt/vault/data"
}
EOF

echo "🐟 Ensuring VAULT_ADDR is in Fish config..."
FISH_CONFIG="$HOME/.config/fish/config.fish"
VAULT_ADDR_LINE="set -gx VAULT_ADDR http://127.0.0.1:8200"
grep -qxF "$VAULT_ADDR_LINE" "$FISH_CONFIG" || echo "$VAULT_ADDR_LINE" >> "$FISH_CONFIG"
export VAULT_ADDR="http://127.0.0.1:8200"

# Get default gateway
GATEWAY=$(ip route | awk '/default/ {print $3}')

echo "🛠️ Creating systemd service..."
sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description=Vault
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Enabling and starting Vault systemd service..."
sudo systemctl daemon-reexec
sudo systemctl enable --now vault

echo "⏳ Waiting for Vault to become available..."
until curl -s http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; do
  sleep 5
done

echo "🔐 Target NAS IP required"
read -rp "Enter NAS VM IP (e.g. 10.5.1.13): " NAS_IP
if [[ -z "${NAS_IP:-}" ]]; then
  echo "NAS IP is required." >&2
  exit 1
fi

echo "🔐 Initializing Vault and saving unseal keys and root token..."
#sleep 5
sudo chown "$(whoami)":"$(whoami)" /opt/vault/data
vault operator init > /opt/vault/data/vault.un

echo "🔓 Unsealing Vault..."
UNSEAL_KEYS=($(grep 'Unseal Key' /opt/vault/data/vault.un | awk '{print $4}'))
vault operator unseal "${UNSEAL_KEYS[0]}"
vault operator unseal "${UNSEAL_KEYS[1]}"
vault operator unseal "${UNSEAL_KEYS[2]}"

echo "🔑 Logging into Vault with root token..."
ROOT_TOKEN=$(grep 'Initial Root Token' /opt/vault/data/vault.un | awk '{print $4}')
vault login "$ROOT_TOKEN"

# Add unseal automation before creating the secret engine
create_vault_unseal_service

echo "📂 Enabling new KV secrets engine at path SMBNASCreds..."
vault secrets enable -path=SMBNASCreds kv

echo "🔐 Prompting for NAS credentials to store..."
read -p "Enter NAS username: " NAS_USERNAME
read -s -p "Enter NAS password: " NAS_PASSWORD
echo

echo "📝 Storing credentials in SMBNASCreds"
vault kv put SMBNASCreds/credentials username="$NAS_USERNAME" password="$NAS_PASSWORD"



# Create vault-mount-nas script and service
echo "🧰 Setting up NAS mount automation..."
sudo tee /usr/local/bin/vault-mount-nas.sh > /dev/null << 'EOF'
#!/usr/bin/env bash

set -euo pipefail

export VAULT_ADDR="http://127.0.0.1:8200"
VAULT_PATH="SMBNASCreds/credentials"

# Wait for Vault to be unsealed and ready
echo "⏳ Waiting for Vault to become ready..."
until curl -s $VAULT_ADDR/v1/sys/seal-status | grep -q '"sealed":'; do
  sleep 1
done

# Ensure mount directories exist
sudo mkdir -p /mnt/smbDevelopment
sudo mkdir -p /mnt/smbEntertainment

# Fetch credentials from Vault
echo "🔐 Fetching NAS credentials from Vault..."
USERNAME=$(vault kv get -field=username "$VAULT_PATH")
PASSWORD=$(vault kv get -field=password "$VAULT_PATH")

# Create temporary credentials file
CREDENTIALS_FILE="/tmp/.smbcredentials"
echo "username=$USERNAME" > "$CREDENTIALS_FILE"
echo "password=$PASSWORD" >> "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"

# Mount SMB shares
echo "🔗 Mounting NAS shares from //$NAS_IP ..."
sudo mount -t cifs //$NAS_IP/smbDevelopment /mnt/smbDevelopment \
  -o credentials="$CREDENTIALS_FILE",uid=$(id -u),gid=$(id -g),dir_mode=0775,file_mode=0664,noperm,vers=2.0

sudo mount -t cifs //$NAS_IP/smbEntertainment /mnt/smbEntertainment \
  -o credentials="$CREDENTIALS_FILE",uid=$(id -u),gid=$(id -g),dir_mode=0775,file_mode=0664,noperm,vers=2.0


# Cleanup temp credentials
rm -f "$CREDENTIALS_FILE"

echo "✅ NAS shares mounted successfully."

EOF
sudo chmod +x /usr/local/bin/vault-mount-nas.sh

sudo tee /etc/systemd/system/vault-mount-nas.service > /dev/null << EOF
[Unit]
Description=Mount NAS shares using Vault credentials
After=network-online.target vault-unseal.service
Requires=network-online.target vault-unseal.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for i in {1..20}; do /usr/local/bin/vault-mount-nas.sh && break || sleep 10; done'
Environment=VAULT_ADDR=http://127.0.0.1:8200

[Install]
WantedBy=multi-user.target


EOF

sudo systemctl daemon-reexec
sudo systemctl enable vault-mount-nas.service

echo "✅ Vault setup complete, unsealed, and SMBNASCreds populated!"
