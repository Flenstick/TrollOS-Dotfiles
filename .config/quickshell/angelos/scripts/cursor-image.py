#!/usr/bin/env python3
"""The arrow of a cursor theme as a PNG, for the shake-to-find pointer.

  cursor-image.py <theme> <out.png>   → JSON {png, nominal, width, height, xhot, yhot}

Reads the Xcursor file (left_ptr / default / arrow) of the theme from the usual
icon folders, takes its largest image and writes it as a straight-alpha PNG.
Python standard library only.
"""
import json
from pathlib import Path
import struct
import sys
import zlib

DIRS = [Path.home() / ".local/share/icons", Path.home() / ".icons", Path("/usr/share/icons"), Path("/usr/share/pixmaps")]
NAMES = ["left_ptr", "default", "arrow", "top_left_arrow"]
IMAGE = 0xFFFD0002


def find(theme, seen=None):
    seen = seen or set()
    if theme in seen:
        return None
    seen.add(theme)
    for base in DIRS:
        for name in NAMES:
            f = base / theme / "cursors" / name
            if f.is_file():
                return f
    for base in DIRS:
        index = base / theme / "index.theme"
        if index.is_file():
            for line in index.read_text(errors="ignore").splitlines():
                if line.strip().lower().startswith("inherits"):
                    for parent in line.split("=", 1)[1].split(","):
                        hit = find(parent.strip(), seen)
                        if hit:
                            return hit
    return None


def largest(data):
    if data[:4] != b"Xcur":
        raise ValueError("not an Xcursor file")
    _, _, ntoc = struct.unpack_from("<III", data, 4)
    best = None
    for i in range(ntoc):
        kind, nominal, pos = struct.unpack_from("<III", data, 16 + i * 12)
        if kind != IMAGE:
            continue
        _, _, _, _, w, h, xhot, yhot, _ = struct.unpack_from("<IIIIIIIII", data, pos)
        if best is None or w * h > best[1] * best[2]:
            best = (nominal, w, h, xhot, yhot, pos + 36)
    if not best:
        raise ValueError("no image in the cursor")
    return best


def png(path, w, h, argb):
    rows = bytearray()
    for y in range(h):
        rows.append(0)
        for x in range(w):
            a, r, g, b = argb[(y * w + x) * 4 + 3], argb[(y * w + x) * 4 + 2], argb[(y * w + x) * 4 + 1], argb[(y * w + x) * 4]
            if a and a < 255:   # premultiplied → straight
                r, g, b = min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a)
            rows += bytes((r, g, b, a))

    def chunk(tag, body):
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + chunk(b"IEND", b""))


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    theme, out = sys.argv[1], sys.argv[2]
    f = find(theme) or find("default")
    if not f:
        print(json.dumps({"error": "no cursor"}))
        return 1
    data = f.read_bytes()
    nominal, w, h, xhot, yhot, pos = largest(data)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    png(out, w, h, data[pos:pos + w * h * 4])
    print(json.dumps({"png": out, "nominal": nominal, "width": w, "height": h, "xhot": xhot, "yhot": yhot}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
