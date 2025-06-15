#!/usr/bin/env bash

set -euo pipefail

export VAULT_ADDR="http://127.0.0.1:8200"
VAULT_PATH="AsusNASCreds/credentials"

# Wait for Vault to be unsealed and ready
echo "⏳ Waiting for Vault to become ready..."
until curl -s $VAULT_ADDR/v1/sys/seal-status | grep -q '"sealed":'; do
  sleep 1
done


# Ensure mount directories exist
sudo mkdir -p /mnt/AsusDevelopment
sudo mkdir -p /mnt/AsusEntertainment

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
echo "🔗 Mounting NAS shares..."
sudo mount -t cifs //192.168.50.1/Development /mnt/AsusDevelopment \
  -o credentials=$CREDENTIALS_FILE,uid=$(id -u),gid=$(id -g),vers=2.0

sudo mount -t cifs //192.168.50.1/Entertainment /mnt/AsusEntertainment \
  -o credentials=$CREDENTIALS_FILE,uid=$(id -u),gid=$(id -g),vers=2.0

# Cleanup temp credentials
rm -f "$CREDENTIALS_FILE"

echo "✅ NAS shares mounted successfully."
