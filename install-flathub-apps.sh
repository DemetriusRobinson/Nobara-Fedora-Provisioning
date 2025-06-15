#!/bin/bash

set -e

echo "📦 Installing Flathub apps..."

echo "🌐 Installing Zen Browser via Flatpak..."
flatpak install -y flathub app.zen_browser.zen
echo "🌐 Installing Vivaldi Browser via Flatpak..."
flatpak install -y flathub com.vivaldi.Vivaldi
echo "🌐 Installing Floorp Browser via Flatpak..."
flatpak install -y flathub one.ablaze.floorp
echo "🌐 Installing Peek via Flatpak..."
flatpak install -y flathub com.uploadedlobster.peek
echo "🌐 Installing pupgui2 via Flatpak..."
flatpak install -y flathub net.davidotek.pupgui2
echo "🌐 Installing Android Studio via Flatpak..."
flatpak install -y flathub com.google.AndroidStudio
echo "🌐 Installing itch.io via Flatpak..."
flatpak install -y flathub io.itch.itch

echo "✅ Flathub app installation complete."
