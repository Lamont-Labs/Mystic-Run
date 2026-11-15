#!/usr/bin/env python3
"""Prove all visible atlas RGB came from the approved source, not new painting."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    folder = ROOT / "experiments/knight_rig/art"
    manifest = json.loads((folder / "rig.json").read_text())
    source_path = ROOT / manifest["source"]
    assert hashlib.sha256(source_path.read_bytes()).hexdigest() == manifest["source_sha256"]
    source = Image.open(source_path).convert("RGBA")
    atlas = Image.open(folder / "knight_layers.png").convert("RGBA")
    assert atlas.size == (1024, 512)
    assert len(manifest["parts"]) == 14
    names = set()
    visible = 0
    for part in manifest["parts"]:
        assert part["name"] not in names
        assert not part["parent"] or part["parent"] in names
        names.add(part["name"])
        x, y, w, h = part["region"]
        layer = atlas.crop((x, y, x + w, y + h))
        original = source.crop(part["source_rect"])
        assert layer.size == original.size
        for actual, expected in zip(layer.getdata(), original.getdata()):
            if actual[3]:
                assert actual[:3] == expected[:3], f"Repainted pixel in {part['name']}"
                assert actual[3] <= expected[3]
                visible += 1
    assert visible > 30000
    print(f"KNIGHT_LAYERS_PASS: {visible} visible painted samples match source RGB; source hash and 14 parts verified")


if __name__ == "__main__":
    main()
