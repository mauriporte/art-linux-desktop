#!/usr/bin/env bash
# Puts back the settings saved by install.sh and removes everything it added.
set -euo pipefail

DATA="$HOME/.local/share/art-desktop"
BK="$DATA/backup/keys.txt"

pkill -u "$USER" -f '[a]rt-flipclock' 2>/dev/null || true

if [ -f "$BK" ]; then
  while IFS=$'\t' read -r key val; do
    # shellcheck disable=SC2086
    gsettings set $key "$val" || echo "Could not restore $key" >&2
  done < "$BK"
  echo "Restored your previous settings (full dconf dump kept in $HOME/art-desktop-backup)."
  mkdir -p "$HOME/art-desktop-backup"
  cp "$DATA/backup/"* "$HOME/art-desktop-backup/"
else
  echo "No saved settings found in $DATA/backup; removing files only." >&2
fi

rm -rf "$HOME/.themes/ART-Dark" "$HOME/.icons/ART-Phosphor" "$HOME/.local/share/fonts/art-desktop" "$DATA"
rm -f "$HOME/.local/bin/art-flipclock" "$HOME/.config/autostart/art-flipclock.desktop" \
      "$HOME/.local/share/applications/art-flipclock.desktop"
fc-cache -f >/dev/null 2>&1 || true
echo "A.R.T. look removed. Your weather setting stays in ~/.config/art-desktop (delete it if you like)."
