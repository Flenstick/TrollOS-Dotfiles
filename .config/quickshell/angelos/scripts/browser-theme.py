#!/usr/bin/env python3
"""Browsers in angelOS's colours, heaven and hell: Helium, Chromium, Firefox
(Settings → Windows → Browsers; entry "helium" of templates/templates.json builds the themes).

  browser-theme.py build PALETTE.json          write the static themes for the palette's realm
  browser-theme.py status                      every browser found, as JSON
  browser-theme.py apply ID [--restart|--wait] turn angelOS's look on in ID's profile
  browser-theme.py revert ID [--restart|--wait] put the profile back as it was before
  ID: helium, chromium or firefox

Two looks:
  live    the browser follows GTK — angelOS's GTK theme (scripts/gtk-live.py) switches live
          between heaven and hell, title bar buttons included. Helium and Chromium: their
          theme "GTK" (Settings → Appearance → Theme). Firefox: its "System theme — auto",
          the default one.
  static  a theme file for the current palette and realm, read when the browser starts:
          Chromium's theme extension ~/.local/share/angelos/helium/theme (helium://extensions
          → Developer mode → Load unpacked, once; Chromium can't load a theme by itself) and
          Firefox's userChrome.css (angelOS turns it on in the profile by `apply firefox`).

Profiles are touched only by `apply`/`revert` (a button in Settings), never by `build`.
Chromium writes its Preferences when it quits, so they are edited only while it is closed:
`--restart` closes it gently (SIGTERM: it saves the session and the prefs), edits, and opens
it again with --restore-last-session — the tabs come back; `--wait` leaves a waiter (a
transient systemd unit, up to 12 hours) that edits the moment the browser closes; with
neither, a running browser is only reported. Firefox never rewrites user.js or its chrome
folder, so its edits are made at once and count from its next start.
Before an edit: a full copy of each file into a new folder ~/.local/share/angelos/browsers/
backup-<id>-<time>/, and the values replaced go into <id>.undo.json — `revert` puts exactly
those back (whatever else changed in the profile meanwhile stays).
"""
import configparser
import hashlib
import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
DATA = HOME / ".local/share/angelos"
STATE = DATA / "browsers"
THEME = DATA / "helium/theme"                    # Chromium's theme extension (path kept: loaded copies point here)
FF_CSS = STATE / "firefox/angelos-theme.css"     # Firefox's userChrome part, linked into the profile
MARK_BEGIN, MARK_END = "angelOS begin", "angelOS end"

HELL = {
    "body": "#160609", "face": "#2a0b10", "faceAlt": "#3d1016", "sunken": "#0c0305",
    "edge": "#050102", "hi": "#6e1a21", "blood": "#b3142b", "ember": "#ff6a1a",
    "flame": "#ffb02e", "gold": "#d9a441", "text": "#f3d9c0", "textDim": "#a8857a",
}


def test_profile(name):
    """ANGELOS_BROWSER_<NAME>: a test profile instead of the real one (tests/browsers); empty =
    look it up as usual (Firefox's profiles.ini) but list the browser even if not installed."""
    v = os.environ.get("ANGELOS_BROWSER_" + name.upper())
    return None if v is None else (Path(v) if v else None)


def testing(bid):
    return ("ANGELOS_BROWSER_" + bid.upper()) in os.environ


def config_home(env):
    return Path(env.get("XDG_CONFIG_HOME") or (env.get("HOME") or str(HOME)) + "/.config")


BROWSERS = {
    "helium": {"name": "Helium", "kind": "chromium", "comm": "helium", "dir": "net.imput.helium",
               "bins": ["helium-browser", "/opt/helium-browser-bin/helium"]},
    "chromium": {"name": "Chromium", "kind": "chromium", "comm": "chromium", "dir": "chromium",
                 "bins": ["chromium", "/usr/lib/chromium/chromium"]},
    "firefox": {"name": "Firefox", "kind": "firefox", "comm": "firefox", "dir": None,
                "bins": ["firefox", "/usr/lib/firefox/firefox"]},
}
for _bid, _b in BROWSERS.items():
    _b["id"] = _bid
    _b["profile"] = test_profile(_bid) or (config_home(os.environ) / _b["dir"] if _b["dir"] else None)


# ── colours ──────────────────────────────────────────────────────────────────

def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return "#" + "".join("%02x" % round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def looks(p, hell):
    """The browser's parts in the palette's (or hell's) colours, as #rrggbb."""
    if hell:
        h = HELL
        return {
            "frame": mix(h["faceAlt"], h["blood"], 0.35), "frameInactive": h["face"],
            "incognito": h["body"], "incognitoInactive": h["sunken"],
            "tab": h["face"], "tabInactive": h["sunken"], "tabText": h["flame"], "tabTextDim": h["textDim"],
            "toolbar": h["face"], "text": h["text"], "icon": h["flame"],
            "field": h["sunken"], "desk": h["body"], "link": h["ember"], "accent": h["blood"],
            "button": h["faceAlt"], "edge": h["edge"], "select": h["blood"], "selectText": h["text"],
            "dark": True,
        }
    dark = p.get("mode") == "dark"
    return {
        "frame": mix(p["faceAlt"], p["accent"], 0.16 if dark else 0.10), "frameInactive": p["faceAlt"],
        "incognito": mix(p["desk"], "#000000", 0.4), "incognitoInactive": mix(p["desk"], "#000000", 0.5),
        "tab": p["faceAlt"], "tabInactive": p["faceAlt"], "tabText": p["text"], "tabTextDim": p["textDim"],
        "toolbar": p["face"], "text": p["text"], "icon": p["accent"],
        "field": p["sunken"], "desk": p["desk"], "link": p["accent"], "accent": p["accent"],
        "button": p["face"], "edge": p.get("edge", p["sunken"]),
        "select": p.get("select", p["accent"]), "selectText": p.get("selectText", p["desk"]),
        "dark": dark,
    }


def chromium_colors(c):
    return {
        "frame": rgb(c["frame"]), "frame_inactive": rgb(c["frameInactive"]),
        "frame_incognito": rgb(c["incognito"]), "frame_incognito_inactive": rgb(c["incognitoInactive"]),
        "background_tab": rgb(c["tab"]), "background_tab_inactive": rgb(c["tabInactive"]),
        "toolbar": rgb(c["toolbar"]), "toolbar_text": rgb(c["text"]),
        "toolbar_button_icon": rgb(c["icon"]),
        "tab_text": rgb(c["tabText"]), "tab_background_text": rgb(c["tabTextDim"]),
        "tab_background_text_inactive": rgb(c["tabTextDim"]),
        "bookmark_text": rgb(c["text"]),
        "omnibox_background": rgb(c["field"]), "omnibox_text": rgb(c["text"]),
        "ntp_background": rgb(c["desk"]), "ntp_text": rgb(c["text"]),
        "ntp_link": rgb(c["link"]), "ntp_header": rgb(c["accent"]),
        "button_background": rgb(c["button"]) + [1],
    }


def firefox_css(c, realm):
    """userChrome.css variables, Firefox 157's names and the older ones (ESR) side by side."""
    v = {
        "toolbox-background-color": c["frame"], "toolbox-background-color-inactive": c["frameInactive"],
        "toolbox-text-color": c["text"], "toolbox-text-color-inactive": c["tabTextDim"],
        "toolbox-bgcolor": c["frame"], "toolbox-bgcolor-inactive": c["frameInactive"], "toolbox-textcolor": c["text"],
        "lwt-accent-color": c["frame"], "lwt-text-color": c["text"],
        "toolbar-background-color": c["toolbar"], "toolbar-text-color": c["text"],
        "toolbar-bgcolor": c["toolbar"], "toolbar-color": c["text"],
        "tab-background-color-selected": c["toolbar"], "tab-text-color-selected": c["tabText"],
        "tab-selected-bgcolor": c["toolbar"], "tab-selected-textcolor": c["tabText"],
        "tab-text-color": c["tabTextDim"], "tab-loading-fill": c["accent"],
        "toolbar-field-background-color": c["field"], "toolbar-field-text-color": c["text"],
        "toolbar-field-background-color-focus": c["field"], "toolbar-field-text-color-focus": c["text"],
        "toolbar-field-border-color": c["edge"], "toolbar-field-border-color-focus": c["accent"],
        "toolbar-field-color": c["text"], "toolbar-field-focus-color": c["text"],
        "toolbar-field-focus-background-color": c["field"], "toolbar-field-focus-border-color": c["accent"],
        "toolbarbutton-icon-fill": c["icon"],
        "panel-background-color": c["toolbar"], "panel-text-color": c["text"], "panel-border-color": c["edge"],
        "arrowpanel-background": c["toolbar"], "arrowpanel-color": c["text"], "arrowpanel-border-color": c["edge"],
        "focus-outline-color": c["accent"],
        "urlbarView-highlight-background": c["select"], "urlbarView-highlight-color": c["selectText"],
        "sidebar-background-color": c["toolbar"], "sidebar-text-color": c["text"],
        "chrome-content-separator-color": c["edge"], "newtab-background-color": c["desk"],
    }
    body = "\n".join("  --%s: %s !important;" % kv for kv in v.items())
    scheme = "dark" if c["dark"] else "light"
    return ("/* angelOS — %s (browser-theme.py rewrites this file; Firefox reads it when it starts) */\n"
            ":root {\n  color-scheme: %s !important;\n%s\n}\n"
            "#navigator-toolbox { background-color: %s !important; color: %s !important; }\n"
            "#navigator-toolbox:-moz-window-inactive { background-color: %s !important; }\n"
            "#nav-bar, #PersonalToolbar { background-color: %s !important; color: %s !important; }\n"
            ".tab-background[selected] { background-color: %s !important; }\n"
            "menupopup, panel { --panel-background: %s !important; --panel-color: %s !important; }\n"
            % (realm, scheme, body, c["frame"], c["text"], c["frameInactive"], c["toolbar"], c["text"],
               c["toolbar"], c["toolbar"], c["text"]))


def write_text(path, text):
    """Write only when it changed; True if it did."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == text:
        return False
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)
    return True


def build(pal):
    hell = pal.get("realm") == "hell"
    realm = "hell" if hell else "heaven"
    c = looks(pal, hell)
    colors = chromium_colors(c)
    manifest = {
        "manifest_version": 3,
        "name": "angelOS",
        "version": "1.%d.%d" % (1 if hell else 0, int(hashlib.sha1(json.dumps(colors, sort_keys=True).encode()).hexdigest()[:6], 16) % 65535),
        "description": "angelOS — " + ("hell, while the demon rules" if hell else "heaven, the angelOS palette") + " (rewritten by angelOS; the browser reads it at start)",
        "theme": {"colors": colors, "properties": {"ntp_background_alignment": "bottom"}},
    }
    new = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
    changed = False
    if not (THEME / "manifest.json").exists() or (THEME / "manifest.json").read_text() != new:
        # Chromium caches a built theme next to an unpacked one: drop it so the new colours count
        for stale in THEME.glob("Cached Theme*.pak"):
            stale.unlink()
        changed = write_text(THEME / "manifest.json", new)
    changed = write_text(FF_CSS, firefox_css(c, realm)) or changed
    return changed, realm


# ── processes ────────────────────────────────────────────────────────────────

def installed(b):
    return any(shutil.which(x) or Path(x).exists() for x in b["bins"])


def main_pids(b):
    """The browser's own process for this profile, from the profile's lock: Chromium's
    SingletonLock → "host-PID", Firefox's lock → "IP:+PID". Only a live process of that browser
    counts (not a stale lock after a crash), and only this profile's — a test or a stand with
    a fake HOME never takes the person's browser for its own. (Not by name or environment:
    Chromium overwrites its environment with its process title.)"""
    prof = profile_dir(b)
    if prof is None:
        return []
    try:
        target = os.readlink(prof / ("SingletonLock" if b["kind"] == "chromium" else "lock"))
    except OSError:
        return []
    m = re.search(r"(\d+)$", target)
    if not m or (b["kind"] == "chromium" and target.rsplit("-", 1)[0] != socket.gethostname()):
        return []
    pid = int(m.group(1))
    try:
        comm = Path("/proc/%d/comm" % pid).read_text().strip()
    except OSError:
        return []
    return [pid] if comm in (b["comm"], b["comm"] + "-bin") and not zombie(pid) else []


def running(b):
    return bool(main_pids(b))


def close_gently(b, timeout=30):
    """SIGTERM: Chromium ends the session as at logout — tabs saved, Preferences written.
    Returns how it was started (its flags, not the pages it was given), or None if it stayed."""
    pids = main_pids(b)
    try:
        raw = [a for a in Path("/proc/%d/cmdline" % pids[0]).read_bytes().decode(errors="ignore").split("\0") if a]
    except (OSError, IndexError):
        raw = []
    # intact: its flags again (not the pages it was given); one string — Chromium rewrote it
    # into its process title, can't be split safely — then it starts the usual way (reopen)
    argv = raw[:1] + [a for a in raw[1:] if a.startswith("-") and a != "--restore-last-session"] if len(raw) > 1 else []
    for p in pids:
        try:
            os.kill(p, signal.SIGTERM)
        except OSError:
            pass
    end = time.time() + timeout
    while time.time() < end:
        if not any(Path("/proc/%d" % p).exists() and not zombie(p) for p in pids):
            time.sleep(0.5)                       # the last writes of its helpers
            return argv
        time.sleep(0.2)
    return None


def zombie(pid):
    try:
        return Path("/proc/%d/stat" % pid).read_text().rsplit(")", 1)[1].split()[0] == "Z"
    except (OSError, IndexError):
        return False


def reopen(b, argv):
    """Open the browser again with its tabs, the way it ran before, as the user's apps are
    opened (niri's spawn)."""
    if not argv:
        exe = next((x for x in b["bins"] if shutil.which(x) or Path(x).exists()), None)
        if not exe:
            return False
        argv = [exe]                              # the launcher: its flags file applies too
        if b["kind"] == "chromium":
            # always by path: the spawned browser may see another HOME (niri's) and would
            # otherwise hand the tabs to whatever browser runs there
            argv.append("--user-data-dir=" + str(b["profile"]))
    argv = argv + (["--restore-last-session"] if b["kind"] == "chromium" else [])
    if os.environ.get("ANGELOS_BROWSER_NO_REOPEN"):
        return True
    if os.environ.get("NIRI_SOCKET") and shutil.which("niri"):
        if subprocess.run(["niri", "msg", "action", "spawn", "--"] + argv, capture_output=True).returncode == 0:
            return True
    subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return True


# ── profiles ─────────────────────────────────────────────────────────────────

def firefox_profile():
    """The profile Firefox opens by default: the install's Default=, else the Default=1 one."""
    for root in (config_home(os.environ) / "mozilla/firefox", HOME / ".mozilla/firefox"):
        ini = root / "profiles.ini"
        if not ini.exists():
            continue
        cp = configparser.ConfigParser(interpolation=None)
        cp.optionxform = str
        try:
            cp.read(ini)
        except configparser.Error:
            continue
        pick = None
        for sec in cp.sections():
            if sec.startswith("Install") and cp[sec].get("Default"):
                pick = root / cp[sec]["Default"]
                break
        if pick is None:
            for sec in cp.sections():
                s = cp[sec]
                if sec.startswith("Profile") and s.get("Path") and (s.get("Default") == "1" or pick is None):
                    pick = (root / s["Path"]) if s.get("IsRelative", "1") == "1" else Path(s["Path"])
                    if s.get("Default") == "1":
                        break
        if pick and pick.is_dir():
            return pick
    return None


def profile_dir(b):
    if b["kind"] == "firefox":
        return b["profile"] or firefox_profile()
    return b["profile"]


def undo_file(bid):
    return STATE / (bid + ".undo.json")


def load_undo(bid, prof):
    """What apply replaced — only if it was this profile's (another one's record is no undo here)."""
    u = read_json(undo_file(bid), None)
    return u if u and prof is not None and u.get("profile") == str(prof) else None


def backup(bid, files):
    """A new folder each time (never into an old backup), the files that exist copied in."""
    d = STATE / ("backup-%s-%s" % (bid, time.strftime("%Y%m%d-%H%M%S")))
    n = 1
    while d.exists():
        n += 1
        d = d.with_name(d.name.split("~")[0] + "~%d" % n)
    d.mkdir(parents=True)
    for f in files:
        if f.exists():
            shutil.copy2(f, d / f.name)
    return d


def read_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def write_json(path, data, compact=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".angelos-tmp")
    tmp.write_text(json.dumps(data, separators=(",", ":")) if compact else json.dumps(data, indent=1, ensure_ascii=False) + "\n")
    tmp.replace(path)


# Chromium: Preferences keys the GTK theme sets — (dotted path, value or DELETE)
DELETE = object()
CHROMIUM_GTK = [
    ("extensions.theme.id", DELETE),
    ("extensions.theme.system_theme", 1),         # ui::SystemTheme::kGtk
    ("browser.theme.user_color2", DELETE),
    ("browser.theme.color_variant2", DELETE),
    ("browser.theme.user_color", DELETE),
    ("browser.theme.color_variant", DELETE),
    ("browser.theme.is_grayscale2", DELETE),
    ("browser.theme.color_scheme2", 0),           # dark or light from the system
]
MISSING = "__angelos_missing__"


def dig(d, path, create=False):
    keys = path.split(".")
    for k in keys[:-1]:
        if not isinstance(d.get(k), dict):
            if not create:
                return None, keys[-1]
            d[k] = {}
        d = d[k]
    return d, keys[-1]


def chromium_gtk_mode(prefs):
    ext = (prefs.get("extensions") or {}).get("theme") or {}
    return ext.get("system_theme") == 1 and not ext.get("id")


def chromium_status(b):
    prefs = read_json(b["profile"] / "Default/Preferences", None)
    loaded = False
    if prefs:
        for v in ((prefs.get("extensions") or {}).get("settings") or {}).values():
            if isinstance(v, dict) and v.get("path") == str(THEME):
                loaded = True
    return {"profile": prefs is not None, "live": bool(prefs and chromium_gtk_mode(prefs)),
            "static": loaded, "theme": str(THEME)}


def chromium_edit(b, bid, on):
    path = b["profile"] / "Default/Preferences"
    prefs = json.loads(path.read_text())
    undo = load_undo(bid, b["profile"])
    if on:
        folder = backup(bid, [path])
        before = undo["before"] if undo else {}
        for key, val in CHROMIUM_GTK:
            parent, last = dig(prefs, key, create=True)
            if not undo:
                before[key] = parent.get(last, MISSING)
            if val is DELETE:
                parent.pop(last, None)
            else:
                parent[last] = val
        write_json(path, prefs, compact=True)
        write_json(undo_file(bid), {"browser": bid, "profile": str(b["profile"]), "before": before,
                                    "backup": str(folder), "at": time.strftime("%Y-%m-%d %H:%M:%S")})
        return {"backup": str(folder)}
    if not undo:
        return {"nothing": True}
    folder = backup(bid, [path])
    for key, val in undo["before"].items():
        parent, last = dig(prefs, key, create=val != MISSING)
        if parent is None:
            continue
        if val == MISSING:
            parent.pop(last, None)
        else:
            parent[last] = val
    write_json(path, prefs, compact=True)
    undo_file(bid).unlink()
    return {"backup": str(folder)}


# Firefox: a marked block in user.js (the pref that lets userChrome.css load) and one at the
# top of chrome/userChrome.css that imports our file, linked in as chrome/angelos-theme.css
FF_PREF = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'


def strip_block(text, comment):
    out, skip = [], False
    for line in text.splitlines(keepends=True):
        s = line.strip()
        if s == comment % MARK_BEGIN:
            skip = True
            continue
        if s == comment % MARK_END:
            skip = False
            continue
        if not skip:
            out.append(line)
    return "".join(out)


def css_with_import(text):
    """@import must come before every other rule (only @charset/@layer may precede it)."""
    block = "/* %s */\n@import url(\"angelos-theme.css\");\n/* %s */\n" % (MARK_BEGIN, MARK_END)
    lines = strip_block(text, "/* %s */").splitlines(keepends=True)
    at = 1 if lines and lines[0].lstrip().lower().startswith("@charset") else 0
    return "".join(lines[:at]) + block + "".join(lines[at:])


def firefox_status(b):
    prof = profile_dir(b)
    if not prof:
        return {"profile": False, "live": False, "static": False, "theme": str(FF_CSS)}
    theme_id = "default-theme@mozilla.org"
    try:
        for line in (prof / "prefs.js").read_text(errors="ignore").splitlines():
            if line.startswith('user_pref("extensions.activeThemeID"'):
                theme_id = line.split(",", 1)[1].strip().rstrip(");").strip().strip('"')
    except OSError:
        pass
    link = prof / "chrome/angelos-theme.css"
    on = link.is_symlink() and MARK_BEGIN in (read_text(prof / "chrome/userChrome.css")) and FF_PREF in read_text(prof / "user.js")
    return {"profile": True, "live": theme_id == "default-theme@mozilla.org", "themeId": theme_id,
            "static": on, "theme": str(FF_CSS), "profileDir": str(prof)}


def read_text(p):
    try:
        return p.read_text(errors="ignore")
    except OSError:
        return ""


def firefox_edit(b, bid, on):
    prof = profile_dir(b)
    if not prof:
        raise RuntimeError("no Firefox profile yet: start Firefox once")
    chrome = prof / "chrome"
    ujs, uc, link = prof / "user.js", chrome / "userChrome.css", chrome / "angelos-theme.css"
    undo = load_undo(bid, prof)
    if not on and not undo and not link.is_symlink():
        return {"nothing": True}
    folder = backup(bid, [ujs, uc])
    if on:
        record = undo or {"browser": bid, "profile": str(prof), "created": [p.name for p in (ujs, uc) if not p.exists()],
                          "backup": str(folder), "at": time.strftime("%Y-%m-%d %H:%M:%S")}
        if not FF_CSS.exists():
            raise RuntimeError("no theme built yet: change the theme once or run build")
        old = strip_block(read_text(ujs), "// %s")
        write_text(ujs, old + ("" if not old or old.endswith("\n") else "\n") + "// %s\n%s\n// %s\n" % (MARK_BEGIN, FF_PREF, MARK_END))
        chrome.mkdir(exist_ok=True)
        write_text(uc, css_with_import(read_text(uc)))
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(FF_CSS)
        write_json(undo_file(bid), record)
        return {"backup": str(folder)}
    created = (undo or {}).get("created", [])
    for p, comment in ((ujs, "// %s"), (uc, "/* %s */")):
        if p.exists():
            rest = strip_block(read_text(p), comment)
            if not rest.strip() and p.name in created:
                p.unlink()
            else:
                write_text(p, rest)
    if link.is_symlink():
        link.unlink()
    try:
        chrome.rmdir()                            # only if we left it empty
    except OSError:
        pass
    if undo:
        undo_file(bid).unlink()
    return {"backup": str(folder)}


# ── commands ─────────────────────────────────────────────────────────────────

def waiter_unit(bid):
    return "angelos-browser-" + bid


def status():
    out = []
    for bid, b in BROWSERS.items():
        if not installed(b) and not testing(bid):
            continue
        s = chromium_status(b) if b["kind"] == "chromium" else firefox_status(b)
        s.update({"id": bid, "name": b["name"], "kind": b["kind"], "installed": True,
                  "running": running(b), "undo": load_undo(bid, profile_dir(b)) is not None,
                  "pending": subprocess.run(["systemctl", "--user", "is-active", "--quiet", waiter_unit(bid)],
                                            capture_output=True).returncode == 0})
        out.append(s)
    print(json.dumps({"browsers": out}, ensure_ascii=False))


def edit(bid, on, mode):
    b = BROWSERS[bid]
    if b["kind"] == "firefox":
        r = firefox_edit(b, bid, on)
        r.update({"ok": True, "done": True, "running": running(b)})   # counts from its next start
        return r
    if not (b["profile"] / "Default/Preferences").exists():
        return {"ok": False, "error": "no %s profile yet: start it once" % b["name"]}
    if running(b):
        if mode == "restart":
            argv = close_gently(b)
            if argv is None:
                return {"ok": False, "error": "%s didn't close" % b["name"], "running": True}
            r = chromium_edit(b, bid, on)
            r.update({"ok": True, "done": True, "reopened": reopen(b, argv)})
            return r
        if mode == "wait":
            unit = waiter_unit(bid)
            subprocess.run(["systemctl", "--user", "stop", unit], capture_output=True)
            me = [sys.executable, str(Path(__file__).resolve()), "apply" if on else "revert", bid, "--waiting"]
            if subprocess.run(["systemd-run", "--user", "--collect", "--quiet", "--unit", unit] + me,
                              capture_output=True).returncode != 0:
                subprocess.Popen(me, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            return {"ok": True, "done": False, "pending": True}
        if mode == "waiting":
            end, gone = time.time() + 12 * 3600, 0
            while time.time() < end:
                gone = gone + 1 if not running(b) else 0
                if gone >= 2:                         # closed for good, Preferences written
                    time.sleep(1)
                    r = chromium_edit(b, bid, on)
                    r.update({"ok": True, "done": True})
                    return r
                time.sleep(2)
            return {"ok": False, "error": "%s stayed open" % b["name"]}
        return {"ok": True, "done": False, "running": True}
    if mode != "waiting":                         # closed already: an old waiter has nothing left to do
        subprocess.run(["systemctl", "--user", "stop", waiter_unit(bid)], capture_output=True)
    r = chromium_edit(b, bid, on)
    r.update({"ok": True, "done": True})
    return r


def main():
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "build":
        changed, realm = build(json.loads(Path(a[1]).read_text()))
        print(json.dumps({"ok": True, "changed": changed, "realm": realm}))
    elif a == ["status"]:
        status()
    elif len(a) >= 2 and a[0] in ("apply", "revert") and a[1] in BROWSERS:
        mode = next((m[2:] for m in a[2:] if m in ("--restart", "--wait", "--waiting")), "")
        try:
            r = edit(a[1], a[0] == "apply", mode)
        except (OSError, ValueError, RuntimeError) as e:
            r = {"ok": False, "error": str(e)}
        print(json.dumps(r, ensure_ascii=False))
        sys.exit(0 if r.get("ok") else 1)
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
