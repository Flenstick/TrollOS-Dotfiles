#!/usr/bin/env python3
"""angelOS pixel wordmarks (Panel → Logo: Windose, Hell, Y2K Chrome) drawn from real pixel
fonts, so the letters are the same size as the text wordmarks (Classic 95, Angel +):

  windose  Pixeloid Sans Bold 9 px, white sticker letters, ink outline, a coloured rim;
           the O is a pill (accent top, white bottom)
  chrome   Pixeloid Sans Bold 9 px in Y2K chrome bands (white → silver → grey horizon →
           pink), ink outline, a sparkle
  hell     Jacquard 24 (a pixel blackletter, OFL) at half the art pixel: red letters with
           a dark-red drop shadow, a near-black outline and a few drips

A dev tool: its output is pasted into widgets/Logos.js (no fonts needed at run time).
AngelLogo scales an art pixel to fontSize / 9 × `scale`, the grid of the 9 px title
font, so the rows here line up with "angel" set in it (each mark keeps the whole line
box — ascent to descent — and pads it evenly, centred like the text).

  wordmark-art.py --pixeloid DIR --jacquard FILE [--preview out.png] [--js]
"""
import argparse
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFont


def render(path, size, text):
    """the text's pixels in its full line box (rows: ascent + descent), columns trimmed"""
    ft = ImageFont.truetype(path, size)
    asc, desc = ft.getmetrics()
    im = Image.new("L", (int(ft.getlength(text)) + size, asc + desc), 0)
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    d.text((0, 0), text, font=ft, fill=255)
    a = np.array(im) > 127
    cols = np.nonzero(a.any(0))[0]
    return a[:, cols.min():cols.max() + 1]


def hcat(parts, gap):
    h = max(p.shape[0] for p in parts)
    out = []
    for i, p in enumerate(parts):
        if i:
            out.append(np.zeros((h, gap), bool))
        out.append(p)
    return np.concatenate(out, 1)


def grow(m, n=1):
    """8-neighbour dilation by n (the array keeps its size)"""
    for _ in range(n):
        p = np.pad(m, 1)
        g = np.zeros_like(p)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                g |= np.roll(np.roll(p, dy, 0), dx, 1)
        m = g[1:-1, 1:-1]
    return m


def grid(h, w):
    return np.full((h, w), ".", dtype="<U1")


def rows(g):
    return ["".join(r) for r in g]


def windose(pix_bold):
    angel = render(pix_bold, 9, "angel")
    s = render(pix_bold, 9, "S")
    h = angel.shape[0]
    top = int(np.nonzero(s.any(1))[0].min())        # cap height rows
    bot = int(np.nonzero(s.any(1))[0].max())
    ph = bot - top + 1
    pill = np.zeros((h, 6), bool)
    pill[top:bot + 1, :] = True
    pill[top, 0] = pill[top, 5] = pill[bot, 0] = pill[bot, 5] = False   # rounded
    word = hcat([angel, pill, s], 1)
    pad = 2
    m = np.pad(word, pad)
    pm = np.pad(hcat([np.zeros_like(angel), pill, np.zeros_like(s)], 1), pad)
    g = grid(*m.shape)
    g[grow(m, 2) & ~grow(m, 1)] = "x"                 # coloured rim
    g[grow(m, 1) & ~m] = "#"                          # ink outline
    g[m] = "w"
    # the pill: accent top half, a seam, a white bottom, a shine
    ys, xs = np.nonzero(pm)
    mid = top + pad + ph // 2
    for y, x in zip(ys, xs):
        g[y, x] = "o" if y < mid else ("#" if y == mid else "w")
    g[top + pad + 1, xs.min() + 1] = "w"
    return rows(g), 1


def chrome(pix_bold):
    word = render(pix_bold, 9, "angelOS")
    h, w = word.shape
    pad = 1
    m = np.pad(word, ((pad, pad), (pad, pad + 4)))
    g = grid(*m.shape)
    g[grow(m, 1) & ~m] = "#"
    # bands by line-box row: highlight, silver, the dark horizon, silver, pink reflection
    band = {2: "w", 3: "w", 4: "w", 5: "s", 6: "g", 7: "s", 8: "p", 9: "p", 10: "p"}
    for y, x in zip(*np.nonzero(m)):
        g[y, x] = band.get(y - pad, "p")
    # a four-point sparkle over the S
    sx, sy = m.shape[1] - 3, pad + 1
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        g[sy + dy, sx + dx] = "y" if (dx, dy) == (0, 0) else "w"
    return rows(g), 1


def hell(jacquard):
    word = render(jacquard, 24, "angelOS")
    h, w = word.shape
    pad = 3
    m = np.pad(word, pad)
    # drips: from the lowest pixel of a few stems, 2–5 px down
    drips = np.zeros_like(m)
    cols = [c for c in range(m.shape[1]) if m[:, c].any()]
    base = max(int(np.nonzero(m[:, c])[0].max()) for c in cols)
    picks = [cols[int(len(cols) * f)] for f in (0.08, 0.37, 0.6, 0.9)]
    for i, c in enumerate(picks):
        ys = np.nonzero(m[:, c])[0]
        y0 = int(ys.max())
        if y0 < base - 3:          # only from letters on the baseline
            continue
        n = (2, 4, 3, 5)[i]
        drips[y0 + 1:min(m.shape[0], y0 + 1 + n), c] = True
    body = m | drips
    shadow = np.roll(np.roll(body, 1, 0), 1, 1) & ~body
    g = grid(*m.shape)
    g[grow(body | shadow, 1) & ~(body | shadow)] = "k"
    g[shadow] = "d"
    g[body] = "r"
    # a hot highlight on each letter's top pixels
    tops = body & ~np.roll(body, 1, 0)
    g[tops & m] = "e"
    return rows(g), 0.5


PALETTE = {  # preview colours (a pink dark theme); the shell uses the theme's
    "#": (58, 16, 48), "w": (255, 255, 255), "o": (255, 95, 162), "x": (138, 125, 255),
    "y": (255, 216, 74), "s": (200, 200, 215), "g": (150, 150, 170), "p": (255, 182, 214),
    "r": (224, 32, 58), "d": (122, 10, 30), "k": (26, 5, 8), "e": (255, 120, 110),
}


def preview(marks, out, pix_regular):
    scale = 2       # an 18 px title: the 9 px grid at 2 screen px
    blocks = []
    # the reference: "angel" + "OS" set in the title font as AngelLogo does (18 px)
    ft = ImageFont.truetype(pix_regular, 18)
    ref = Image.new("RGBA", (200, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(ref)
    d.fontmode = "1"
    d.text((0, 2), "angel", font=ft, fill=PALETTE["o"])
    d.text((int(ft.getlength("angel")), 2), "OS", font=ImageFont.truetype(pix_regular.replace(".ttf", "-Bold.ttf"), 18), fill=PALETTE["x"])
    blocks.append(("angel (text)", ref))
    for name, (rws, sc) in marks.items():
        px = scale * sc
        h, w = len(rws), max(len(r) for r in rws)
        im = Image.new("RGBA", (int(w * px), int(h * px)), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        for y, r in enumerate(rws):
            for x, ch in enumerate(r):
                if ch in PALETTE:
                    d.rectangle([int(x * px), int(y * px), int((x + 1) * px) - 1, int((y + 1) * px) - 1], fill=PALETTE[ch])
        blocks.append((name, im))
    W = 40 + max(b.width for _, b in blocks) + 140
    H = sum(max(b.height, 30) + 16 for _, b in blocks) + 16
    for bg_name, bg in (("dark", (24, 14, 30)), ("light", (236, 226, 240))):
        canvas = Image.new("RGBA", (W, H), bg + (255,))
        y = 12
        d = ImageDraw.Draw(canvas)
        for name, b in blocks:
            hh = max(b.height, 30)
            canvas.alpha_composite(b, (20, y + (hh - b.height) // 2))
            d.text((W - 130, y + hh // 2 - 6), name, fill=(150, 150, 150, 255))
            y += hh + 16
        canvas = canvas.resize((W * 2, H * 2), Image.NEAREST)
        canvas.save(out.replace(".png", "-" + bg_name + ".png"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pixeloid", default="~/.local/share/fonts/pixel")
    ap.add_argument("--jacquard", required=True, help="Jacquard24-Regular.ttf")
    ap.add_argument("--preview")
    ap.add_argument("--js", action="store_true", help="print the wordmarks block for Logos.js")
    a = ap.parse_args()
    import os
    pdir = os.path.expanduser(a.pixeloid)
    bold = os.path.join(pdir, "PixeloidSans-Bold.ttf")
    marks = {"windose": windose(bold), "hell": hell(a.jacquard), "chrome": chrome(bold)}
    if a.preview:
        preview(marks, a.preview, os.path.join(pdir, "PixeloidSans.ttf"))
    if a.js:
        for name, (rws, sc) in marks.items():
            print(f"    {name}: {{\n        scale: {sc},\n        rows: [")
            print(",\n".join("            " + json.dumps(r) for r in rws))
            print("        ]\n    },")
    else:
        for name, (rws, sc) in marks.items():
            print(name, len(rws), "×", max(map(len, rws)), "scale", sc)


if __name__ == "__main__":
    main()
