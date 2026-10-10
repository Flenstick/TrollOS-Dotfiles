#!/usr/bin/env python3
"""Windows 11 style "Bloom" wallpaper, drawn from scratch (no Microsoft artwork).

A ribbon flower of translucent folded petals over a soft gradient, dark or light.
    win11-bloom.py OUT.png [--light] [--size 3840x2160] [--hue 212]
--hue moves the whole picture around the colour wheel (212 = Windows blue).
"""
import argparse
import colorsys
import math

import numpy as np
from PIL import Image, ImageFilter


def hsv(h, s, v):
    return np.array(colorsys.hsv_to_rgb((h % 360) / 360, s, v), dtype=np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--light", action="store_true")
    ap.add_argument("--size", default="3840x2160")
    ap.add_argument("--hue", type=float, default=212)
    a = ap.parse_args()
    W, H = (int(v) for v in a.size.split("x"))
    hue = a.hue
    ss = 1  # supersample is done by drawing at full 4K
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    nx, ny = x / W, y / H

    # ---- background: soft diagonal gradient + a glow behind the flower ----
    if a.light:
        c0, c1 = hsv(hue - 6, 0.10, 0.99), hsv(hue + 4, 0.30, 0.93)
    else:
        c0, c1 = hsv(hue + 8, 0.80, 0.10), hsv(hue - 4, 0.85, 0.26)
    t = np.clip(0.55 * nx + 0.45 * ny, 0, 1)[..., None]
    img = c0 * (1 - t) + c1 * t
    cx, cy = 0.5 * W, 0.55 * H
    r = np.hypot((x - cx) / W, (y - cy) / H)[..., None]
    glow = np.exp(-(r / 0.28) ** 2)
    gcol = hsv(hue - 10, 0.55, 1.0) if not a.light else hsv(hue - 4, 0.35, 1.0)
    img = img + glow * (gcol - img) * (0.35 if not a.light else 0.45)

    # ---- petals: folded ribbons around the centre ----
    def petal(angle, length, width, bend, cA, cB, alpha):
        """A lens-shaped petal from the centre outwards, with a lengthwise gradient
        and a darker fold along one edge, like Bloom's folded fabric."""
        nonlocal img
        ca, sa = math.cos(angle), math.sin(angle)
        dx, dy = x - cx, y - cy
        u = (dx * ca + dy * sa) / length          # along the petal 0..1
        v = (-dx * sa + dy * ca) / length         # across
        v = v - bend * u * u                      # curve it
        half = width * np.maximum(np.sin(np.clip(u, 0, 1) * math.pi), 0) ** 0.8
        inside = (u > 0) & (u < 1) & (np.abs(v) < half)
        edge = np.clip((half - np.abs(v)) / (0.012 + 1e-6), 0, 1)
        m = (inside * edge).astype(np.float32)[..., None]
        k = np.clip(u, 0, 1)[..., None]
        col = cA * (1 - k) + cB * k
        # fold: one side darker, the crease bright
        side = np.clip((v / np.maximum(half, 1e-4) + 1) / 2, 0, 1)[..., None]
        shade = 0.72 + 0.38 * side
        crease = np.exp(-((v / np.maximum(half, 1e-4) - 0.15) / 0.12) ** 2)[..., None] * 0.25
        col = np.clip(col * shade + crease, 0, 1)
        img = img * (1 - m * alpha) + col * (m * alpha)

    n = 9
    base = min(W, H)
    for layer in range(2):
        for i in range(n):
            ang = -math.pi / 2 + (i - (n - 1) / 2) * (math.pi * 1.15 / n) + layer * 0.17
            ln = base * (0.62 if layer == 0 else 0.48) * (1 - 0.08 * abs(i - (n - 1) / 2) / n)
            hA = hue - 18 + i * 3 + layer * 8
            if a.light:
                cA, cB = hsv(hA, 0.85, 0.80), hsv(hA - 10, 0.35, 1.0)
            else:
                cA, cB = hsv(hA, 0.95, 0.55), hsv(hA - 14, 0.45, 1.0)
            petal(ang, ln, 0.20 if layer == 0 else 0.16, 0.10 * (1 if i % 2 else -1), cA, cB, 0.80 if layer == 0 else 0.70)
    # a few petals hanging down for the lower half of the bloom
    for i in range(5):
        ang = math.pi / 2 + (i - 2) * 0.42
        hA = hue - 6 + i * 4
        cA, cB = (hsv(hA, 0.9, 0.45), hsv(hA - 8, 0.6, 0.85)) if not a.light else (hsv(hA, 0.8, 0.75), hsv(hA - 8, 0.3, 1.0))
        petal(ang, base * 0.30, 0.18, 0.08 * (1 if i % 2 else -1), cA, cB, 0.55)

    out = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB")
    out = out.filter(ImageFilter.GaussianBlur(radius=max(1, W / 1600)))
    # a hair of noise against banding
    noise = (np.random.default_rng(7).normal(0, 1.4, (H, W, 1))).astype(np.float32)
    arr = np.clip(np.asarray(out).astype(np.float32) + noise, 0, 255).astype(np.uint8)
    Image.fromarray(arr, "RGB").save(a.out, optimize=True)
    print(a.out)


if __name__ == "__main__":
    main()
