#!/usr/bin/env bash
# Builds the release app and installs it for the current user only:
# ~/.local/share/habitpp (app), app menu entry and icon. No sudo needed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${FLUTTER:-$HOME/development/flutter/bin/flutter}"
DEST="$HOME/.local/share/habitpp"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"

cd "$ROOT"
"$FLUTTER" build linux --release

pkill -x habitpp 2>/dev/null || true
rm -rf "$DEST"
mkdir -p "$DEST" "$APPS" "$ICONS"
cp -r build/linux/x64/release/bundle/. "$DEST/"
cp assets/habitpp.svg "$ICONS/habitpp.svg"

cat > "$APPS/uz.xursanali.habitpp.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Habitpp
Comment=IELTS bosim ilovasi
Exec=$DEST/habitpp
Icon=habitpp
Terminal=false
Categories=Education;
StartupWMClass=uz.xursanali.habitpp
DESKTOP

update-desktop-database "$APPS" 2>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "O'rnatildi: menyudan 'Habitpp' ni oching. Autostart: ilova ichida Sozlamalar."
