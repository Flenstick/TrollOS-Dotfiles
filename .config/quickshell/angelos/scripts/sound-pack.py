#!/usr/bin/env python3
"""Download the NEEDY GIRL OVERDOSE sound pack for angelOS.

  sound-pack.py overdose <dir>     fetches the Windose sounds, prints JSON

The sounds come from Plasma-Overdose (github.com/Notify-ctrl/Plasma-Overdose,
a KDE theme after the game; the sounds belong to the game's authors). They are
fetched on the user's machine when the pack is switched on and are not shipped
with angelOS. Each angelOS event gets the Windose sound that fits it; events
the game has nothing for (the demon's glass, the angel's choir) stay with the
synthesised Y2K pack.
"""
import json
import os
import sys
import urllib.request

SOURCES = [
    "https://raw.githubusercontent.com/Notify-ctrl/Plasma-Overdose/master/sounds/stereo/{}.ogg",
    "https://codeberg.org/Notify-ctrl/Plasma-Overdose/raw/branch/master/sounds/stereo/{}.ogg",
]
# angelOS event -> Windose sound
OVERDOSE = {
    "startup": "desktop-login",
    "notify": "message-new-instant",
    "error": "dialog-warning",
    "click": "button-pressed",
    "shutdown": "desktop-logout",
    "angel": "item-selected",
    "wallpaper": "complete",
    "open": "window-unminimized",
    "toggle": "button-pressed-modifier",
    "screenshot": "message-sent-instant",
    "volume": "audio-volume-change",
    "windowClose": "window-close",
    "demon": "dialog-error",
}


def fetch(name):
    last = None
    for src in SOURCES:
        try:
            req = urllib.request.Request(src.format(name), headers={"User-Agent": "angelOS"})
            with urllib.request.urlopen(req, timeout=20) as r:
                data = r.read(4 * 1024 * 1024)
            if data[:4] == b"OggS":
                return data
            last = "not an ogg file"
        except OSError as e:
            last = str(e)
    raise OSError(last or "no source")


def main():
    if len(sys.argv) != 3 or sys.argv[1] != "overdose":
        sys.exit(__doc__)
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    got, failed = {}, {}
    for event, name in OVERDOSE.items():
        path = os.path.join(out, event + ".ogg")
        if os.path.getsize(path) if os.path.exists(path) else 0:
            got[event] = path
            continue
        try:
            data = fetch(name)
        except OSError as e:
            failed[event] = str(e)
            continue
        with open(path + ".part", "wb") as f:
            f.write(data)
        os.replace(path + ".part", path)
        got[event] = path
    with open(os.path.join(out, "SOURCE.txt"), "w") as f:
        f.write("NEEDY GIRL OVERDOSE sounds via Plasma-Overdose\n"
                "https://github.com/Notify-ctrl/Plasma-Overdose — the sounds belong to the game's authors.\n")
    print(json.dumps({"ok": not failed, "sounds": got, "failed": failed}))
    sys.exit(0 if got else 1)


if __name__ == "__main__":
    main()
