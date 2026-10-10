"""Regression tests for authored (non-rotating) sprite animation strips."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image

SHELL = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("sprite_rig", SHELL / "scripts/sprite-rig.py")
sprite_rig = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sprite_rig)


class SpriteSequenceTest(unittest.TestCase):
    def test_authored_frames_keep_order_position_and_foreground_layer(self):
        colors = [(255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255),
                  (255, 255, 0, 255), (255, 0, 255, 255), (0, 255, 255, 255)]
        with tempfile.TemporaryDirectory() as tmp:
            atlas = Image.new("RGBA", (32, 8), (80, 80, 80, 255))
            boxes = []
            for i, color in enumerate(colors):
                box = [8 + i * 4, 0, 12 + i * 4, 4]
                boxes.append(box)
                atlas.paste(color, box)
            source = Path(tmp) / "sheet.png"
            atlas.save(source)
            recipe = {
                "sheet": str(source), "block": 1, "mask": False,
                "boxes": {name: [0, 0, 8, 8] for name in ("body", "eyes", "mouth")},
                "overlays": {name: {"scale": 1, "x": 0, "y": 0}
                             for name in ("eyes", "mouth")},
                "parts": {"belly": {"sequence": boxes, "at": [2, 3],
                                    "every": 2, "under": False}},
            }
            try:
                result = sprite_rig.build(recipe, Path(tmp) / "out")
            except KeyError as error:
                self.fail("Authored frame sequences cannot be built: " + str(error))
            part = result["parts"]["belly"]
            self.assertEqual((part["x"], part["y"]), (2, 3))
            self.assertEqual((part["w"], part["h"], part["frames"]), (4, 4, 6))
            self.assertEqual(part["every"], 2)
            self.assertFalse(part["under"])
            with Image.open(Path(tmp) / "out/belly.png") as strip:
                self.assertEqual(strip.size, (24, 4))
                self.assertEqual([strip.getpixel((i * 4 + 1, 1)) for i in range(6)], colors)


if __name__ == "__main__":
    unittest.main()
