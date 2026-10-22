"""Edge-detection and unit tests, mirroring PowerToys MeasureToolCore semantics."""
import importlib.machinery
import importlib.util
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "..", "screen-ruler")
loader = importlib.machinery.SourceFileLoader("screen_ruler", SCRIPT)
spec = importlib.util.spec_from_loader("screen_ruler", loader)
sr = importlib.util.module_from_spec(spec)
sys.modules["screen_ruler"] = sr
loader.exec_module(sr)

BLUE, GREEN = (0, 0, 255), (0, 255, 0)


def canvas(w, h, color):
    img = np.zeros((h, w, 3), dtype=np.int16)
    img[:] = color
    return img


def test_powertoys_reference_example():
    # ScreenCapturing.cpp comment: 5x5 green square at (20,100) on blue -> [20,100]-[24,104]
    img = canvas(200, 200, BLUE)
    img[100:105, 20:25] = GREEN
    assert sr.find_edges(img, 22, 102, 30, False) == (20, 100, 24, 104)
    m = sr.Measurement("spacing", sr.find_edges(img, 22, 102, 30, False))
    assert (m.width_px(), m.height_px()) == (5, 5)


def test_runs_to_screen_border():
    img = canvas(50, 40, BLUE)
    assert sr.find_edges(img, 10, 10, 0, False) == (0, 0, 49, 39)


def test_start_point_is_clamped_like_powertoys():
    img = canvas(50, 40, BLUE)
    img[:, 0] = GREEN  # column 0 differs; start at x=0 is clamped to x=1
    l, _, r, _ = sr.find_edges(img, 0, 5, 0, False)
    assert (l, r) == (1, 49)


def test_sum_vs_per_channel_tolerance():
    img = canvas(100, 10, (100, 100, 100))
    img[:, 60:] = (120, 120, 120)  # each channel +20, sum +60
    # sum mode: 60 > 30 -> edge at 59
    assert sr.find_edges(img, 10, 5, 30, False)[2] == 59
    # per-channel: 20 <= 30 -> passes through to the border
    assert sr.find_edges(img, 10, 5, 30, True)[2] == 99
    # sum mode with tolerance 60 also passes
    assert sr.find_edges(img, 10, 5, 60, False)[2] == 99


def test_gradient_compares_against_start_pixel_not_neighbour():
    # PowerToys compares every pixel with the *start* pixel, so slow gradients still stop.
    img = np.zeros((5, 256, 3), dtype=np.int16)
    img[:, :, :] = np.arange(256, dtype=np.int16)[None, :, None]
    l, _, r, _ = sr.find_edges(img, 100, 2, 30, False)  # sum of 3 channels: |d|*3 <= 30 -> |d| <= 10
    assert (l, r) == (90, 110)


def test_units():
    assert sr.convert(96, "in", 0, 1) == 1.0  # 96 DPI fallback
    assert abs(sr.convert(100, "mm", 0.25, 1) - 25.0) < 1e-9
    assert abs(sr.convert(100, "cm", 0.25, 1) - 2.5) < 1e-9
    assert sr.convert(200, "dip", 0, 2) == 100
    assert sr.fmt(12.3456) == "12.35"


def test_clipboard_text_format():
    m = sr.Measurement("spacing", (0, 0, 127, 39))
    assert m.text("px", 0, 1, with_abbr=False) == "128 × 40"
    assert sr.Measurement("horizontal", (0, 0, 127, 39)).text("px", 0, 1, with_abbr=False) == "128"
    assert sr.Measurement("vertical", (0, 0, 127, 39)).text("px", 0, 1) == "40 px"


if __name__ == "__main__":
    fails = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            try:
                fn()
                print("PASS", name)
            except AssertionError as e:
                fails += 1
                print("FAIL", name, e)
    sys.exit(1 if fails else 0)
