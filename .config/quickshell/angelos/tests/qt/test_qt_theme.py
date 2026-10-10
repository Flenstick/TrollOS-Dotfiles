#!/usr/bin/env python3
"""scripts/qt-theme.py in a throw-away $HOME: Telegram's own fields are left to it, and running
Qt apps are told about a new look.

- the stylesheet boxes Qt's fields in the angelOS frame, but not the ones inside Telegram
  (Ui::RpWidget, Ui::MaskedInputField): Telegram draws those itself, in its own theme
  (scripts/telegram-theme.py) — a box of this sheet in them was the frame around its message field
- qt6ct reloads only on a change in its own folder (not in qss/ or colors/): a stamp is written
  there when the look changed, and left alone when it didn't
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/qt-theme.py"

PALETTE = {
    "mode": "dark", "qtStyle": "1", "realm": "heaven", "appsRealm": "heaven",
    "bg": "#1a171c", "bgAlt": "#22191e", "face": "#22191e", "faceAlt": "#2d1d21", "sunken": "#1a171c",
    "fg": "#fafafa", "text": "#fafafa", "textDim": "#b4b5b7", "hi": "#2d1d21", "lo": "#1a171c",
    "edge": "#1a171c", "accent": "#b3716c", "accent2": "#cca19e", "select": "#b3716c", "selectText": "#1a171c",
}


class QtTheme(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.qt6ct = self.home / ".config/qt6ct"

    def tearDown(self):
        self.tmp.cleanup()

    def run_theme(self, pal):
        f = self.home / "palette.json"
        f.write_text(json.dumps(pal))
        env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / ".config"))
        out = subprocess.run([sys.executable, str(SCRIPT), str(f)], env=env, capture_output=True, text=True, timeout=30)
        self.assertEqual(out.returncode, 0, out.stderr)
        return out

    def test_telegram_fields_are_its_own(self):
        self.run_theme(PALETTE)
        qss = (self.qt6ct / "qss/angelos.qss").read_text()
        boxed = qss.index("QLineEdit, QTextEdit, QPlainTextEdit, QAbstractSpinBox {")
        own = qss.index("Ui--RpWidget QTextEdit, Ui--RpWidget QLineEdit, Ui--MaskedInputField {")
        self.assertLess(boxed, own, "Telegram's rule must come after the field box")
        rule = qss[own:qss.index("}", own)]
        for want in ("background: transparent", "border: none", "border-image: none"):
            self.assertIn(want, rule)
        # the focus frame is a pseudo-state rule of its own: Telegram's needs one as well
        self.assertIn("Ui--RpWidget QTextEdit:focus", qss[qss.index("QTextEdit:focus"):])
        focus = qss.index("Ui--RpWidget QTextEdit:focus")
        self.assertIn("border-image: none", qss[focus:qss.index("}", focus)])

    def test_stamp_tells_running_apps(self):
        stamp = self.qt6ct / ".angelos-stamp"
        self.run_theme(PALETTE)
        self.assertTrue(stamp.exists(), "no stamp in qt6ct's folder after the first look")
        first = stamp.read_text()
        before = stamp.stat().st_ino
        self.run_theme(PALETTE)
        self.assertEqual(stamp.stat().st_ino, before, "the same look must not wake qt6ct")
        self.run_theme(dict(PALETTE, accent="#5787b3", select="#5787b3"))
        self.assertNotEqual(stamp.read_text(), first, "a new look must change the stamp")


if __name__ == "__main__":
    unittest.main(verbosity=2)
