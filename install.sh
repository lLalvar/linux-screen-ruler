#!/usr/bin/env bash
# Install screen-ruler for the current user on Ubuntu (GNOME).
#   ./install.sh                 install with the default shortcut Super+R
#   ./install.sh --no-deps       skip apt packages
#   SHORTCUT='<Super><Shift>m' ./install.sh   use a different shortcut
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/screen-ruler"
SHORTCUT="${SHORTCUT:-<Super>r}"
KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/screen-ruler/"

if [[ "${1:-}" != "--no-deps" ]]; then
  echo "==> Installing dependencies (sudo apt)"
  # gnome-screenshot gives silent captures on GNOME Wayland (it is on GNOME Shell's allow-list)
  sudo apt-get install -y python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-numpy gnome-screenshot libnotify-bin
fi

echo "==> Installing to $BIN_DIR/screen-ruler"
install -Dm755 "$HERE/screen-ruler" "$BIN_DIR/screen-ruler"

mkdir -p "$APP_DIR"
cat > "$APP_DIR/io.github.screenruler.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Screen Ruler
Comment=Measure pixels on screen with edge detection (PowerToys-style)
Exec=$BIN_DIR/screen-ruler
Icon=applications-graphics
Terminal=false
Categories=Utility;Graphics;Development;
Keywords=ruler;measure;pixel;
EOF

if [[ ! -f "$CFG_DIR/config.json" ]]; then
  mkdir -p "$CFG_DIR"
  cat > "$CFG_DIR/config.json" <<'EOF'
{
  "pixel_tolerance": 30,
  "per_channel_edge_detection": false,
  "draw_feet_on_cross": true,
  "line_color": "#FF4500",
  "extra_unit": "none",
  "default_mode": "spacing",
  "wheel_step": 15,
  "capture_backend": "auto"
}
EOF
  echo "==> Wrote default config to $CFG_DIR/config.json"
fi

if command -v gsettings >/dev/null && gsettings list-schemas | grep -q org.gnome.settings-daemon.plugins.media-keys; then
  echo "==> Adding GNOME shortcut $SHORTCUT"
  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
  updated="$(python3 - "$current" "$KB_PATH" <<'PY'
import ast, sys
cur, path = sys.argv[1], sys.argv[2]
cur = cur.replace("@as ", "")
items = ast.literal_eval(cur) if cur.strip() else []
if path not in items:
    items.append(path)
print(str(items))
PY
)"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH"
  gsettings set "$schema" name "Screen Ruler"
  gsettings set "$schema" command "$BIN_DIR/screen-ruler"
  gsettings set "$schema" binding "$SHORTCUT"
else
  echo "!! gsettings/GNOME not found – bind $BIN_DIR/screen-ruler to a key in your desktop's settings."
fi

echo
echo "Done. Press $SHORTCUT (or run 'screen-ruler') to start measuring."
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "Note: $BIN_DIR is not on your PATH yet (log out/in, or add it)." ;; esac
