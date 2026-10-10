#!/usr/bin/env python3
"""Jacquard 12 + Cyrillic → "Jacquard 12 Hell" (OFL 1.1 derivative; Jacquard has no
Reserved Font Name). The Cyrillic is drawn as pixel bitmaps on the font's own grid
(cyr_glyphs.py) and traced into outlines here.

  build.py SRC.ttf OUT.ttf
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.recordingPen import RecordingPen
import cyr_glyphs as C

U = 60          # one pixel of the font, in font units
TOP = 14        # the first row of a bitmap is y = TOP


def grid(rows):
    """{(x, y)} of inked pixels; rows from y = TOP down."""
    ink = set()
    for i, row in enumerate(rows):
        y = TOP - i
        for x, ch in enumerate(row):
            if ch == '#':
                ink.add((x, y))
    return ink


def trace(ink):
    """Outlines of a set of pixels: clockwise outer contours, counter-clockwise holes
    (TrueType's rule), corners only."""
    out = {}
    def edge(a, b):
        out.setdefault(a, []).append(b)
    for (x, y) in ink:
        if (x, y + 1) not in ink:
            edge((x, y + 1), (x + 1, y + 1))
        if (x + 1, y) not in ink:
            edge((x + 1, y + 1), (x + 1, y))
        if (x, y - 1) not in ink:
            edge((x + 1, y), (x, y))
        if (x - 1, y) not in ink:
            edge((x, y), (x, y + 1))
    loops = []
    while out:
        start = next(iter(out))
        loop = [start]
        cur = start
        prev_dir = None
        while True:
            nexts = out.get(cur)
            if not nexts:
                break
            if len(nexts) > 1 and prev_dir is not None:
                # at a pinch (two pixels touching by a corner): turn right first
                def turn(n):
                    d = (n[0] - cur[0], n[1] - cur[1])
                    cross = prev_dir[0] * d[1] - prev_dir[1] * d[0]
                    return 0 if cross < 0 else (1 if cross == 0 else 2)
                nexts.sort(key=turn)
            nxt = nexts.pop(0)
            if not nexts:
                del out[cur]
            prev_dir = (nxt[0] - cur[0], nxt[1] - cur[1])
            cur = nxt
            if cur == start:
                break
            loop.append(cur)
        # drop the points in the middle of straight runs
        pts = []
        n = len(loop)
        for i in range(n):
            a, b, c = loop[i - 1], loop[i], loop[(i + 1) % n]
            if (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]) != 0:
                pts.append(b)
        if len(pts) >= 3:
            loops.append(pts)
    return loops


def glyph_from(ink, glyphset=None):
    pen = TTGlyphPen(glyphset)
    for loop in trace(ink):
        pen.moveTo((loop[0][0] * U, loop[0][1] * U))
        for p in loop[1:]:
            pen.lineTo((p[0] * U, p[1] * U))
        pen.closePath()
    return pen.glyph()


def raster(font, name):
    """The pixels of an existing glyph (its outlines sit on the 60-unit grid)."""
    gs = font.getGlyphSet()
    rec = RecordingPen()
    gs[name].draw(rec)
    contours, cur = [], []
    for op, args in rec.value:
        if op == 'moveTo':
            cur = [args[0]]
        elif op in ('lineTo', 'qCurveTo', 'curveTo'):
            cur.extend(args)
        elif op in ('closePath', 'endPath'):
            if cur:
                contours.append(cur)
            cur = []
    ink = set()
    adv = font['hmtx'][name][0] // U
    for y in range(-5, 17):
        for x in range(0, adv + 2):
            px, py = x * U + U / 2, y * U + U / 2
            w = 0
            for c in contours:
                for i in range(len(c)):
                    (x1, y1), (x2, y2) = c[i], c[(i + 1) % len(c)]
                    if y1 <= py < y2 or y2 <= py < y1:
                        if x1 + (py - y1) * (x2 - x1) / (y2 - y1) > px:
                            w += 1 if y2 > y1 else -1
            if w:
                ink.add((x, y))
    return ink, adv


def main(src, dst):
    f = TTFont(src)
    cmap = f.getBestCmap()
    order = f.getGlyphOrder()
    glyf, hmtx = f['glyf'], f['hmtx']
    new_cmap = {}

    def add(name, ink, adv):
        g = glyph_from(ink)
        glyf[name] = g
        g.recalcBounds(glyf)
        hmtx[name] = (adv * U, g.xMin if hasattr(g, 'xMin') else 0)
        if name not in order:
            order.append(name)

    drawn = dict(C.LOWER)
    drawn.update(C.UPPER)
    for ch, rows in drawn.items():
        rows = C.pad(rows)
        name = 'uni%04X' % ord(ch)
        add(name, grid(rows), len(rows[0]))
        new_cmap[ord(ch)] = name
    for ch, lat in C.SAME.items():
        new_cmap[ord(ch)] = cmap[ord(lat)]
    for ch, (lat, dots, y0) in C.DOTTED.items():
        ink, adv = raster(f, cmap[ord(lat)])
        for i, row in enumerate(dots):
            for x, c in enumerate(row):
                if c == '#':
                    ink.add((x, y0 - i))
        name = 'uni%04X' % ord(ch)
        add(name, ink, adv)
        new_cmap[ord(ch)] = name
    if C.NUMERO:
        rows = C.pad(C.NUMERO)
        add('uni2116', grid(rows), len(rows[0]))
        new_cmap[0x2116] = 'uni2116'

    f.setGlyphOrder(order)
    for t in f['cmap'].tables:
        if t.isUnicode():
            t.cmap.update(new_cmap)
    for tag in ('hdmx', 'LTSH', 'VDMX'):
        if tag in f:
            del f[tag]
    f['maxp'].numGlyphs = len(order)
    name = f['name']
    family = "Jacquard 12 Hell"
    for rec in list(name.names):
        if rec.nameID in (1, 16):
            name.setName(family, rec.nameID, rec.platformID, rec.platEncID, rec.langID)
        elif rec.nameID == 4:
            name.setName(family + " Regular", 4, rec.platformID, rec.platEncID, rec.langID)
        elif rec.nameID == 6:
            name.setName("Jacquard12Hell-Regular", 6, rec.platformID, rec.platEncID, rec.langID)
        elif rec.nameID == 3:
            name.setName("1.002;angelOS;Jacquard12Hell-Regular", 3, rec.platformID, rec.platEncID, rec.langID)
        elif rec.nameID == 0:
            name.setName(rec.toUnicode() + " Cyrillic: Copyright 2026 the angelOS contributors.", 0, rec.platformID, rec.platEncID, rec.langID)
        elif rec.nameID == 5:
            name.setName("Version 1.002; Cyrillic added for angelOS", 5, rec.platformID, rec.platEncID, rec.langID)
    f.save(dst)
    print("saved", dst, "glyphs", len(order), "new chars", len(new_cmap))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
