#!/usr/bin/env python3
"""TrollOS: what a desktop layout (Settings → Макеты, services/DesktopPresets) builds in its colours.

  preset-assets.py cursor THEME PRIMARY SECONDARY BORDER
        the plain pixel cursor (pixel-cursors, as angelOS Pixel) recoloured
        → ~/.local/share/icons/THEME (scripts/cursors.py builds it; the source is cached)
  preset-assets.py icons NAME RAMP
        Pixora with every colour of its SVGs mapped by lightness onto RAMP (a JSON list of
        [stop 0..1, "#rrggbb"], dark to light) → ~/.local/share/icons/pixora-NAME
        (Inherits as pixora-dark; folder-tint.py tints the folders over it)
  preset-assets.py icon-theme NAME
        GTK (settings.ini, gsettings) and qt5ct/qt6ct take icon theme NAME; the folders are
        rebuilt over it on the palette's next render
  preset-assets.py fonts [FAMILY…]
        the Material You look's fonts, downloaded when fontconfig doesn't have them (Roboto Flex,
        Material Symbols Rounded/Outlined/Sharp; OFL / Apache 2.0, from Google's repositories)
        → ~/.local/share/fonts/angelos/material
  preset-assets.py md-icons SEED VARIANT MODE DARK
        «Material You» icons from Papirus (64x64: apps, places, mimetypes, devices, categories)
        → ~/.local/share/icons/MaterialYou. MODE themed: every colour onto the seed's primary
        tones by its lightness (Android's themed icons); colored: Papirus' colours, the folders
        in the primary. DARK 1|0 picks Papirus-Dark or Papirus(-Light) for the rest
  preset-assets.py seed-from IMAGE
        the Material You seed of a picture: its most colourful well-lit colour (#rrggbb)
  preset-assets.py icon-theme-status
        the icon theme in use now — its base: angelOS's tinted folders (angelos-folders-a/b,
        rebuilt under the other name on every render) stand for the Pixora under them

Prints "ok …" on success; anything else on stderr and exit 1. A theme already built with
the same colours is left as it is (a stamp file in it).
"""
import colorsys
import configparser
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HOME = Path.home()
ICONS = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share")) / "icons"
CONF = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
INIS = [CONF / "gtk-3.0/settings.ini", CONF / "gtk-4.0/settings.ini"]
QTS = [CONF / "qt5ct/qt5ct.conf", CONF / "qt6ct/qt6ct.conf"]
OUTLINE = "3e3546"          # Pixora's pixel outline


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), HERE / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def theme_dir(name):
    for d in (ICONS, HOME / ".icons", Path("/usr/share/icons")):
        if (d / name / "index.theme").is_file():
            return d / name
    return None


def stamped(d, want):
    s = d / ".trollos-preset"
    return (d / "index.theme").is_file() and s.is_file() and s.read_text() == want


# ---- the cursor ----
def cursor(theme, primary, secondary, border):
    want = f"{primary} {secondary} {border}"
    d = ICONS / theme
    if stamped(d, want):
        return f"ok cursor {theme} (already)"
    cur = load("cursors")
    cur.build_pixel({"id": theme.lower(), "theme": theme, "name": theme, "about": "TrollOS desktop layout cursor",
                     "build": "pixel", "palette": {"primary": primary, "secondary": secondary, "border": border}})
    if not (d / "index.theme").is_file():
        raise SystemExit(f"cursor {theme} was not built")
    (d / ".trollos-preset").write_text(want)
    return f"ok cursor {theme}"


# ---- the icons ----
def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def mapper(ramp):
    stops = [(float(p), hexrgb(c)) for p, c in ramp]
    outline = "%02x%02x%02x" % lerp(stops[0][1], stops[1][1], 0.5) if len(stops) > 1 else OUTLINE

    def at(l):
        for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
            if l <= p1:
                return lerp(c0, c1, (l - p0) / max(1e-6, p1 - p0))
        return stops[-1][1]

    def recolor(hexc):
        if hexc.lower() == OUTLINE:
            return outline
        r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4))
        return "%02x%02x%02x" % at(0.2126 * r + 0.7152 * g + 0.0722 * b)
    return recolor


def fix_svg(text, recolor):
    text = re.sub(r"#([0-9a-fA-F]{6})\b", lambda m: "#" + recolor(m.group(1)), text)
    return re.sub(r"#([0-9a-fA-F]{3})\b(?![0-9a-fA-F])", lambda m: "#" + recolor("".join(c * 2 for c in m.group(1))), text)


def icons(name, ramp_json):
    ramp = json.loads(ramp_json)
    want = json.dumps(ramp)
    dst = ICONS / f"pixora-{name}"
    if stamped(dst, want):
        return f"ok icons pixora-{name} (already)"
    src_theme = theme_dir("pixora")
    if not src_theme:
        raise SystemExit("Pixora is not installed (~/.local/share/icons/pixora)")
    src = src_theme / "scalable"
    recolor = mapper(ramp)
    tmp = dst.with_name(dst.name + ".part")
    shutil.rmtree(tmp, ignore_errors=True)
    for f in src.rglob("*"):
        out = tmp / "scalable" / f.relative_to(src)
        if f.is_symlink():
            out.parent.mkdir(parents=True, exist_ok=True)
            out.symlink_to(os.readlink(f))
        elif f.is_dir():
            out.mkdir(parents=True, exist_ok=True)
        elif f.suffix == ".svg":
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(fix_svg(f.read_text(errors="ignore"), recolor))
        else:
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, out)
    base = theme_dir("pixora-dark") or src_theme
    idx = (base / "index.theme").read_text()
    idx = re.sub(r"^Name=.*$", f"Name=Pixora {name.capitalize()}", idx, count=1, flags=re.M)
    idx = re.sub(r"^Comment=.*$", "Comment=Pixora recoloured for a TrollOS desktop layout (scripts/preset-assets.py)", idx, count=1, flags=re.M)
    (tmp / "index.theme").write_text(idx)
    (tmp / ".trollos-preset").write_text(want)
    shutil.rmtree(dst, ignore_errors=True)
    tmp.rename(dst)
    if shutil.which("gtk-update-icon-cache"):
        subprocess.run(["gtk-update-icon-cache", "-f", "-q", str(dst)], check=False)
    return f"ok icons pixora-{name}"


# ---- the fonts (the Material You look) ----
FONTS = {
    "Roboto Flex": "https://github.com/google/fonts/raw/main/ofl/robotoflex/RobotoFlex%5BGRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght%5D.ttf",
    "Material Symbols Rounded": "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf",
    "Material Symbols Outlined": "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsOutlined%5BFILL,GRAD,opsz,wght%5D.ttf",
    "Material Symbols Sharp": "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsSharp%5BFILL,GRAD,opsz,wght%5D.ttf",
}


def has_font(family):
    out = subprocess.run(["fc-list", ":family=" + family, "family"], capture_output=True, text=True).stdout
    return bool(out.strip())


def fonts(families):
    import urllib.request
    want = families or list(FONTS)
    dst = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share")) / "fonts/angelos/material"
    got = []
    for fam in want:
        if fam not in FONTS or has_font(fam):
            continue
        dst.mkdir(parents=True, exist_ok=True)
        out = dst / (fam.replace(" ", "") + ".ttf")
        req = urllib.request.Request(FONTS[fam], headers={"User-Agent": "angelOS"})
        with urllib.request.urlopen(req, timeout=60) as r:
            data = r.read()
        if len(data) < 10000 or data[:4] not in (b"\x00\x01\x00\x00", b"OTTO", b"true"):
            raise SystemExit(f"{fam}: not a font ({len(data)} bytes)")
        tmp = out.with_suffix(".part")
        tmp.write_bytes(data)
        tmp.rename(out)
        got.append(fam)
    if got and shutil.which("fc-cache"):
        subprocess.run(["fc-cache", "-f", str(dst)], check=False)
    return "ok fonts" + (" " + ", ".join(got) if got else " (all there)")


# ---- Material You: tones (CIELAB L* at a hue and chroma, cut to sRGB), as config/MaterialColor.js ----
def _lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _delin(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def _lab(rgb):
    r, g, b = (_lin(c) for c in rgb)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    fx, fy, fz = f(x), f(y), f(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def _lch_rgb(L, C, H):
    import math
    a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200
    fi = lambda t: t ** 3 if t ** 3 > 216 / 24389 else (116 * t - 16) / (24389 / 27)
    x, y, z = fi(fx) * 0.95047, (fy ** 3 if L > 8 else L / (24389 / 27)), fi(fz) * 1.08883
    r = 3.2406 * x - 1.5372 * y - 0.4986 * z
    g = -0.9689 * x + 1.8758 * y + 0.0415 * z
    bl = 0.0557 * x - 0.2040 * y + 1.0570 * z
    if min(r, g, bl) < -1e-4 or max(r, g, bl) > 1 + 1e-4:
        return None
    return tuple(_delin(max(0.0, min(1.0, c))) for c in (r, g, bl))


def tone(H, C, T):
    if T <= 0:
        return (0, 0, 0)
    if T >= 100:
        return (255, 255, 255)
    rgb = _lch_rgb(T, C, H)
    if rgb is None:
        lo, hi, rgb = 0.0, C, _lch_rgb(T, 0, H)
        for _ in range(16):
            mid = (lo + hi) / 2
            m = _lch_rgb(T, mid, H)
            if m:
                lo, rgb = mid, m
            else:
                hi = mid
    return tuple(round(c * 255) for c in rgb)


def seed_hc(seed, variant):
    import math
    L, a, b = _lab([int(seed.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)])
    h = math.degrees(math.atan2(b, a)) % 360
    c = math.hypot(a, b)
    return h, {"vibrant": max(c, 75), "expressive": 50, "neutral": 14, "monochrome": 0, "fidelity": max(c, 20)}.get(variant, 42), (h + 240) % 360 if variant == "expressive" else h


MD_DIRS = ("apps", "places", "mimetypes", "devices", "categories")


def md_icons(seed, variant, mode, dark):
    want = json.dumps([seed.lower(), variant, mode, dark])
    dst = ICONS / "MaterialYou"
    if stamped(dst, want):
        return "ok md-icons (already)"
    src = None
    for name in ("Papirus-Dark", "Papirus"):
        d = theme_dir(name)
        if d and (d / "64x64/apps").is_dir():
            src = d
            break
    if not src:
        raise SystemExit("Papirus is not installed (papirus-icon-theme)")
    h, c, hp = seed_hc(seed, variant)
    hp = h if variant != "expressive" else hp
    # the ramp a themed icon is drawn with: dark parts → a deep tone, light parts → a pale one
    lo_t, hi_t = (25, 92) if dark == "1" else (30, 95)
    cache = {}

    def themed(hexc):
        if hexc in cache:
            return cache[hexc]
        r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4))
        L = _lab((r, g, b))[0] / 100
        sat = max(r, g, b) - min(r, g, b)
        t = lo_t + (hi_t - lo_t) * L
        out = "%02x%02x%02x" % tone(hp, c * (0.55 + 0.6 * sat), t)
        cache[hexc] = out
        return out

    folder_cols = {}

    def folders(hexc):
        if hexc not in folder_cols:
            r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4))
            hh = colorsys.rgb_to_hls(r, g, b)
            # Papirus' blue folder body and its shades → the primary at the same lightness
            folder_cols[hexc] = "%02x%02x%02x" % tone(hp, c, _lab((r, g, b))[0]) if 0.5 < hh[0] < 0.7 and hh[2] > 0.15 else hexc
        return folder_cols[hexc]

    tmp = dst.with_name("MaterialYou.part")
    shutil.rmtree(tmp, ignore_errors=True)
    n = 0
    for ctx in MD_DIRS:
        sd = src / "64x64" / ctx
        if not sd.is_dir():
            sd = theme_dir("Papirus") / "64x64" / ctx
        od = tmp / "64x64" / ctx
        od.mkdir(parents=True, exist_ok=True)
        for f in sd.iterdir():
            o = od / f.name
            if f.is_symlink():
                o.symlink_to(os.readlink(f))
                continue
            if f.suffix != ".svg":
                continue
            t = f.read_text(errors="ignore")
            if mode == "themed":
                t = re.sub(r"#([0-9a-fA-F]{6})\b", lambda m: "#" + themed(m.group(1).lower()), t)
            elif ctx == "places" and f.name.startswith(("folder", "user-")):
                t = re.sub(r"#([0-9a-fA-F]{6})\b", lambda m: "#" + folders(m.group(1).lower()), t)
            o.write_text(t)
            n += 1
    base = "Papirus-Dark" if dark == "1" else "Papirus-Light" if theme_dir("Papirus-Light") else "Papirus"
    dirs = ",".join("64x64/" + d for d in MD_DIRS)
    ctxname = {"apps": "Applications", "places": "Places", "mimetypes": "MimeTypes", "devices": "Devices", "categories": "Categories"}
    idx = ["[Icon Theme]", "Name=Material You", "Comment=Papirus in the Material You scheme (TrollOS, scripts/preset-assets.py)",
           f"Inherits={base},breeze-dark,hicolor" if dark == "1" else f"Inherits={base},breeze,hicolor", f"Directories={dirs}", ""]
    for d in MD_DIRS:
        idx += [f"[64x64/{d}]", "Size=64", f"Context={ctxname[d]}", "Type=Scalable", "MinSize=8", "MaxSize=512", ""]
    (tmp / "index.theme").write_text("\n".join(idx))
    (tmp / ".trollos-preset").write_text(want)
    shutil.rmtree(dst, ignore_errors=True)
    tmp.rename(dst)
    if shutil.which("gtk-update-icon-cache"):
        subprocess.run(["gtk-update-icon-cache", "-f", "-q", str(dst)], check=False)
    return f"ok md-icons {mode} {n} icons"


def seed_from(path):
    from PIL import Image
    im = Image.open(path).convert("RGB")
    im.thumbnail((128, 128))
    q = im.quantize(colors=16, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()[:48]
    counts = sorted(q.getcolors(), reverse=True)
    best, score = "#6750a4", -1.0
    total = sum(c for c, _ in counts) or 1
    import math
    for n, i in counts:
        r, g, b = pal[i * 3:i * 3 + 3]
        L, a, bb = _lab((r / 255, g / 255, b / 255))
        ch = math.hypot(a, bb)
        sc = ch * (1 - abs(L - 55) / 70) * (0.35 + (n / total) ** 0.5)
        if sc > score:
            best, score = "#%02x%02x%02x" % (r, g, b), sc
    return best


# ---- the icon theme in use ----
def current():
    for ini in INIS:
        cp = configparser.ConfigParser(interpolation=None)
        try:
            cp.read(ini)
            v = cp.get("Settings", "gtk-icon-theme-name", fallback="")
        except configparser.Error:
            v = ""
        if v:
            return v
    return ""


def icon_theme(name):
    if not theme_dir(name):
        raise SystemExit(f"no icon theme {name}")
    ft = load("folder-tint")
    ft.set_theme(name)
    # the folders are rebuilt over the new base on the palette's next render
    (ICONS / ".angelos-folders").unlink(missing_ok=True)
    for qt in QTS:
        if qt.is_file():
            t = qt.read_text()
            n = re.sub(r"(?m)^icon_theme=.*$", f"icon_theme={name}", t)
            if n != t:
                qt.write_text(n)
    return f"ok icon-theme {name}"


def main():
    a = sys.argv[1:]
    try:
        if a[:1] == ["cursor"] and len(a) == 5:
            print(cursor(*a[1:]))
        elif a[:1] == ["icons"] and len(a) == 3:
            print(icons(a[1], a[2]))
        elif a[:1] == ["icon-theme"] and len(a) == 2:
            print(icon_theme(a[1]))
        elif a[:1] == ["md-icons"] and len(a) == 5:
            print(md_icons(*a[1:]))
        elif a[:1] == ["seed-from"] and len(a) == 2:
            print(seed_from(a[1]))
        elif a[:1] == ["fonts"]:
            print(fonts(a[1:]))
        elif a == ["icon-theme-status"]:
            print(load("folder-tint").base_of(current()) if current() else "")
        else:
            sys.exit(__doc__)
    except SystemExit:
        raise
    except Exception as e:  # noqa: BLE001 — one line for the page, not a trace
        print(f"{type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
