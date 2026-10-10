#!/usr/bin/env python3
"""fastfetch draws the angelOS emblem (Settings → Bar → Logo).

  fastfetch-logo.py --emblem NAME --rows JSON --palette JSON   write the emblem
  fastfetch-logo.py --restore                                   put the original back

Writes ~/.config/fastfetch/logo.txt (40×16 truecolor blocks, the size the
config.jsonc declares). The logo that was there first is kept once as
logo-original.txt; the heart emblem uses it (the hand-drawn winged heart with
the halo and pill). A logo.txt edited by hand afterwards is left alone.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

DIR = Path.home() / ".config/fastfetch"
LOGO = DIR / "logo.txt"
ORIGINAL = DIR / "logo-original.txt"
STAMP = DIR / ".angelos-logo"          # hash of the last logo.txt written here
WIDTH, HEIGHT = 40, 16
TEXT = ["\x1b[1;38;2;255;111;176m✧ INTERNET ANGEL ✧\x1b[0m",
        "\x1b[38;2;201;182;255mN E E D Y  G I R L  O V E R D O S E\x1b[0m"]
TEXT_WIDTH = [18, 35]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def rgb(hex_colour):
    h = hex_colour.lstrip("#")[:6]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def render(rows, palette):
    """Each art pixel is two full blocks: square pixels in a terminal."""
    lines = []
    for row in rows:
        out, current = "", None
        for ch in row:
            colour = palette.get(ch) if ch not in ". " else None
            if colour is None:
                if current is not None:
                    out += "\x1b[0m"
                    current = None
                out += "  "
            else:
                if colour != current:
                    out += "\x1b[38;2;%d;%d;%dm" % rgb(colour)
                    current = colour
                out += "██"
        lines.append(out + ("\x1b[0m" if current is not None else ""))
    width = max(len(r) for r in rows) * 2
    left = max(0, (WIDTH - width) // 2)
    art = [" " * left + line for line in lines]
    text = [" " * max(0, (WIDTH - w) // 2) + t for t, w in zip(TEXT, TEXT_WIDTH)]
    body = art + [""] + text
    top = max(0, (HEIGHT - len(body)) // 2)
    body = [""] * top + body
    return "\n".join(body + [""] * max(0, HEIGHT - len(body))) + "\n"


def ours(data):
    """logo.txt is ours to replace: written here, the original, or never customised."""
    if not STAMP.exists():
        return True
    known = {STAMP.read_text().strip()}
    if ORIGINAL.exists():
        known.add(digest(ORIGINAL.read_bytes()))
    return digest(data) in known


def write(data):
    tmp = LOGO.with_suffix(".tmp")
    tmp.write_bytes(data)
    tmp.replace(LOGO)
    STAMP.write_text(digest(data) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--emblem", default="heart")
    ap.add_argument("--rows", default="[]")
    ap.add_argument("--palette", default="{}")
    ap.add_argument("--restore", action="store_true")
    a = ap.parse_args()
    if not DIR.is_dir():
        print("no fastfetch config")
        return 0
    current = LOGO.read_bytes() if LOGO.exists() else b""
    if current and not ours(current):
        print("logo.txt was edited by hand; left alone")
        return 0
    if current and not ORIGINAL.exists():
        shutil.copyfile(LOGO, ORIGINAL)
    if a.restore or a.emblem == "heart":
        if ORIGINAL.exists():
            data = ORIGINAL.read_bytes()
            if data != current:
                write(data)
            print("original")
            return 0
        if a.restore:
            return 0
    rows, palette = json.loads(a.rows), json.loads(a.palette)
    if not rows or not isinstance(rows, list) or not isinstance(palette, dict):
        print("nothing to draw", file=sys.stderr)
        return 1
    data = render(rows, palette).encode()
    if data != current:
        write(data)
    print("written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
