#!/bin/bash

set -e

echo "📦 Installing QEMU, KVM, libvirt, and supporting tools..."
sudo dnf install -y \
  qemu-kvm \
  libvirt \
  virt-install \
  virt-manager \
  bridge-utils \
  libvirt-daemon-config-network \
  libvirt-daemon-kvm \
  virt-viewer \
  libguestfs-tools

echo "🔧 Enabling and starting libvirtd service..."
sudo systemctl enable --now libvirtd

echo "👤 Adding current user ($USER) to libvirt group..."
sudo usermod -aG libvirt "$USER"

echo "🔁 Restart your session or run: newgrp libvirt"
echo "✅ QEMU + KVM + Virt-Manager installation complete."
