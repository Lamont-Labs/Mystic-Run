from __future__ import annotations

import sys
import unittest
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import build_premium_2d_assets as pipeline


class Premium2DAssetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.atlases = pipeline.build_character_atlases()
        cls.backgrounds = pipeline.build_backgrounds()

    def test_every_atlas_region_is_the_unmodified_approved_cutout(self) -> None:
        for character, data in self.atlases.items():
            atlas = Image.open(ROOT / data["atlas"]["path"]).convert("RGBA")
            for view, frame in data["frames"].items():
                source = Image.open(ROOT / frame["source"]["path"]).convert("RGBA")
                x, y, width, height = frame["region"]
                packed = atlas.crop((x, y, x + width, y + height))
                self.assertIsNone(
                    ImageChops.difference(source, packed).getbbox(),
                    f"{character} {view} atlas pixels differ from approved source",
                )

    def test_action_pose_art_is_not_mislabeled_as_concept_faithful(self) -> None:
        for character, data in self.atlases.items():
            contract = data["animation_contract"]
            self.assertEqual(contract["approved_pose_frames"], ["front", "rear"])
            self.assertEqual(contract["action_pose_frames"], [])
            self.assertIn("Do not substitute", contract["note"])
            self.assertTrue((ROOT / data["atlas"]["path"]).is_file())

    def test_backdrops_are_mobile_portrait_derivatives_with_preserved_sources(self) -> None:
        for character, data in self.backgrounds.items():
            self.assertEqual(data["dimensions"], [768, 1152])
            self.assertIn("2:3 portrait", data["crop"])
            source = ROOT / data["source"]["path"]
            output = ROOT / data["output"]["path"]
            self.assertTrue(source.is_file())
            self.assertTrue(output.is_file())
            with Image.open(output) as image:
                self.assertEqual(image.size, (768, 1152))
                self.assertEqual(image.format, "JPEG")


if __name__ == "__main__":
    unittest.main()
