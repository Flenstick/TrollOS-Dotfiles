#!/usr/bin/env python3
"""The Steam client in angelOS's colours, heaven and hell and every circle (a Millennium
theme; entry "steam" of templates/templates.json).

  steam-theme.py build PALETTE.json   write the theme for the palette (realm, circle, mode)
                                      and put it where Millennium looks for themes
  steam-theme.py apply                make it Millennium's active theme (Steam closed; its
                                      config is backed up once)
  steam-theme.py status               what is set up, as JSON

Nothing happens without Millennium (https://steambrew.app): angelOS installs neither Steam
nor Millennium. Millennium 3.x keeps its themes in <Steam>/millennium/themes/<name>/ with a
skin.json (its src/system/filesystem.cc: get_millennium_path() = the Steam folder +
"millennium"); the theme "angelOS" is written to ~/.local/share/angelos/steam/angelOS and
copied there — into each Steam found (the native one, the Flatpak one). A folder "angelOS"
there that angelOS did not write (no .angelos mark) is left alone.

How it follows: data/steam/angelos.js (Millennium loads it into every Steam window)
recolours Steam's own stylesheets by what each colour is — greys onto angelOS's surfaces and
text by brightness, blues onto the accent, greens onto "ok", reds onto "danger" — as
--ao-* variables, and fetches colors.json, the variables' values, every few seconds. So a new
palette, the light or dark mode, the demon's hell and its circles reach an open Steam on the
fly; the store and the community are other sites and only take the colours on their next
page (webkit.css, written with them).
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
SHELL = Path(__file__).resolve().parent.parent
SRC = SHELL / "data/steam"
BASE = HOME / ".local/share/angelos/steam/angelOS"
NAME = "angelOS"
MARK = ".angelos"
STEAMS = [HOME / ".local/share/Steam", HOME / ".steam/steam",
          HOME / ".var/app/com.valvesoftware.Steam/.local/share/Steam"]
CONFIG = Path(os.environ.get("MILLENNIUM__CONFIG_PATH") or HOME / ".config/millennium") / "config.json"
STATIC = ["skin.json", "angelos.css", "angelos.js"]


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def hexa(c):
    return "#" + "".join("%02x" % max(0, min(255, round(v * 255))) for v in c)


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def colours(pal):
    """The --ao-* variables: s0…s7 the ramp Steam's greys land on (dark to light as Steam
    sees them), the accent and its lighter text, ok and danger, and a few names for the CSS."""
    hell = pal.get("realm") == "hell" and pal.get("hell")
    if hell:
        h = {k: rgb(v) for k, v in hell.items() if isinstance(v, str) and v.startswith("#")}
        ramp = [h["edge"], h["sunken"], h["body"], h["face"], h["faceAlt"], h["textDim"], h["text"],
                mix(h["text"], (1, 1, 1), 0.35)]
        accent, accent_text = h["accent"], mix(h["accent"], h["text"], 0.35)
        # Steam's reds are warnings to read: the circle's accent, deepened by its blood
        ok, danger = h["ok"], mix(h["accent"], h["blood"], 0.3)
        on_accent = h["text"] if lum(accent) < 0.55 else h["body"]
        dark = True
    else:
        p = {k: rgb(v) for k, v in pal.items() if isinstance(v, str) and len(v) == 7 and v.startswith("#")}
        dark = pal.get("mode") != "light"
        text = p.get("text", rgb("#fafafa" if dark else "#2a1a22"))
        accent = p.get("accent", rgb("#ff5cad"))
        if dark:
            ramp = [mix(p["desk"], (0, 0, 0), 0.45), p["desk"], p["face"], p["faceAlt"], p.get("hi", p["faceAlt"]),
                    p["textDim"], text, mix(text, (1, 1, 1), 0.5)]
            accent_text = p.get("accent2", mix(accent, text, 0.35))
        else:
            # Steam is dark: in a light palette its dark grounds become the light surfaces and
            # its light text the dark ink
            ramp = [p["face"], p["desk"], p["faceAlt"], mix(p["faceAlt"], p.get("hi", p["faceAlt"]), 0.5),
                    p.get("hi", p["faceAlt"]), p["textDim"], text, mix(text, (0, 0, 0), 0.3)]
            accent_text = mix(accent, text, 0.3)
        ok, danger = p.get("ok", rgb("#57e3a2")), p.get("danger", rgb("#ff4f6d"))
        on_accent = p.get("selectText", ramp[1]) if lum(accent) > 0.62 else rgb("#ffffff")
    out = {"s%d" % i: hexa(c) for i, c in enumerate(ramp)}
    out.update({
        "accent": hexa(accent), "accentText": hexa(accent_text), "onAccent": hexa(on_accent),
        "ok": hexa(ok), "danger": hexa(danger),
        "desk": out["s1"], "line": out["s4"], "text": out["s6"],
        "realm": "hell" if hell else "heaven", "mode": "dark" if dark else "light",
    })
    if hell:
        out["circle"] = pal["hell"].get("circle", "")
    return out


def css(c):
    names = {k: v for k, v in c.items() if isinstance(v, str) and v.startswith("#")}
    return ":root {\n" + "".join("    --ao-%s: %s;\n" % kv for kv in sorted(names.items())) + "}\n"


def webkit(c):
    """The store and the community: other sites, so only the frame — the page's ground, its
    links, the selection and the scrollbars — in the palette's colours, written as they are."""
    return (
        "/* angelOS for Steam (scripts/steam-theme.py): written for every palette */\n"
        + css(c)
        + "::selection { background: %s; color: %s; }\n" % (c["accent"], c["onAccent"])
        + "::-webkit-scrollbar-track { background: %s !important; }\n" % c["desk"]
        + "::-webkit-scrollbar-thumb { background: %s !important; border-radius: 0 !important; }\n" % c["line"]
        + "body { background-color: %s !important; }\n" % c["s1"]
    )


def write(path, text):
    """Write when it changed (Millennium and Steam are told nothing; angelos.js polls)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_file() and path.read_text() == text:
        return False
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)
    return True


def steams():
    """Each Steam with Millennium in it: <Steam>/millennium (or Millennium installed system-wide
    for a Steam that has not started with it yet)."""
    system = Path("/usr/lib/millennium").is_dir()
    seen, out = set(), []
    for s in STEAMS:
        try:
            real = s.resolve()
        except OSError:
            continue
        if real in seen or not (real / "steamui").is_dir():
            continue
        seen.add(real)
        if (real / "millennium").is_dir() or system:
            out.append(real)
    return out


def install(steam):
    """Copy the theme into <Steam>/millennium/themes/angelOS; never over someone else's."""
    dest = steam / "millennium/themes" / NAME
    if dest.exists() and not (dest / MARK).exists():
        return "skipped: %s is not angelOS's" % dest
    dest.mkdir(parents=True, exist_ok=True)
    (dest / MARK).write_text("written by angelOS (scripts/steam-theme.py)\n")
    changed = 0
    for f in BASE.iterdir():
        if f.is_file() and (not (dest / f.name).is_file() or (dest / f.name).read_bytes() != f.read_bytes()):
            shutil.copyfile(f, dest / f.name)
            changed += 1
    return "%s (%d changed)" % (dest, changed)


def build(palette_file):
    pal = json.loads(Path(palette_file).read_text())
    c = colours(pal)
    for name in STATIC:
        write(BASE / name, (SRC / name).read_text())
    write(BASE / "colors.json", json.dumps(c, indent=1) + "\n")
    write(BASE / "colors.css", css(c))
    write(BASE / "webkit.css", webkit(c))
    write(BASE / MARK, "written by angelOS (scripts/steam-theme.py)\n")
    found = steams()
    if not found:
        print("steam: no Millennium — the theme waits in", BASE)
        return
    for s in found:
        print("steam:", install(s))


def steam_running():
    return subprocess.run(["pgrep", "-x", "steam"], capture_output=True).returncode == 0


def apply():
    """Millennium's active theme := angelOS. Millennium rewrites its config while Steam runs,
    so only with Steam closed; the config is backed up once (config.json.angelos-before)."""
    if not steams():
        return {"ok": False, "error": "no Millennium"}
    if steam_running():
        return {"ok": False, "error": "steam running"}
    try:
        cfg = json.loads(CONFIG.read_text())
    except (OSError, ValueError):
        return {"ok": False, "error": "no Millennium config"}
    backup = CONFIG.with_name("config.json.angelos-before")
    if not backup.exists():
        shutil.copy2(CONFIG, backup)
    cfg.setdefault("themes", {})["activeTheme"] = NAME
    tmp = CONFIG.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cfg, indent=4) + "\n")
    tmp.replace(CONFIG)
    return {"ok": True}


def status():
    found = steams()
    try:
        active = json.loads(CONFIG.read_text()).get("themes", {}).get("activeTheme", "")
    except (OSError, ValueError):
        active = ""
    return {
        "millennium": bool(found),
        "steam": [str(s) for s in found],
        "installed": [str(s / "millennium/themes" / NAME) for s in found
                      if (s / "millennium/themes" / NAME / MARK).exists()],
        "active": active == NAME,
        "theme": str(BASE),
        "running": steam_running(),
    }


def main():
    args = sys.argv[1:]
    if args[:1] == ["build"] and len(args) > 1:
        build(args[1])
    elif args[:1] == ["apply"]:
        print(json.dumps(apply()))
    elif args[:1] == ["status"]:
        print(json.dumps(status()))
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
