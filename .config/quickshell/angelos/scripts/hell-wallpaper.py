#!/usr/bin/env python3
"""The demon's wallpaper (Settings → Y2K → Angel or demon).

  hell-wallpaper.py <dir> [WxH …] [--pack DIR …] [--cache DIR] [--repo OWNER/NAME] [--drawn]
                    [--prefer NAME …]
      prints JSON {"ok", "files": {"WxH": path}, "source": "pack" | "drawn"}

Paintings first: the Hell pack of the wallpapers repo — pixel hell made from
public-domain paintings (Martin, Doré, Bosch; each circle its own pair from Doré's
Inferno). It is looked for in every --pack dir (the installer puts it into
~/Pictures/Hell) and in --cache, all of them together; if none has it, the Hell folder
of --repo is downloaded into --cache once. Every screen size gets a picture of its own
orientation (portrait screens: the tall ones): one of the --prefer names (the circle's
own pair, story/circles.json → backdrop.pictures: "hell-limbo", "hell-limbo-portrait"…)
— a preferred one an older pack lacks is fetched alone into --cache (not more often than
once a day while it can't be had) — or a random one otherwise.

Drawn, with --drawn or when there is no pack and no network: drawn at 1/6 of the
size and scaled up without smoothing — a dithered night sky, a cracked
broken-heart moon, bats, two ridges of mountains with glowing seams and a lava
lake with flames and embers, written to <dir>/hell-<W>x<H>.png. Deterministic,
dark enough to sit behind the dark theme.
"""
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def dither(c1, c2, t, x, y):
    """Ordered dither between two colours: retro gradient bands."""
    steps = 4
    v = t * steps
    lo = min(steps - 1, int(v))
    frac = v - lo
    a = lerp(c1, c2, lo / steps)
    b = lerp(c1, c2, (lo + 1) / steps)
    return b if frac * 16 > BAYER[y % 4][x % 4] else a


def heart(cx, cy, r, x, y):
    # implicit heart: (x²+y²−1)³ − x²y³ ≤ 0, scaled
    u = (x - cx) / r
    v = (cy - y) / r + 0.25
    return (u * u + v * v - 1) ** 3 - u * u * v ** 3 <= 0


def draw(w, h, seed=666):
    rnd = random.Random(seed)
    img = Image.new("RGB", (w, h))
    px = img.load()
    portrait = h > w
    horizon = int(h * (0.72 if not portrait else 0.8))
    sky = [(6, 2, 10), (22, 4, 18), (58, 8, 22), (96, 14, 24)]
    for y in range(h):
        t = y / max(1, horizon)
        band = min(len(sky) - 2, int(t * (len(sky) - 1)))
        tt = t * (len(sky) - 1) - band
        for x in range(w):
            px[x, y] = dither(sky[band], sky[band + 1], max(0.0, min(1.0, tt)), x, y) if y < horizon else sky[-1]

    # stars, mostly dim red
    for _ in range(int(w * h / 160)):
        x, y = rnd.randrange(w), rnd.randrange(int(horizon * 0.8))
        px[x, y] = rnd.choice([(90, 30, 50), (140, 50, 70), (200, 120, 140)])

    # the moon: a big cracked heart
    mr = int(min(w, h) * (0.13 if not portrait else 0.16))
    mx, my = (int(w * 0.72), int(h * 0.24)) if not portrait else (int(w * 0.62), int(h * 0.2))
    crack = [(mx - int(mr * 0.1) + int(math.sin(i * 1.7) * mr * 0.12), my - mr + i) for i in range(int(mr * 2.2))]
    crack_x = {y: x for x, y in crack}
    for y in range(my - 2 * mr, my + 2 * mr):
        for x in range(mx - 2 * mr, mx + 2 * mr):
            if 0 <= x < w and 0 <= y < h and heart(mx, my, mr, x, y):
                edge = not heart(mx, my, mr * 0.9, x, y)
                base = (150, 20, 44) if not edge else (215, 60, 90)
                if y in crack_x and abs(x - crack_x[y]) <= 0:
                    base = (20, 4, 10)
                if (x * 7 + y * 13) % 29 == 0:
                    base = (120, 14, 36)
                px[x, y] = base
    # glow around it
    for y in range(max(0, my - 3 * mr), min(h, my + 3 * mr)):
        for x in range(max(0, mx - 3 * mr), min(w, mx + 3 * mr)):
            d = math.hypot(x - mx, y - my) / mr
            if 1.2 < d < 2.6 and not heart(mx, my, mr, x, y) and BAYER[y % 4][x % 4] < (2.6 - d) * 4:
                r, g, b = px[x, y]
                px[x, y] = (min(255, r + 26), g + 4, b + 10)

    # bats
    for _ in range(5 if not portrait else 4):
        bx, by = rnd.randrange(int(w * 0.1), int(w * 0.9)), rnd.randrange(int(h * 0.08), int(horizon * 0.55))
        for dx, dy in ((-2, -1), (-1, 0), (0, 0), (1, 0), (2, -1), (0, 1)):
            if 0 <= bx + dx < w and 0 <= by + dy < h:
                px[bx + dx, by + dy] = (8, 2, 8)

    # two ridges of mountains; the near one has glowing seams
    def ridge(base_y, rough, color, seam):
        y = base_y
        heights = []
        for x in range(w):
            y += rnd.choice((-1, 0, 0, 1)) * rough
            if rnd.random() < 0.04:
                y -= rnd.randrange(2, 6) * rough
            y = max(int(h * 0.35), min(horizon + 4, y))
            heights.append(y)
            for yy in range(y, h):
                px[x, yy] = color
        if seam:
            for _ in range(int(w / 7)):
                x = rnd.randrange(w)
                yy = heights[x] + rnd.randrange(2, 8)
                for k in range(rnd.randrange(3, 10)):
                    if 0 <= x < w and yy < h:
                        px[x, yy] = (255, 90, 30) if k % 3 else (255, 180, 60)
                    x += rnd.choice((-1, 0, 1))
                    yy += 1
        return heights

    ridge(int(horizon * 0.74), 1, (38, 8, 22), False)
    ridge(int(horizon * 0.88), 1, (16, 3, 11), True)

    # the lava lake
    lake = horizon + int((h - horizon) * 0.55)
    for y in range(lake, h):
        t = (y - lake) / max(1, h - lake)
        for x in range(w):
            c = dither((190, 52, 20), (70, 8, 12), t, x, y)
            if (x + y * 3 + int(math.sin(x / 5.0 + y) * 4)) % 23 == 0:
                c = (235, 120, 50)
            px[x, y] = c
    # flames along the shore
    x = 0
    while x < w:
        fh = rnd.randrange(2, 8 if not portrait else 10)
        fw = rnd.randrange(2, 5)
        for k in range(fh):
            half = max(0, int(fw * (1 - k / fh)))
            for dx in range(-half, half + 1):
                xx, yy = x + dx, lake - k
                if 0 <= xx < w and 0 <= yy < h:
                    px[xx, yy] = (245, 170, 60) if abs(dx) < half / 2 and k < fh * 0.6 else (200, 50, 24)
        x += rnd.randrange(3, 9)
    # embers
    for _ in range(int(w * h / 170)):
        y = int(lake - abs(rnd.gauss(0, (lake - h * 0.45) / 3.0)))
        x = rnd.randrange(w)
        if 0 <= y < h:
            px[x, y] = rnd.choice([(230, 110, 40), (255, 170, 70), (170, 40, 26)])
    return img


PICTURE = (".png", ".jpg", ".jpeg", ".webp")


def pack_pictures(dirs):
    """(path, portrait) for every picture in the pack folders together (a name in an
    earlier folder wins: the installed pack before the cache)"""
    found, seen = [], set()
    for d in dirs:
        d = Path(d).expanduser()
        if not d.is_dir():
            continue
        for f in sorted(d.iterdir()):
            if f.suffix.lower() in PICTURE and f.stem not in seen:
                try:
                    with Image.open(f) as im:
                        found.append((str(f), im.height > im.width))
                        seen.add(f.stem)
                except OSError:
                    pass
    return found


def fetch_named(repo, cache, names):
    """the circle's own pictures an older pack lacks: fetched alone into the cache; a name
    that can't be had now (offline, not in the repo) is tried again a day later"""
    import time
    import urllib.request
    cache = Path(cache).expanduser()
    cache.mkdir(parents=True, exist_ok=True)
    got = False
    for name in names:
        dst, miss = cache / (name + ".png"), cache / (".missing-" + name)
        if dst.exists() or (miss.exists() and time.time() - miss.stat().st_mtime < 86400):
            continue
        try:
            url = f"https://raw.githubusercontent.com/{repo}/main/Hell/{name}.png"
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "angelOS"}), timeout=15) as r:
                tmp = dst.with_suffix(".png.part")
                tmp.write_bytes(r.read())
                tmp.replace(dst)
                got = True
        except Exception:
            miss.touch()
    return got


def fetch_pack(repo, cache):
    """the Hell folder of the wallpapers repo → cache (a few hundred KB)"""
    import urllib.request
    cache = Path(cache).expanduser()
    cache.mkdir(parents=True, exist_ok=True)
    head = {"User-Agent": "angelOS", "Accept": "application/vnd.github+json"}
    req = urllib.request.Request(f"https://api.github.com/repos/{repo}/contents/Hell", headers=head)
    with urllib.request.urlopen(req, timeout=15) as r:
        items = json.load(r)
    for it in items:
        if it.get("type") == "file" and Path(it["name"]).suffix.lower() in PICTURE and it.get("download_url"):
            dst = cache / it["name"]
            if dst.exists() and dst.stat().st_size == it.get("size"):
                continue
            with urllib.request.urlopen(urllib.request.Request(it["download_url"], headers={"User-Agent": "angelOS"}), timeout=30) as r:
                tmp = dst.with_suffix(dst.suffix + ".part")
                tmp.write_bytes(r.read())
                tmp.replace(dst)


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    out = Path(args.pop(0))
    packs, cache, repo, drawn, sizes, prefer = [], None, "MixaDoDs/PixelStreetArt_Wallpapers", False, [], []
    while args:
        a = args.pop(0)
        if a == "--pack":
            packs.append(args.pop(0))
        elif a == "--cache":
            cache = args.pop(0)
        elif a == "--repo":
            repo = args.pop(0)
        elif a == "--drawn":
            drawn = True
        elif a == "--prefer":
            prefer.append(args.pop(0))
        else:
            sizes.append(a)
    sizes = sizes or ["1920x1080", "1080x1920"]

    if not drawn:
        dirs = packs + ([cache] if cache else [])
        pics = pack_pictures(dirs)
        if not pics and cache:
            try:
                fetch_pack(repo, cache)
            except Exception:
                pass
            pics = pack_pictures(dirs)
        names = {Path(p).stem for p, _ in pics}
        if pics and cache and prefer and not all(n in names for n in prefer):
            if fetch_named(repo, cache, [n for n in prefer if n not in names]):
                pics = pack_pictures(dirs)
        if pics:
            made = {}
            for s in sizes:
                W, H = (int(v) for v in s.lower().split("x"))
                fit = [p for p, portrait in pics if portrait == (H > W)] or [p for p, _ in pics]
                own = [p for p in fit if Path(p).stem in prefer]
                made[s] = own[0] if own else random.choice(fit)
            print(json.dumps({"ok": True, "files": made, "source": "pack"}))
            return

    out.mkdir(parents=True, exist_ok=True)
    made = {}
    for s in sizes:
        W, H = (int(v) for v in s.lower().split("x"))
        scale = 6 if max(W, H) <= 2560 else 8
        small = draw(max(40, W // scale), max(40, H // scale))
        path = out / f"hell-{W}x{H}.png"
        small.resize((W, H), Image.NEAREST).save(path)
        made[s] = str(path)
    print(json.dumps({"ok": True, "files": made, "source": "drawn"}))


if __name__ == "__main__":
    main()
