#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
JS_TEMPLATE="$SCRIPT_DIR/panel_config.js"

# Ask user for monitor index
echo "Detecting screens..."
MONITORS=$(qdbus org.kde.KWin /KWin org.kde.KWin.screens)
echo "Monitors:"
echo "$MONITORS"
read -rp "Enter screen index to apply panels to (e.g., 0): " SCREEN_INDEX

# Ask to reset top panel
read -rp "Recreate TOP panel if it exists? [y/N]: " TOP_CHOICE
[[ "$TOP_CHOICE" =~ ^[Yy]$ ]] && TOP_OK="true" || TOP_OK="false"

# Ask to reset bottom panel
read -rp "Recreate BOTTOM panel if it exists? [y/N]: " BOTTOM_CHOICE
[[ "$BOTTOM_CHOICE" =~ ^[Yy]$ ]] && BOTTOM_OK="true" || BOTTOM_OK="false"

# Replace placeholders in the JS file and run
FINAL_JS=$(cat "$JS_TEMPLATE" | \
  sed "s/{{SCREEN}}/$SCREEN_INDEX/g" | \
  sed "s/{{TOP_OK}}/$TOP_OK/g" | \
  sed "s/{{BOTTOM_OK}}/$BOTTOM_OK/g")

# Run it
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$FINAL_JS"
