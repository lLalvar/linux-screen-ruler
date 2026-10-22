# screen-ruler

PowerToys **Screen Ruler** (MeasureTool) port for Ubuntu GNOME, Wayland + X11. Single-file Python/GTK3 app.

## Layout
- `screen-ruler` — the whole app (executable, `#!/usr/bin/python3`; must be system Python with `gi`)
- `tests/test_edges.py` — edge detection, units, clipboard-format tests
- `install.sh` / `uninstall.sh` — apt deps, `~/.local/bin`, .desktop, GNOME shortcut Super+R
- `README.md` — usage, config, PowerToys → port mapping

## Commands
```bash
python3 tests/test_edges.py          # unit tests (no display needed)
./screen-ruler --image some.png      # try the overlay on an image instead of the screen
./screen-ruler --mode bounds --print # print the copied measurement to stdout
```

## Design (ported from microsoft/PowerToys src/modules/MeasureTool, MIT)
- Snapshot, not live: capture once, show one fullscreen overlay per monitor painted with its crop.
  Continuous capture is intentionally not ported (needs ScreenCast portal + PipeWire on Wayland).
- Capture order (`capture_desktop`): X11 root window → `gnome-screenshot -f` (silent on GNOME Wayland,
  it's on GNOME Shell's allow-list) → xdg screenshot portal → `grim`.
- `find_edges()` = `EdgeDetection.cpp::FindEdge`: walk from the cursor until a pixel differs from the
  **start** pixel (not the neighbour). Start point clamped to [1, size-2]. Result is inclusive l,t,r,b.
- Closeness = `BGRATextureView::PixelsClose`: sum of RGB diffs ≤ tol, or (per-channel) each ≤ tol.
- Sizes are inclusive: width = right − left + 1, for both spacing and bounds (matches PowerToys).
- Screenshot pixels vs logical px: per-monitor `Frame.sx/sy` = image px per logical px (HiDPI/fractional).
- Clipboard text matches PowerToys `Clipboard.cpp`: `W × H`, one measurement per line, no `px` suffix.
  Uses Gtk clipboard + `store()`, overridable with `SCREEN_RULER_COPY_CMD` (e.g. `wl-copy`).
- Defaults from PowerToys Settings.h/constants.h: tolerance 30, wheel step 15, color #FF4500, feet on.
- Config: `~/.config/screen-ruler/config.json` (keys in `DEFAULTS`).

## Conventions
- Keep it one file with no deps beyond apt packages (python3-gi, gir1.2-gtk-3.0, python3-gi-cairo, python3-numpy).
- When changing measurement behaviour, check the PowerToys source first and add a test.
- Verified on Xvfb (X11 path). The Wayland capture paths have not yet been tested on real hardware.
