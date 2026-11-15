#!/usr/bin/env python3
"""Extract transparent front/rear character cutouts from the approved sheet.

The source concept remains the visual authority. This script only crops its
existing character artwork and removes the connected pale backdrop; it does
not redraw, synthesize, or retouch character pixels.
"""
from __future__ import annotations

import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "references/01-character-concept.png"
DEST = ROOT / "assets/characters/concept-sprites"

# Pixel regions were measured against the original 1536 x 1024 source sheet.
REGIONS = {
    "knight_front": (42, 50, 455, 592),
    "knight_rear": (115, 630, 445, 1005),
    "gargoyle_front": (475, 105, 977, 600),
    "gargoyle_rear": (540, 628, 950, 1005),
    "witch_front": (1048, 35, 1530, 610),
    "witch_rear": (1088, 620, 1528, 1005),
}


def background_mask(image: Image.Image) -> bytearray:
    """Return pixels matching the local backdrop and connected to the crop edge."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    samples = []
    patch = min(10, width // 8, height // 8)
    for left, top in [
        (0, 0),
        (width - patch, 0),
        (0, height - patch),
        (width - patch, height - patch),
    ]:
        colors = [
            pixels[x, y]
            for y in range(top, top + patch)
            for x in range(left, left + patch)
        ]
        samples.append(
            tuple(
                sorted(color[channel] for color in colors)[len(colors) // 2]
                for channel in range(3)
            )
        )

    candidate = bytearray(width * height)
    for y in range(height):
        row = y * width
        v = y / max(1, height - 1)
        for x in range(width):
            u = x / max(1, width - 1)
            expected = tuple(
                (1 - v) * ((1 - u) * samples[0][c] + u * samples[1][c])
                + v * ((1 - u) * samples[2][c] + u * samples[3][c])
                for c in range(3)
            )
            actual = pixels[x, y]
            distance = sum((actual[c] - expected[c]) ** 2 for c in range(3)) ** 0.5
            if max(actual) >= 140 and distance <= 36:
                candidate[row + x] = 1

    background = bytearray(width * height)
    queue: deque[int] = deque()

    def seed(index: int) -> None:
        if candidate[index] and not background[index]:
            background[index] = 1
            queue.append(index)

    for x in range(width):
        seed(x)
        seed((height - 1) * width + x)
    for y in range(height):
        seed(y * width)
        seed(y * width + width - 1)

    while queue:
        index = queue.popleft()
        x, y = index % width, index // width
        if x:
            seed(index - 1)
        if x + 1 < width:
            seed(index + 1)
        if y:
            seed(index - width)
        if y + 1 < height:
            seed(index + width)
    return background


def crop_sprite(sheet: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    source = sheet.crop(box).convert("RGBA")
    background = background_mask(source)
    width, height = source.size
    alpha = Image.new("L", source.size, 255)
    alpha_pixels = alpha.load()
    for index, is_background in enumerate(background):
        if is_background:
            alpha_pixels[index % width, index // width] = 0
    source.putalpha(alpha)

    # Remove detached layout ornaments and label fragments, not small parts
    # attached to the character silhouette.
    alpha_data = bytearray(alpha.tobytes())
    visited = bytearray(width * height)
    minimum_component = max(500, width * height // 1000)
    for start, opacity in enumerate(alpha_data):
        if opacity == 0 or visited[start]:
            continue
        component: list[int] = []
        queue = [start]
        visited[start] = 1
        while queue:
            index = queue.pop()
            component.append(index)
            x, y = index % width, index // width
            for neighbor in (
                index - 1 if x else -1,
                index + 1 if x + 1 < width else -1,
                index - width if y else -1,
                index + width if y + 1 < height else -1,
            ):
                if neighbor >= 0 and alpha_data[neighbor] and not visited[neighbor]:
                    visited[neighbor] = 1
                    queue.append(neighbor)
        if len(component) < minimum_component:
            for index in component:
                alpha_data[index] = 0
    alpha = Image.frombytes("L", source.size, bytes(alpha_data))
    source.putalpha(alpha)

    # Crop only after masking so the concept pose's entire silhouette remains.
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError(f"No character pixels remained for region {box}")
    left, top, right, bottom = bounds
    # Retain a small transparent breathing margin for the in-game billboard.
    pad = 5
    left, top = max(0, left - pad), max(0, top - pad)
    right, bottom = min(width, right + pad), min(height, bottom + pad)
    return source.crop((left, top, right, bottom))


def main() -> None:
    sheet_bytes = SOURCE.read_bytes()
    sheet_hash = hashlib.sha256(sheet_bytes).hexdigest()
    sheet = Image.open(SOURCE).convert("RGB")
    if sheet.size != (1536, 1024):
        raise RuntimeError(f"Unexpected concept sheet dimensions: {sheet.size}")
    DEST.mkdir(parents=True, exist_ok=True)

    manifest = {
        "source": "references/01-character-concept.png",
        "source_sha256": sheet_hash,
        "method": "source crop with edge-connected pale-backdrop transparency",
        "generated_art": False,
        "sprites": {},
    }
    for name, box in REGIONS.items():
        sprite = crop_sprite(sheet, box)
        path = DEST / f"{name}.png"
        sprite.save(path, optimize=True)
        manifest["sprites"][name] = {
            "path": path.relative_to(ROOT).as_posix(),
            "source_region": list(box),
            "dimensions": list(sprite.size),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "alpha_pixels": sprite.getchannel("A").histogram()[0],
        }
        print(f"{name}: {sprite.width}x{sprite.height} {path.stat().st_size} bytes")

    (DEST / "PROVENANCE.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"CONCEPT_SPRITES {json.dumps(manifest, sort_keys=True)}")


if __name__ == "__main__":
    main()
