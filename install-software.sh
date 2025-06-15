#!/usr/bin/env bash

set -e

INSTALL_DIR="$HOME/Applications"
BITWIG_DL_PAGE="https://www.bitwig.com/download/"
BITWIG_FLATPAK_URL_BASE="https://www.bitwig.com/dl/Bitwig%20Studio"
TOOLBOX_URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"

# -------- Detect OS --------
if grep -qi "nobara" /etc/os-release; then
  CURRENT_OS="Nobara"
else
  CURRENT_OS="Fedora"
fi
echo "🖥️ Detected OS: $CURRENT_OS"

# -------- App:OS Labels --------
declare -A APP_RULES=(
  [steam]="Nobara"
  [lutris]="Nobara"
  [winehq]="Nobara"
  [bitwig]="All"
  [jetbrains_toolbox]="All"
  [blender]="All"
  [freecad]="All"
  [kicad]="All"
  [krita]="All"
  [paintstorm]="All"
  [native_access]="All"
  [arturia]="All"
  [lmms]="All"
  [godot]="All"
  [unity]="All"
  [clipstudio]="All"
  [cura]="All"
  [material_maker]="All"
  [arduino]="All"
  [stability_matrix]="All"
)

function is_installed() {
  command -v "$1" &>/dev/null
}

function install_flatpak_if_missing() {
  if ! is_installed flatpak; then
    echo "🛠 Installing flatpak..."
    sudo dnf install -y flatpak
  fi
}

function install_from_dnf_or_flatpak() {
  local app_name="$1"
  local cmd_check="$2"
  local flatpak_id="$3"

  if is_installed "$cmd_check"; then
    echo "✅ $app_name already installed. Skipping..."
    return
  fi

  echo "📦 Trying to install $app_name via dnf..."
  if ! sudo dnf install -y "$app_name"; then
    echo "⚠️ $app_name not found in dnf. Falling back to Flatpak..."
    install_flatpak_if_missing
    flatpak install --user -y "$flatpak_id"
  fi

  echo "✅ $app_name installation complete (via dnf or Flatpak)."
}

function download_windows_app() {
  local name="$1"
  local url="$2"
  local filename="$3"

  local app_dir="$INSTALL_DIR/$name"
  mkdir -p "$app_dir"

  if [[ -f "$app_dir/$filename" ]]; then
    echo "✅ $name already downloaded. Skipping..."
    return
  fi

  echo "📥 Attempting to download $name..."
  if ! wget -O "$app_dir/$filename" "$url"; then
    echo "❌ Failed to download $name — check the URL or download manually."
  else
    echo "✅ $name download complete."
  fi
}


function install_bitwig() {
  if is_installed bitwig-studio || flatpak list | grep -iq bitwig; then
    echo "✅ Bitwig Studio already installed. Skipping..."
    return
  fi

  echo "🔍 Checking for latest Bitwig Studio version..."
  LATEST_VERSION=$(curl -s "$BITWIG_DL_PAGE" | grep -oP 'Bitwig Studio \K[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
  if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Could not detect Bitwig version. Skipping..."
    return
  fi

  echo "📥 Downloading Bitwig Studio Flatpak ($LATEST_VERSION)..."
  mkdir -p "$INSTALL_DIR/Bitwig_Studio"
  wget -O "$INSTALL_DIR/Bitwig_Studio/bitwig.flatpak" "$BITWIG_FLATPAK_URL_BASE/$LATEST_VERSION/installer_flatpak"

  install_flatpak_if_missing
  flatpak install --user --noninteractive "$INSTALL_DIR/Bitwig_Studio/bitwig.flatpak" || true
  echo "✅ Bitwig Studio installation complete."
}

function install_jetbrains_toolbox() {
  if [[ -d "$INSTALL_DIR/JetBrainsToolbox" ]]; then
    echo "✅ JetBrains Toolbox already installed. Skipping..."
    return
  fi

  echo "📥 Downloading JetBrains Toolbox..."
  TOOLBOX_JSON=$(curl -s "$TOOLBOX_URL")
  DOWNLOAD_LINK=$(echo "$TOOLBOX_JSON" | grep -oP '"linux":.*?"link":"\K(.*?)(?=")')
  if [[ -z "$DOWNLOAD_LINK" ]]; then
    echo "❌ Could not retrieve JetBrains Toolbox download URL."
    return
  fi

  mkdir -p "$INSTALL_DIR/JetBrainsToolbox"
  cd "$INSTALL_DIR/JetBrainsToolbox"
  wget -O toolbox.tar.gz "$DOWNLOAD_LINK"
  tar -xzf toolbox.tar.gz --strip-components=1
  chmod +x ./jetbrains-toolbox
  echo "✅ JetBrains Toolbox unpacked (not launched)."
}

function install_material_maker() {
  local base_dir="$INSTALL_DIR/MaterialMaker"
  mkdir -p "$base_dir"

  echo "📡 Checking Material Maker releases on GitHub..."

  releases_json=$(curl -s "https://api.github.com/repos/RodZill4/material-maker/releases")

  stable_url=$(echo "$releases_json" |
    grep browser_download_url |
    grep 'linux.tar.gz' |
    grep -v 'b[0-9]' |  # exclude beta
    head -n1 | cut -d '"' -f 4)

  beta_url=$(echo "$releases_json" |
    grep browser_download_url |
    grep 'linux.tar.gz' |
    grep 'b[0-9]' |
    head -n1 | cut -d '"' -f 4)

  if [[ -z "$stable_url" && -z "$beta_url" ]]; then
    echo "❌ Failed to detect any stable or beta release for Material Maker."
    return
  fi

  # --- Install Stable ---
  if [[ -n "$stable_url" ]]; then
    echo "📥 Downloading stable release: $stable_url"
    stable_dir="$base_dir/Stable"
    mkdir -p "$stable_dir"
    wget -O "$stable_dir/mm_stable.tar.gz" "$stable_url"
    tar -xf "$stable_dir/mm_stable.tar.gz" -C "$stable_dir" --strip-components=1
    chmod +x "$stable_dir/Material\ Maker" || true
    echo "✅ Material Maker Stable installed to $stable_dir"
  fi

  # --- Install Beta ---
  if [[ -n "$beta_url" ]]; then
    echo "📥 Downloading beta release: $beta_url"
    beta_dir="$base_dir/Beta"
    mkdir -p "$beta_dir"
    wget -O "$beta_dir/mm_beta.tar.gz" "$beta_url"
    tar -xf "$beta_dir/mm_beta.tar.gz" -C "$beta_dir" --strip-components=1
    chmod +x "$beta_dir/Material\ Maker" || true
    echo "✅ Material Maker Beta installed to $beta_dir"
  fi
}

function install_godot_dotnet() {
  local godot_dir="$INSTALL_DIR/Godot.NET"
  local stable_dir="$godot_dir/Stable"
  mkdir -p "$stable_dir"

  echo "📡 Fetching latest Godot .NET (Mono) stable version..."

  local mono_url=$(curl -s https://api.github.com/repos/godotengine/godot/releases |
    grep browser_download_url |
    grep 'mono.*linux.*x86_64.zip' |
    grep -vE 'rc|alpha|beta' |
    head -n1 | cut -d '"' -f 4)

  local mono_file=$(basename "$mono_url")
  local version=$(echo "$mono_file" | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')

  # Check if extracted folder already exists
  local extract_folder="$stable_dir/Godot_v${version}-stable_mono_linux_x86_64"
  if [[ -d "$extract_folder" ]]; then
    echo "✅ Godot .NET $version already installed at $extract_folder. Skipping download."
  else
    echo "📥 Downloading Godot .NET $version..."
    wget -O "$stable_dir/$mono_file" "$mono_url"
    unzip -o "$stable_dir/$mono_file" -d "$stable_dir"
  fi

  # Find binary and make executable
#   local godot_bin=$(find "$extract_folder" -maxdepth 1 -type f -name "Godot_v*-mono_linux.*" -o -name "Godot_v*-mono_linux_x86_64" | head -n1)
#   if [[ -n "$godot_bin" ]]; then
#     chmod +x "$godot_bin"
#     echo "✅ Godot binary made executable: $godot_bin"
#   else
#     echo "❌ Could not find the Godot executable in $extract_folder"
#   fi

  # Check for .NET SDK 8.0+
  echo "🔍 Checking for .NET SDK 8.0 or later..."
  if ! dotnet --list-sdks 2>/dev/null | grep -q '^8\.'; then
    echo "⚠️  .NET SDK 8.0+ not found."
    echo "💡 Install with: sudo dnf install -y dotnet-sdk-8.0"
    sudo dnf install -y dotnet-sdk-8.0
  else
    echo "✅ .NET SDK 8.0+ is already installed."
  fi
}

# -------- App Dispatcher --------
function process_apps() {
  for app in "${!APP_RULES[@]}"; do
    rule="${APP_RULES[$app]}"
    if [[ "$rule" != "All" && "$rule" == "$CURRENT_OS" ]]; then
      echo "⏩ Skipping $app (rule: $rule)"
      continue
    fi

    case "$app" in
      bitwig) install_bitwig ;;
      jetbrains_toolbox) install_jetbrains_toolbox ;;
      blender) install_from_dnf_or_flatpak "blender" "blender" "org.blender.Blender" ;;
      freecad) install_from_dnf_or_flatpak "freecad" "freecad" "org.freecadweb.FreeCAD" ;;
      kicad) install_from_dnf_or_flatpak "kicad" "kicad" "org.kicad.KiCad" ;;
      krita) install_from_dnf_or_flatpak "krita" "krita" "org.kde.krita" ;;
      lmms) install_from_dnf_or_flatpak "lmms" "lmms" "io.lmms.LMMS" ;;
      godot) install_godot_dotnet ;;
      unity) echo "📝 Unity not available in repos — please install via Unity Hub manually." ;;
      clipstudio) echo "📝 Clip Studio must be installed manually via Wine or Bottles." ;;
      cura) install_from_dnf_or_flatpak "cura" "cura" "com.ultimaker.cura" ;;
      material_maker) install_material_maker ;;
      arduino) install_from_dnf_or_flatpak "arduino" "arduino" "cc.arduino.arduinoide" ;;
      stability_matrix) echo "📝 Stability Matrix uses a .zip or AppImage installer. Handle manually." ;;
      paintstorm) download_windows_app "PaintstormStudio" "https://paintstormstudio.com/files/linux/PaintstormStudio.tar.gz" "PaintstormStudio.tar.gz" ;;
      native_access) download_windows_app "NativeAccess" "https://native-instruments.com/fileadmin/downloads/Native_Access_2_Installer.exe" "NativeAccessInstaller.exe" ;;
      arturia) echo "📝 Arturia Software Center must be downloaded manually from: https://www.arturia.com/support/downloads&manuals" ;;
      *) echo "❓ No install logic defined for $app. Skipping." ;;
    esac
  done
}

process_apps

echo "🎉 All apps processed based on OS logic and fallback rules!"
