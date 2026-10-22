#!/usr/bin/env bash
# Remove screen-ruler (keeps ~/.config/screen-ruler unless --purge).
set -euo pipefail
KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/screen-ruler/"

rm -f "$HOME/.local/bin/screen-ruler" "$HOME/.local/share/applications/io.github.screenruler.desktop"

if command -v gsettings >/dev/null && gsettings list-schemas | grep -q org.gnome.settings-daemon.plugins.media-keys; then
  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
  updated="$(python3 - "$current" "$KB_PATH" <<'PY'
import ast, sys
cur, path = sys.argv[1].replace("@as ", ""), sys.argv[2]
items = [i for i in (ast.literal_eval(cur) if cur.strip() else []) if i != path]
print(str(items) if items else "@as []")
PY
)"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
  gsettings reset-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH" || true
fi

[[ "${1:-}" == "--purge" ]] && rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/screen-ruler"
echo "screen-ruler removed."
