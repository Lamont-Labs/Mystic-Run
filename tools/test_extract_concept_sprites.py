import hashlib
import json
import unittest
from pathlib import Path

from PIL import Image

import extract_concept_sprites as extractor


class ConceptSpriteExtractionTests(unittest.TestCase):
    def test_committed_cutouts_match_the_approved_source_and_recipe(self):
        source_bytes = extractor.SOURCE.read_bytes()
        manifest = json.loads(
            (extractor.DEST / "PROVENANCE.json").read_text()
        )
        self.assertEqual(
            hashlib.sha256(source_bytes).hexdigest(), manifest["source_sha256"]
        )
        self.assertFalse(manifest["generated_art"])
        sheet = Image.open(extractor.SOURCE).convert("RGB")

        self.assertEqual(set(manifest["sprites"]), set(extractor.REGIONS))
        for name, region in extractor.REGIONS.items():
            with self.subTest(sprite=name):
                sprite_path = extractor.DEST / f"{name}.png"
                actual = Image.open(sprite_path).convert("RGBA")
                expected = extractor.crop_sprite(sheet, region)
                entry = manifest["sprites"][name]

                self.assertEqual(actual.size, expected.size)
                self.assertEqual(actual.tobytes(), expected.tobytes())
                self.assertEqual(
                    hashlib.sha256(sprite_path.read_bytes()).hexdigest(),
                    entry["sha256"],
                )
                self.assertGreater(actual.getchannel("A").histogram()[0], 0)
                self.assertGreater(actual.getchannel("A").histogram()[255], 1000)


if __name__ == "__main__":
    unittest.main()
