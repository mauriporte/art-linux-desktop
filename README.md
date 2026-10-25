# A.R.T. Linux desktop

A dark, quiet look for the **Cinnamon** desktop (Debian 13), matching the A.R.T. Android launchers:

- **ART-Dark** theme (GTK3 + Cinnamon): near-black `#050505`, cards `#1C1C1E`, muted `#9E9E9E`, orange accent `#E8650A`.
  Recoloured at install time from your system's own Adwaita-dark and Cinnamon themes, so it follows your versions.
- **ART-Phosphor** icons: [Phosphor](https://phosphoricons.com) outline icons (MIT) in soft grey; anything missing falls back to Adwaita.
- **Roboto / Roboto Condensed** fonts (OFL), your current font size kept.
- **Flip-clock screensaver**: 24-hour flip cards with the weather ([Open-Meteo](https://open-meteo.com), no account),
  drifting slowly against burn-in. Any key, click, touch or mouse move closes it. It starts after Cinnamon's idle delay
  (System Settings → Screensaver) and skips full-screen apps such as videos.
- **Slide-in panel for touch screens**: tap the small orange tab on the right edge (or click it) and swipe between
  *Weather* (now, next hours, five days, change city with a tap), and, when Home Assistant is set up, *Music*
  (now playing, cover, play/pause, skip, volume) and *Remote* (D-pad, OK, back, home, play, volume for an Android TV
  via HA's `remote.send_command`). Swipe right on the first page, tap ✕ or tap outside to close it.
- Optional wallpaper; otherwise a solid near-black background.

Everything is per user: no root, nothing outside your home folder.

## Install

```bash
git clone https://github.com/mauriporte/art-linux-desktop
cd art-linux-desktop
./install.sh --city "Lisbon" --wallpaper ~/Pictures/my-wallpaper.jpg
```

Both options are optional. You need `cinnamon`, `python3-gi`, `gir1.2-gtk-3.0`, `libglib2.0-bin`, `dconf-cli` and
`x11-utils`, which a normal Cinnamon install already has. X11 only (Cinnamon's default).

- Show the clock now: `art-flipclock` (also in the menu as *Flip clock*)
- Change the weather city: `art-flipclock --city "Madrid"`

## Home Assistant (optional)

Create `~/.config/art-desktop/ha.ini` (mode 600) with your HA address and entities, leave `token` empty, and paste
a long-lived access token into the panel's *Connect Home Assistant* box (or into the file):

```ini
[ha]
url = http://homeassistant.local:8123
token =
music = media_player.spotify
remote = remote.living_room_tv
```

The token stays in that file only. The panel polls HA every 10 s, and only while it is open.

## Uninstall

```bash
./uninstall.sh
```

The first install saves your settings (a full `dconf dump` plus the exact keys it changes). Uninstall puts those
keys back, removes everything it added, and leaves a copy of the backup in `~/art-desktop-backup`.

## Licences

Code: MIT. Icons: Phosphor Icons, MIT (`icons/phosphor/LICENSE`). Fonts: Roboto, SIL OFL 1.1 (`fonts/OFL.txt`).
