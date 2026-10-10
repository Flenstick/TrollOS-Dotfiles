#!/usr/bin/env python3
"""widgets/IconSets.js from two pixel icon sets — the shell's other two icon styles (D3).

  icon-sets.py PIXELARTICONS_DIR HACKERNOON_DIR     (the unpacked npm packages:
      npm pack pixelarticons@2.4.1 @hackernoon/pixel-icon-library@1.1.0)

Each angelOS icon name (widgets/Icons.js) gets the closest icon of each set, rendered with
rsvg-convert at 1:1 on its 24-unit grid (the shapes sit on whole units: no half-tones),
cut to its ink and written as rows of '#' like ours — one cell per unit (pixelarticons draws
mostly with 2-unit squares, but not all on one grid: halving them would bend the shapes).
Names with no counterpart (the hearts with horns, the
pentagram — angelOS's own) and families with a member missing (a Wi-Fi bar, "previous")
keep ours, so a tray icon never changes style with its state.

Licences: pixelarticons — MIT, © 2019 Gerrit Halfmann; HackerNoon's Pixel Icon Library — the
icons CC BY 4.0, © HackerNoon (changed: rendered to bitmaps, cropped, recoloured by the
theme). See docs/ICON-CREDITS.md.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

# angelOS name → [pixelarticons name, HackerNoon name] (None: ours in that style)
MAP = {
    "camera": ["camera", "camera"], "document": ["file-text", "notebook"], "fire": ["fire", "fire"],
    "chat": ["comment", "comment"], "cd": ["album", "disc"], "sparkleStar": ["sparkles", "sparkles"],
    "sparkle": ["sparkle", "sparkles"], "star": ["star", "star"], "calc": ["calculator", None],
    "gear": ["gear", "cog"], "monitor": ["monitor", "pc"], "keyboard": ["keyboard", None],
    "mouse": ["mouse", None], "chip": ["cpu", None], "speaker": ["volume-2", "sound-on"],
    "speakerMute": ["volume-x", "sound-mute"], "mic": ["mic", None], "micMute": ["mic-off", None],
    "bell": ["bell", "bell"], "bellOff": ["bell-off", "bell-mute"], "music": ["music", "music"],
    "lock": ["lock", "lock"], "power": ["power", None], "moon": ["moon", "moon"], "sun": ["sun", "sun"],
    "logout": ["logout", "logout"], "refresh": ["reload", "refresh"], "folder": ["folder", "folder"],
    "plug": ["plug", None], "image": ["image", "image"], "palette": ["colors-swatch", "paint-brush"],
    "package": ["archive", "archive"], "terminal": ["terminal", "code-block"],
    "window": ["app-windows", "window-restore"], "calendar": ["calendar", "calender"],
    "info": ["info-box", "info-circle"], "warn": ["warning-diamond", "exclamation-triangle"],
    "trash": ["trash", "trash"], "search": ["search", "search"], "check": ["check", "check"],
    "close": ["close", "times"], "minimize": ["minus", "minus"], "maximize": ["square", "expand"],
    "plus": ["plus", "plus"], "minus": ["minus", "minus"], "arrowRight": ["arrow-right", "arrow-right"],
    "arrowLeft": ["arrow-left", "arrow-left"], "arrowDown": ["arrow-down", "arrow-down"],
    "arrowUp": ["arrow-up", "arrow-up"], "play": ["play", "play"], "pause": ["pause", "pause"],
    "next": ["forward", None], "prev": [None, None], "pin": ["map-pin", "thumbtack"],
    "gauge": ["speed-fast", None], "skull": ["skull", None], "wifi": ["wifi", "wifi"],
    "wifiOff": [None, None], "wifi1": [None, None], "wifi2": [None, None],
    "gamepad": ["gamepad", None], "cursor": ["cursor-minimal", None], "download": ["download", "download"],
    "grid": ["grid-2x2-2", "grid"],
}
# all or none: a state change must not switch the style
FAMILIES = [["wifi", "wifiOff", "wifi1", "wifi2"], ["play", "pause", "next", "prev"],
            ["mic", "micMute"], ["speaker", "speakerMute"], ["bell", "bellOff"],
            ["arrowRight", "arrowLeft", "arrowDown", "arrowUp"], ["minimize", "maximize", "close"],
            ["plus", "minus"]]
SETS = ["pixelarticons", "hackernoon"]


def raster(svg):
    with tempfile.NamedTemporaryFile(suffix=".png") as png:
        subprocess.run(["rsvg-convert", "-w", "24", "-h", "24", "-o", png.name, str(svg)], check=True)
        im = Image.open(png.name).convert("RGBA")
        return [[im.getpixel((x, y))[3] >= 128 for x in range(24)] for y in range(24)]


def rows(g):
    ys = [y for y, r in enumerate(g) if any(r)]
    xs = [x for x in range(len(g[0])) if any(r[x] for r in g)]
    if not ys:
        return None
    return ["".join("#" if g[y][x] else "." for x in range(xs[0], xs[-1] + 1)) for y in range(ys[0], ys[-1] + 1)]


def main():
    pa_dir = Path(sys.argv[1]) / "svg"
    hn_dir = Path(sys.argv[2]) / "icons/SVG/regular"
    out = {s: {} for s in SETS}
    for name, (pa, hn) in MAP.items():
        if pa:
            out["pixelarticons"][name] = rows(raster(pa_dir / (pa + ".svg")))
        if hn:
            out["hackernoon"][name] = rows(raster(hn_dir / (hn + ".svg")))
    for s in SETS:
        for fam in FAMILIES:
            if not all(out[s].get(n) for n in fam):
                for n in fam:
                    out[s].pop(n, None)
    js = [".pragma library", "",
          "// The shell's other two icon styles (Settings → Appearance → Icons; widgets/PxIcon): generated",
          "// by scripts/icon-sets.py, don't edit by hand. pixelarticons — MIT, (c) 2019 Gerrit Halfmann;",
          "// HackerNoon's Pixel Icon Library — the icons CC BY 4.0, (c) HackerNoon, changed: rendered to",
          "// bitmaps, cropped, coloured by the theme. docs/ICON-CREDITS.md has the licences and links.",
          "// A name missing from a set is drawn in angelOS's own style.", "",
          "const sets = " + json.dumps(out, indent=1, sort_keys=True) + ";", "",
          "function get(style, name) {", "    const s = sets[style];", "    return s && s[name] ? s[name] : null;", "}", ""]
    target = Path(__file__).resolve().parent.parent / "widgets/IconSets.js"
    target.write_text("\n".join(js))
    for s in SETS:
        print("%s: %d icons — ours: %s" % (s, len(out[s]), ", ".join(sorted(set(MAP) - set(out[s])))))


if __name__ == "__main__":
    main()
