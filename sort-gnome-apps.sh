#!/usr/bin/env bash

set -e

echo "🖥️ Configuring GNOME folders and dash favorites..."

# -- Detect OS
if grep -qi "nobara" /etc/os-release; then
  CURRENT_OS="Nobara"
else
  CURRENT_OS="Fedora"
fi

# -------- Folder Builder --------
function create_gnome_app_folder() {
  local folder_name="$1"
  shift
  local desktop_ids=("$@")

  local dconf_base="/org/gnome/desktop/app-folders/folders/$folder_name"
  local dconf_list="/org/gnome/desktop/app-folders/folder-children"

  # Register folder
  dconf write "$dconf_base/name" "'$folder_name'"

  # Add apps
  local app_list="['$(IFS="','"; echo "${desktop_ids[*]}")']"
  dconf write "$dconf_base/apps" "$app_list"

  # Include folder in menu
  existing=$(dconf read "$dconf_list" | tr -d "[]'" | tr "," "\n" | sed '/^$/d')
  updated=$(printf "'%s'" "$folder_name"; for f in $existing; do [[ "$f" == "$folder_name" ]] || printf ",'%s'" "$f"; done)
  dconf write "$dconf_list" "[$updated]"
}

# -------- Desktop App Groups --------
create_gnome_app_folder "Art & Engineering" \
  org.blender.Blender.desktop \
  org.kde.krita.desktop \
  org.freecad.FreeCAD.desktop \
  org.godotengine.Godot.desktop \
  jetbrains-toolbox.desktop \
  code.desktop

create_gnome_app_folder "Music Production" \
  com.bitwig.BitwigStudio.desktop \
  io.lmms.LMMS.desktop \
  org.ardour.Ardour.desktop \
  org.audacityteam.Audacity.desktop

create_gnome_app_folder "VM" \
  virt-manager.desktop \
  qemu.desktop \
  gnome-boxes.desktop

create_gnome_app_folder "Games" \
  com.valvesoftware.Steam.desktop \
  net.lutris.Lutris.desktop \
  com.github.Matoking.protonupqt.desktop \
  com.github.Sharkwouter.protonplus.desktop

# -------- Dash (Favorites bar) Pinning --------
declare -a favorites=(
  io.gitlab.zen_browser.Zen.desktop
  com.valvesoftware.Steam.desktop
  com.github.cassidyjames.flatpost.desktop
  org.gnome.Software.desktop
  org.gnome.Nautilus.desktop
  org.kde.konsole.desktop
  org.gnome.Calculator.desktop
  com.obsproject.Studio.desktop
  com.discordapp.Discord.desktop
  org.gnome.SystemMonitor.desktop
  org.kde.kdenlive.desktop
  com.spotify.Client.desktop
  org.gnome.Characters.desktop
  org.gnome.Settings.desktop
  com.nobara.updatesystem.desktop
)

valid_favorites=()
for app in "${favorites[@]}"; do
  if [[ "$CURRENT_OS" != "Nobara" && "$app" == "com.nobara.updatesystem.desktop" ]]; then
    continue
  elif [[ "$CURRENT_OS" == "Nobara" && "$app" == "org.gnome.Software.desktop" ]]; then
    continue
  fi

  if [[ -f "/usr/share/applications/$app" || -f "$HOME/.local/share/applications/$app" ]]; then
    valid_favorites+=("$app")
  fi
done

# Use Python to build proper GVariant format list
if [ ${#valid_favorites[@]} -gt 0 ]; then
  favorites_list=$(python3 -c "
import sys
apps = ${valid_favorites[@]+"${valid_favorites[@]}"}
apps = [f.strip() for f in apps if f.strip()]
print('[' + ', '.join([f"'{a}'" for a in apps]) + ']')
")
  dconf write /org/gnome/shell/favorite-apps "$favorites_list"
  echo "✅ Favorites applied successfully."
else
  echo "⚠️ No valid favorites found to pin."
fi

echo "✅ App folders and dash favorites set!"
