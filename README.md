# Screen Ruler for Linux

A port of the [PowerToys Screen Ruler](https://learn.microsoft.com/windows/powertoys/screen-ruler) to Ubuntu and other GNOME desktops (X11 and Wayland).

Press a shortcut, point at something on screen, and the ruler snaps to the nearest edges and shows the size in pixels. Click to copy it. You don't have to drag a ruler into place by hand.

## Features

- **Four modes**, the same as PowerToys: Bounds (draw a box), Spacing (a cross that measures width and height), Horizontal and Vertical.
- **Edge snapping**: from the pixel under the cursor it walks outward until the colour changes by more than a tolerance you can adjust.
- **Copy to clipboard** in the PowerToys format (`360 × 240`).
- **Pin several measurements** with Shift+click.
- **Multiple monitors and HiDPI**: each monitor gets its own overlay, and fractional scaling is handled.
- **Extra units**: inches, cm, mm or logical (DIP) pixels next to the pixel value.

## Install

Requires Ubuntu 22.04 or newer, or another Debian-based GNOME desktop.

```bash
git clone https://github.com/lLalvar/screen-ruler.git
cd screen-ruler
./install.sh
```

The installer:

1. Installs the dependencies with `apt` (`python3-gi`, `python3-gi-cairo`, `gir1.2-gtk-3.0`, `python3-numpy`, `gnome-screenshot`, `libnotify-bin`). It asks for your sudo password.
2. Copies the app to `~/.local/bin/screen-ruler` and adds a "Screen Ruler" entry to your app menu.
3. Writes a default config to `~/.config/screen-ruler/config.json`.
4. Binds the keyboard shortcut **Super+R** (Super is the Windows key).

To uninstall, run `./uninstall.sh`. Add `--purge` to also delete your config.

## Usage

Press **Super+R**, or run `screen-ruler` from a terminal.

| Input | Action |
| --- | --- |
| `1` `2` `3` `4` (or `Ctrl+1`…`4`) | Switch mode: Bounds · Spacing · Horizontal · Vertical |
| Left click | Copy the measurement and close |
| Shift + click | Pin the measurement and keep measuring (copies all pinned) |
| Drag (Bounds mode) | Draw a box. Hold Shift on release to keep it |
| Mouse wheel, or `+` / `-` | Change the pixel tolerance by 15. Higher values ignore gradients and shadows |
| `U` | Cycle the extra unit: none → in → cm → mm → dip |
| `Esc` or right click | Close |

You can also click the buttons in the toolbar at the top of the screen.

### Command-line options

```bash
screen-ruler --mode bounds        # start in a given mode
screen-ruler --image mockup.png   # measure inside an image instead of the screen
screen-ruler --print              # also print the copied measurement to stdout
screen-ruler --delay 2            # wait 2 seconds before capturing (e.g. to open a menu)
```

## Change the keyboard shortcut

The default is **Super+R**. You can change it in one of three ways.

**In GNOME Settings (easiest):**

1. Open **Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts**.
2. Click **Screen Ruler**.
3. Click the shortcut, press the new key combination, and click **Set** or **Replace**.

**With one terminal command:**

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/screen-ruler/ binding '<Super><Shift>m'
```

**When installing:**

```bash
SHORTCUT='<Super><Shift>m' ./install.sh --no-deps
```

Shortcuts are written in GNOME's format: modifiers in angle brackets followed by a key, for example `<Super>r`, `<Control><Alt>m` or `<Super><Shift>F2`. If the new shortcut does nothing, another app or GNOME itself is probably already using it. Search for it under **Settings → Keyboard → View and Customize Shortcuts**.

On desktops other than GNOME (KDE, Xfce, Sway…), the installer can't set the shortcut. Bind `~/.local/bin/screen-ruler` to a key in your desktop's keyboard settings.

## Configuration

Edit `~/.config/screen-ruler/config.json`. The defaults are the same as PowerToys':

```json
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
```

| Key | Meaning |
| --- | --- |
| `pixel_tolerance` | 0–255. How different a pixel can be before it counts as an edge |
| `per_channel_edge_detection` | `true`: compare each colour channel separately. `false`: compare the sum of the channel differences |
| `draw_feet_on_cross` | Draw small end marks on the measurement lines |
| `line_color` | Colour of the measurement lines |
| `extra_unit` | `none`, `in`, `cm`, `mm` or `dip` |
| `default_mode` | `bounds`, `spacing`, `horizontal` or `vertical` |
| `wheel_step` | How much one mouse-wheel step changes the tolerance |
| `capture_backend` | `auto`, `x11`, `gnome-screenshot`, `portal` or `grim` |

With `auto`, X11 sessions capture the screen directly. On Wayland the app tries `gnome-screenshot` first (silent on GNOME), then the desktop screenshot portal (GNOME may ask for permission once), then `grim` (Sway, Hyprland).

If measurements don't reach the clipboard, set a copy command, for example `SCREEN_RULER_COPY_CMD="wl-copy"` on Wayland or `SCREEN_RULER_COPY_CMD="xclip -selection clipboard"` on X11.

## Limitations

- **Snapshot only.** The screen is captured once when the tool opens, which is also PowerToys' default. Live ("continuous") measuring isn't supported, because on Wayland it would need a screen-recording session and a permission prompt.
- The Wayland capture paths have had less testing than X11. Please [open an issue](https://github.com/lLalvar/screen-ruler/issues) if capture fails on your setup.

## How it works

It is a single Python/GTK 3 file, ported from [microsoft/PowerToys `src/modules/MeasureTool`](https://github.com/microsoft/PowerToys/tree/main/src/modules/MeasureTool):

| PowerToys (C++ / Direct3D / WinUI) | This port (Python / GTK 3 / numpy) |
| --- | --- |
| `ScreenCapturing.cpp`: Windows.Graphics.Capture per monitor | One desktop snapshot, cropped per monitor |
| `EdgeDetection.cpp::FindEdge`: walk from the cursor until a pixel differs from the start pixel | `find_edges()`: the same walk, vectorised with numpy |
| `BGRATextureView::PixelsClose`: sum of channel diffs ≤ tolerance, or each channel ≤ tolerance | The same two modes |
| `MeasurementLogic.h::Convert`: px/in/cm/mm/DIP | `convert()`. DIP = GNOME logical pixels |
| `MeasureToolOverlayUI.cpp`: click copies, Shift pins, wheel ±15 | The same |
| `BoundsToolOverlayUI.cpp`: drag a box, width = right − left + 1 | The same |

## Development

```bash
python3 tests/test_edges.py   # unit tests, no display needed
./screen-ruler --image some.png
```

The tests cover the PowerToys reference case, border handling, start-point clamping, both tolerance modes, gradients, unit conversion and the clipboard format.

## License

MIT. See [LICENSE](LICENSE). It includes the notice for Microsoft PowerToys, whose MIT-licensed source this port is based on.
