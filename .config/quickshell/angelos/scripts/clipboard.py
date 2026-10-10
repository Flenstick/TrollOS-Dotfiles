#!/usr/bin/env python3
"""angelOS clipboard history helper (text and images).

  clipboard.py capture          run by `wl-paste --watch`: prints one JSON entry
                                for the new clipboard content (or nothing). The
                                content wl-paste pipes in is always there; asking
                                the clipboard again (for the image next to a text,
                                or the type list) may fail when the owner is gone
                                or busy, so that data is the fallback (issue #20)
  clipboard.py copy             reads one JSON entry on stdin, puts it back with wl-copy
  clipboard.py prune ID...      deletes stored images whose ids are not listed

Images live in ~/.local/state/angelos/clipboard/<sha256-prefix>.<ext> (0700 dir,
0600 files). Content marked by password managers is never stored.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys

STORE = Path(os.environ.get("ANGELOS_CLIPBOARD_DIR", str(Path.home() / ".local/state/angelos/clipboard")))
IMAGE_TYPES = ("image/png", "image/jpeg", "image/webp", "image/gif", "image/bmp")
EXT = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif", "image/bmp": "bmp"}
MAX_IMAGE = 32 * 1024 * 1024
MAX_TEXT = 1024 * 1024
NAME_RE = re.compile(r"[0-9a-f]{32}\.(png|jpg|webp|gif|bmp)\Z")
# clipboard owners that mark secrets (KeePassXC, KDE, Bitwarden desktop…)
SECRET_TYPES = ("x-kde-passwordManagerHint",)
# office suites offer a rendered picture next to the text; the text is what was meant
RICH_TEXT_HINTS = ("application/x-openoffice", "application/vnd.oasis", "text/rtf", "application/rtf",
                   "application/x-qt-windows-mime")


def wl_paste(*args, limit=None, timeout=4):
    """Clipboard contents; the owner may never answer (a closed app), so this times out."""
    try:
        done = subprocess.run(["wl-paste", "--no-newline", *args], stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, timeout=timeout)
    except subprocess.TimeoutExpired:
        return b""
    data = done.stdout
    return data[:limit + 1] if limit else data


def image_size(data):
    """(width, height) from the file header, or (0, 0)."""
    try:
        if data[:8] == b"\x89PNG\r\n\x1a\n":
            return struct.unpack(">II", data[16:24])
        if data[:6] in (b"GIF87a", b"GIF89a"):
            return struct.unpack("<HH", data[6:10])
        if data[:2] == b"BM":
            w, h = struct.unpack("<ii", data[18:26])
            return abs(w), abs(h)
        if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
            kind = data[12:16]
            if kind == b"VP8X":
                return 1 + int.from_bytes(data[24:27], "little"), 1 + int.from_bytes(data[27:30], "little")
            if kind == b"VP8 ":
                w, h = struct.unpack("<HH", data[26:30])
                return w & 0x3FFF, h & 0x3FFF
            if kind == b"VP8L":
                b = int.from_bytes(data[21:25], "little")
                return (b & 0x3FFF) + 1, ((b >> 14) & 0x3FFF) + 1
        if data[:2] == b"\xff\xd8":
            i = 2
            while i + 9 < len(data):
                if data[i] != 0xFF:
                    i += 1
                    continue
                marker = data[i + 1]
                if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                    h, w = struct.unpack(">HH", data[i + 5:i + 9])
                    return w, h
                i += 2 + struct.unpack(">H", data[i + 2:i + 4])[0]
    except (struct.error, IndexError):
        pass
    return 0, 0


def private_store():
    STORE.mkdir(mode=0o700, parents=True, exist_ok=True)
    if STORE.is_symlink() or not STORE.is_dir():
        raise OSError("clipboard store must be a real directory")
    STORE.chmod(0o700)


def sniff_image(data):
    """the MIME type of image bytes, by their header"""
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return "image/gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if data[:2] == b"BM" and len(data) > 26:
        return "image/bmp"
    return None


def piped():
    """what `wl-paste --watch` handed over on stdin (b"" when run by hand)"""
    if sys.stdin is None or sys.stdin.isatty():
        return b""
    try:
        return sys.stdin.buffer.read(MAX_IMAGE + 1)
    except OSError:
        return b""


def capture():
    # wl-clipboard ≥ 2.2 says what happened: data | nil | clear | sensitive
    state = os.environ.get("CLIPBOARD_STATE", "data")
    if state in ("nil", "clear", "sensitive"):
        return 0
    given = piped()
    types = [t.strip() for t in wl_paste("--list-types").decode("utf-8", "replace").splitlines() if t.strip()]
    if not types and not given:
        # a busy owner: one more try before giving up
        import time
        time.sleep(0.15)
        types = [t.strip() for t in wl_paste("--list-types").decode("utf-8", "replace").splitlines() if t.strip()]
    if any(t in types for t in SECRET_TYPES):
        return 0
    image = next((m for m in IMAGE_TYPES if m in types), None)
    text_type = next((t for t in types if t == "text/plain" or t.startswith("text/plain;") or t == "UTF8_STRING"), None)
    if image and text_type and any(t.startswith(RICH_TEXT_HINTS) for t in types):
        image = None
    given_image = sniff_image(given) if given else None
    if not types and given:
        # the owner no longer answers: go by what was piped in
        image, text_type = given_image, None if given_image else "text/plain"
    if image:
        data = given if given_image == image else wl_paste("--type", image, limit=MAX_IMAGE)
        if not data and given_image:
            image, data = given_image, given
        if not data or len(data) > MAX_IMAGE:
            return 0
        digest = hashlib.sha256(data).hexdigest()[:32]
        private_store()
        path = STORE / f"{digest}.{EXT[image]}"
        if not path.exists():
            tmp = path.with_suffix(".part")
            fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
            with os.fdopen(fd, "wb") as out:
                out.write(data)
            os.replace(tmp, path)
        w, h = image_size(data)
        entry = {"kind": "image", "id": digest, "mime": image, "path": str(path),
                 "width": w, "height": h, "bytes": len(data)}
    elif text_type:
        # wl-paste pipes the text type in when there is one; ask again only if not
        raw = given if given and not given_image else wl_paste("--type", text_type, limit=MAX_TEXT)
        if len(raw) > MAX_TEXT:
            return 0
        text = raw.decode("utf-8", "replace")
        if not text.strip():
            return 0
        entry = {"kind": "text", "id": hashlib.sha256(raw).hexdigest()[:32],
                 "mime": "text/plain;charset=utf-8", "text": text}
    else:
        return 0
    print(json.dumps(entry, ensure_ascii=False), flush=True)
    return 0


def stored_path(entry):
    """Only files inside the store, named as capture() names them."""
    path = Path(str(entry.get("path", "")))
    if not NAME_RE.fullmatch(path.name) or path.parent.resolve() != STORE.resolve() or path.is_symlink():
        return None
    return path


def copy():
    entry = json.loads(sys.stdin.read(4 * MAX_TEXT))
    if entry.get("kind") == "image":
        path = stored_path(entry)
        mime = entry.get("mime") if entry.get("mime") in IMAGE_TYPES else "image/png"
        if not path or not path.is_file():
            return 1
        with open(path, "rb") as source:
            return subprocess.run(["wl-copy", "--type", mime], stdin=source).returncode
    text = str(entry.get("text", ""))
    return subprocess.run(["wl-copy", "--type", "text/plain;charset=utf-8"], input=text.encode()).returncode


def prune(keep):
    if not STORE.is_dir() or STORE.is_symlink():
        return 0
    keep = set(keep)
    for path in STORE.iterdir():
        if NAME_RE.fullmatch(path.name) and path.stem not in keep and path.is_file() and not path.is_symlink():
            path.unlink(missing_ok=True)
        elif path.suffix == ".part" and path.is_file():
            path.unlink(missing_ok=True)
    return 0


def main():
    os.umask(0o077)
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        if cmd == "capture":
            return capture()
        if cmd == "copy":
            return copy()
        if cmd == "prune":
            return prune(a for a in sys.argv[2:] if re.fullmatch(r"[0-9a-f]{32}", a))
    except (OSError, ValueError) as error:
        print("clipboard.py:", error, file=sys.stderr)
        return 1
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
