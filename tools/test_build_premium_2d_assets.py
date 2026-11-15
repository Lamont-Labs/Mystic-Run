from __future__ import annotations

import sys
import unittest
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import build_premium_2d_assets as pipeline

EXPECTED_ACTION_POSES = {
    character: {
        "run_rear_0", "run_rear_1", "jump_rear", "fall_rear", "land_rear",
        "slide_rear", "dodge_rear", "dodge_right_rear", "attack_rear",
        "block_rear", "damage_rear", "special_rear", "defeat_rear", "victory_rear",
    }
    for character in ("knight", "gargoyle", "witch")
}


class Premium2DAssetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.atlases = pipeline.build_character_atlases()
        cls.action_atlases = pipeline.build_action_atlases()
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
            self.assertIn("separate action atlas", contract["note"])
            self.assertTrue((ROOT / data["atlas"]["path"]).is_file())

    def test_action_frames_are_keyed_aligned_and_packed_in_grid_atlases(self) -> None:
        self.assertEqual(set(self.action_atlases), {"knight", "gargoyle", "witch"})
        for character, action_data in self.action_atlases.items():
            with Image.open(ROOT / f"assets/characters/concept-sprites/{character}_rear.png") as rear:
                width, height = rear.size
            atlas = Image.open(ROOT / action_data["atlas"]["path"]).convert("RGBA")
            frames = action_data["frames"]
            self.assertEqual(set(frames), EXPECTED_ACTION_POSES[character])
            columns = min(4, len(frames))
            rows = (len(frames) + columns - 1) // columns
            self.assertEqual(action_data["columns"], columns)
            self.assertEqual(action_data["rows"], rows)
            self.assertEqual(
                action_data["atlas_dimensions"],
                [width * columns + 4 * (columns - 1), height * rows + 4 * (rows - 1)],
            )
            run_images = []
            for frame_name, frame in frames.items():
                x, y, frame_width, frame_height = frame["region"]
                self.assertEqual((frame_width, frame_height), (width, height))
                self.assertGreaterEqual(x, 0)
                self.assertGreaterEqual(y, 0)
                self.assertLessEqual(x + frame_width, atlas.width)
                self.assertLessEqual(y + frame_height, atlas.height)
                image = atlas.crop((x, y, x + frame_width, y + frame_height))
                self.assertEqual(image.getchannel("A").getpixel((0, 0)), 0)
                self.assertEqual(image.getchannel("A").getpixel((frame_width - 1, 0)), 0)
                bounds = image.getchannel("A").getbbox()
                self.assertIsNotNone(bounds)
                self.assertEqual(bounds[3], height)
                source = ROOT / frame["source"]["path"]
                self.assertTrue(source.is_file())
                with Image.open(source) as raw_source:
                    self.assertEqual(raw_source.size, (1024, 1024))
                if frame_name in {"run_rear_0", "run_rear_1"}:
                    run_images.append(image)
            self.assertIsNotNone(
                ImageChops.difference(run_images[0], run_images[1]).getbbox(),
                f"{character} run-cycle frames must differ",
            )

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
