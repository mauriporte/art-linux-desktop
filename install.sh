#!/usr/bin/env bash
# A.R.T. desktop look for Cinnamon (Debian 13): dark theme with orange accent, Phosphor icons,
# Roboto fonts, a flip-clock screensaver and an optional wallpaper. Per user, no root needed.
#   ./install.sh [--city "Lisbon"] [--wallpaper /path/to/image]
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DATA="$HOME/.local/share/art-desktop"
THEME="$HOME/.themes/ART-Dark"
ICONS="$HOME/.icons/ART-Phosphor"
FONTS="$HOME/.local/share/fonts/art-desktop"
CITY="" WALL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --city) CITY="$2"; shift 2 ;;
    --wallpaper) WALL="$2"; shift 2 ;;
    -h|--help) sed -n 2,4p "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ---- checks
[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root." >&2; exit 1; }
missing=()
for c in gsettings dconf gresource python3 xprop; do command -v "$c" >/dev/null || missing+=("$c"); done
python3 -c 'import gi; gi.require_version("Gtk", "3.0"); gi.require_version("PangoCairo", "1.0")' 2>/dev/null \
  || missing+=("python3-gi gir1.2-gtk-3.0")
[ -d /usr/share/cinnamon/theme ] || missing+=("cinnamon")
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing: ${missing[*]}" >&2
  echo "On Debian: sudo apt install cinnamon libglib2.0-bin dconf-cli x11-utils python3-gi gir1.2-gtk-3.0" >&2
  exit 1
fi
[ -z "$WALL" ] || [ -f "$WALL" ] || { echo "Wallpaper not found: $WALL" >&2; exit 1; }

# ---- 1. back up the current settings (the first backup is kept forever; uninstall restores it)
mkdir -p "$DATA"
KEYS=(
  "org.cinnamon.desktop.interface gtk-theme"
  "org.cinnamon.desktop.interface icon-theme"
  "org.cinnamon.desktop.interface font-name"
  "org.cinnamon.desktop.wm.preferences titlebar-font"
  "org.cinnamon.theme name"
  "org.cinnamon.desktop.background picture-uri"
  "org.cinnamon.desktop.background picture-options"
  "org.cinnamon.desktop.background primary-color"
  "org.cinnamon.desktop.screensaver idle-activation-enabled"
  "org.cinnamon.desktop.session idle-delay"
  "org.gnome.desktop.interface gtk-theme"
  "org.gnome.desktop.interface icon-theme"
  "org.gnome.desktop.interface color-scheme"
  "org.gnome.desktop.interface font-name"
)
if [ ! -f "$DATA/backup/keys.txt" ]; then
  mkdir -p "$DATA/backup"
  dconf dump / > "$DATA/backup/dconf-full.ini"
  for k in "${KEYS[@]}"; do
    # shellcheck disable=SC2086
    v="$(gsettings get $k 2>/dev/null)" && printf '%s\t%s\n' "$k" "$v"
  done > "$DATA/backup/keys.txt"
  echo "Saved your current settings in $DATA/backup"
fi

# ---- 2. ART-Dark theme, recoloured from the system's own Adwaita-dark (GTK3) and Cinnamon themes
# Base greys -> A.R.T. near-black/cards, blue accents -> orange #E8650A.
recolour() {
  sed -E -i \
    -e 's/#1b1b1b/#050505/gI; s/#1a1a1a/#050505/gI; s/#202020/#0c0c0d/gI; s/#1e1e1e/#0e0e0f/gI' \
    -e 's/#353535/#1c1c1e/gI; s/#2d2d2d/#141416/gI; s/#303030/#18181a/gI; s/#323232/#1a1a1c/gI' \
    -e 's/#313131/#1a1a1c/gI; s/#282828/#161618/gI; s/#262626/#151517/gI; s/#2a2a2a/#17171a/gI' \
    -e 's/#2b2b2b/#17171a/gI; s/#2e2e2e/#19191b/gI; s/#232323/#121214/gI; s/#373737/#232326/gI' \
    -e 's/#242424/#1c1c1e/gI; s/#333333/#2a2a2d/gI; s/#393939/#2e2e31/gI; s/#454545/#3a3a3e/gI' \
    -e 's/#656565/#55555a/gI; s/#919190/#9e9e9e/gI; s/#b2b2b2/#9e9e9e/gI' \
    -e 's/rgba\(36, 36, 36,/rgba(28, 28, 30,/g; s/rgba\(26, 26, 26,/rgba(5, 5, 5,/g' \
    -e 's/#15539e/#e8650a/gI; s/#3584e4/#e8650a/gI; s/#1f76e1/#e8650a/gI; s/#1b6acb/#f07a24/gI' \
    -e 's/#155099/#d85e09/gI; s/#16447c/#b85008/gI; s/#0f3b71/#a84705/gI; s/#092444/#4a2003/gI' \
    -e 's/#030c17/#1a0b01/gI; s/#78aeed/#f08a3e/gI; s/#1c71d8/#e8650a/gI; s/#62a0ea/#f08a3e/gI' \
    -e 's/rgba\(120, 174, 237,/rgba(240, 138, 62,/g; s/rgba\(53, 132, 228,/rgba(232, 101, 10,/g' \
    -e 's/rgba\(21, 83, 158,/rgba(232, 101, 10,/g; s/rgba\(192, 28, 40, 0\.5\)/rgba(232, 101, 10, 0.5)/g' \
    "$@"
}
rm -rf "$THEME"
mkdir -p "$THEME/gtk-3.0"
GTKLIB="$(ls /usr/lib/*/libgtk-3.so.0 /usr/lib/libgtk-3.so.0 2>/dev/null | head -1 || true)"
gresource extract "$GTKLIB" /org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css > "$THEME/gtk-3.0/gtk.css"
recolour "$THEME/gtk-3.0/gtk.css"
cp "$THEME/gtk-3.0/gtk.css" "$THEME/gtk-3.0/gtk-dark.css"
cp -r /usr/share/cinnamon/theme "$THEME/cinnamon"
recolour "$THEME/cinnamon/cinnamon.css" "$THEME"/cinnamon/*.svg
cat >> "$THEME/cinnamon/cinnamon.css" <<'EOF'

/* A.R.T. */
stage { font-family: Roboto, sans-serif; }
.panel-top, .panel-bottom, .panel-left, .panel-right { background-color: rgba(5, 5, 5, 0.92); }
.menu, .popup-menu-boxpointer, .popup-menu-content { background-color: #1c1c1e; border-radius: 12px; }
EOF
cat > "$THEME/index.theme" <<'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=ART-Dark
Comment=A.R.T. near-black with orange accent

[X-GNOME-Metatheme]
GtkTheme=ART-Dark
IconTheme=ART-Phosphor
EOF

# ---- 3. ART-Phosphor icons (Phosphor regular, MIT); missing names fall back to Adwaita
rm -rf "$ICONS"
dirs=""
while read -r ctx name ph; do
  case "$ctx" in ''|\#*) continue ;; esac
  mkdir -p "$ICONS/scalable/$ctx"
  # outline only, soft grey: orange stays the accent of the theme, not of every icon
  sed "s/currentColor/#c9cbd3/" "$HERE/icons/phosphor/$ph.svg" > "$ICONS/scalable/$ctx/$name.svg"
  sed "s/currentColor/#bebebe/" "$HERE/icons/phosphor/$ph.svg" > "$ICONS/scalable/$ctx/$name-symbolic.svg"
  case ",$dirs," in *",scalable/$ctx,"*) ;; *) dirs="${dirs:+$dirs,}scalable/$ctx" ;; esac
done < "$HERE/icons/map.txt"
{
  printf '[Icon Theme]\nName=ART-Phosphor\nComment=Phosphor icons (MIT) for A.R.T.\nInherits=Adwaita,hicolor\nDirectories=%s\n' "$dirs"
  IFS=, ; for d in $dirs; do printf '\n[%s]\nSize=64\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=%s\n' "$d" "${d#scalable/}"; done
  unset IFS
} > "$ICONS/index.theme"
cp "$HERE/icons/phosphor/LICENSE" "$ICONS/LICENSE"
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q "$ICONS" || true

# ---- 4. fonts (Roboto, Roboto Condensed: OFL)
mkdir -p "$FONTS"
cp "$HERE"/fonts/*.ttf "$HERE/fonts/OFL.txt" "$FONTS/"
fc-cache -f "$FONTS" >/dev/null 2>&1 || true

# ---- 5. flip clock: replaces Cinnamon's idle blank screen, same idle delay
mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart" "$HOME/.local/share/applications"
install -m 755 "$HERE/flipclock/art-flipclock" "$HOME/.local/bin/art-flipclock"
install -m 755 "$HERE/panel/art-panel" "$HOME/.local/bin/art-panel"
install -m 755 "$HERE/receiver/art-receiver" "$HOME/.local/bin/art-receiver"
cat > "$HOME/.config/autostart/art-receiver.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=A.R.T. Joint Remote receiver (now playing, media keys)
Exec=$HOME/.local/bin/art-receiver
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
cat > "$HOME/.config/autostart/art-panel.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=A.R.T. slide-in panel
Exec=$HOME/.local/bin/art-panel
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
cat > "$HOME/.config/autostart/art-flipclock.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=A.R.T. flip clock (idle watcher)
Exec=$HOME/.local/bin/art-flipclock --daemon
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
cat > "$HOME/.local/share/applications/art-flipclock.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Flip clock
Comment=A.R.T. flip clock screensaver
Exec=$HOME/.local/bin/art-flipclock
Icon=preferences-desktop-screensaver
Categories=Utility;
EOF
[ -z "$CITY" ] || "$HOME/.local/bin/art-flipclock" --city "$CITY"

# ---- 6. wallpaper (optional; otherwise solid near-black)
if [ -n "$WALL" ]; then
  ext="${WALL##*.}"
  cp "$WALL" "$DATA/wallpaper.$ext"
  gsettings set org.cinnamon.desktop.background picture-uri "file://$DATA/wallpaper.$ext"
  gsettings set org.cinnamon.desktop.background picture-options zoom
else
  gsettings set org.cinnamon.desktop.background picture-options none
  gsettings set org.cinnamon.desktop.background primary-color '#050505'
fi

# ---- 7. apply (keeps your current font size)
size="$(gsettings get org.cinnamon.desktop.interface font-name | tr -d "'" | awk '{print $NF}')"
case "$size" in ''|*[!0-9.]*) size=10 ;; esac
gsettings set org.cinnamon.desktop.interface gtk-theme ART-Dark
gsettings set org.cinnamon.desktop.interface icon-theme ART-Phosphor
gsettings set org.cinnamon.desktop.interface font-name "Roboto $size"
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "Roboto Medium $size"
gsettings set org.cinnamon.theme name ART-Dark
gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false
# Cinnamon 6.4 starts its own screensaver on session idle whatever idle-activation says, covering the flip clock:
# the clock takes over the idle delay (kept from Cinnamon's) and Cinnamon's idle timer goes off
if ! grep -q '^\[clock\]' "$HOME/.config/art-desktop/config.ini" 2>/dev/null; then
  d="$(gsettings get org.cinnamon.desktop.session idle-delay | awk '{print $NF}')"
  [ "${d:-0}" -gt 0 ] 2>/dev/null || d=300
  "$HOME/.local/bin/art-flipclock" --idle "$d" >/dev/null
fi
gsettings set org.cinnamon.desktop.session idle-delay 0
gsettings set org.gnome.desktop.interface gtk-theme ART-Dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme ART-Phosphor 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name "Roboto $size" 2>/dev/null || true

# start the idle watcher now (autostart takes over from the next login)
pkill -u "$USER" -f '[a]rt-flipclock --daemon' 2>/dev/null || true
pkill -u "$USER" -f '[a]rt-panel' 2>/dev/null || true
pkill -u "$USER" -f '[a]rt-receiver' 2>/dev/null || true
if [ -n "${DISPLAY:-}" ]; then
  setsid nohup "$HOME/.local/bin/art-receiver" >/dev/null 2>&1 < /dev/null &
  setsid nohup "$HOME/.local/bin/art-flipclock" --daemon >/dev/null 2>&1 < /dev/null &
  setsid nohup "$HOME/.local/bin/art-panel" >/dev/null 2>&1 < /dev/null &
fi

echo "A.R.T. look installed. Try the clock: art-flipclock   Change city: art-flipclock --city \"Madrid\""
echo "Undo everything: ./uninstall.sh"
