#!/usr/bin/env python3
"""Pack approved character cutouts and prepare mobile-ready painted backdrops.

Character pixels are copied byte-for-byte from the owner-approved concept crops.
This tool deliberately does not use the older locally drawn action studies.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ("knight", "gargoyle", "witch")
VIEWS = ("front", "rear")
BACKGROUND_SOURCES = {
    "knight": "mysticrun_citadel_dawn.png",
    "gargoyle": "mysticrun_enchanted_forest.png",
    "witch": "mysticrun_crystal_canyon.png",
}
BACKGROUND_PROMPTS = {
    "knight": (
        "Hand-painted storybook fantasy panorama of a luminous cloud-top citadel "
        "at dawn, ivory towers, lavender-pink clouds, floating islands, turquoise "
        "and warm gold accents; no characters, road, text, logo or UI."
    ),
    "gargoyle": (
        "Hand-painted storybook fantasy panorama of enchanted silver-green forest "
        "cliffs above clouds, violet twilight, glowing mushrooms, tiny turquoise "
        "fireflies; no characters, road, text, logo or UI."
    ),
    "witch": (
        "Hand-painted storybook fantasy panorama of a floating crystal canyon at "
        "sunset, pale stone, turquoise crystals, pink-lavender sky and distant "
        "towers; no characters, road, text, logo or UI."
    ),
}
LICENSE_ID = "mysticrun-owner-provided-concept-sprites"
BACKGROUND_ASSET_ID = "mysticrun-replit-generated-backdrops"
BACKGROUND_LICENSE = "assets/licenses/mysticrun-replit-generated-art-noncommercial.txt"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(path: Path) -> dict[str, object]:
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": sha256(path),
        "bytes": path.stat().st_size,
    }


def build_character_atlases(root: Path = ROOT) -> dict[str, dict[str, object]]:
    atlas_dir = root / "assets/characters/concept-sprites/atlases"
    atlas_dir.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict[str, object]] = {}

    for character in CHARACTERS:
        sources = {
            view: root / f"assets/characters/concept-sprites/{character}_{view}.png"
            for view in VIEWS
        }
        images = {view: Image.open(path).convert("RGBA") for view, path in sources.items()}
        gutter = 4
        front, rear = images["front"], images["rear"]
        rear_x = front.width + gutter
        atlas = Image.new("RGBA", (rear_x + rear.width, max(front.height, rear.height)), (0, 0, 0, 0))
        atlas.alpha_composite(front, (0, 0))
        atlas.alpha_composite(rear, (rear_x, 0))
        atlas_path = atlas_dir / f"{character}_atlas.png"
        atlas.save(atlas_path, optimize=True)

        manifest[character] = {
            "atlas": record(atlas_path),
            "atlas_dimensions": list(atlas.size),
            "gutter_px": gutter,
            "frames": {
                "front": {
                    "region": [0, 0, front.width, front.height],
                    "source": record(sources["front"]),
                },
                "rear": {
                    "region": [rear_x, 0, rear.width, rear.height],
                    "source": record(sources["rear"]),
                },
            },
            "animation_contract": {
                "approved_pose_frames": ["front", "rear"],
                "action_pose_frames": [],
                "note": (
                    "Do not substitute generated action drawings. Until approved "
                    "source-conditioned poses exist, gameplay keeps the exact "
                    "approved cutout and uses restrained engine transforms."
                ),
            },
        }

    manifest_path = atlas_dir / "manifest.json"
    manifest_path.write_text(json.dumps({
        "schema": 1,
        "generator": "tools/build_premium_2d_assets.py",
        "source_authority": "references/01-character-concept.png",
        "source_sha256": sha256(root / "references/01-character-concept.png"),
        "characters": manifest,
    }, indent=2) + "\n")

    registry_path = root / "assets/asset_registry.json"
    registry = json.loads(registry_path.read_text())
    entry = next(item for item in registry["assets"] if item["id"] == LICENSE_ID)
    entry["sources"] = list(dict.fromkeys(entry["sources"] + [
        "tools/build_premium_2d_assets.py",
        "assets/characters/concept-sprites/atlases/manifest.json",
    ]))
    entry["modifications"] = list(dict.fromkeys(entry["modifications"] + [
        "Packed the approved front/rear cutouts into per-character atlases without changing any character pixels; gameplay reads the atlas regions.",
        "No concept-faithful action-pose frames are claimed; the older local action drawings remain excluded from gameplay.",
    ]))
    records = {item["path"]: item for item in entry["files"]}
    for item in manifest.values():
        atlas_record = item["atlas"]
        records[atlas_record["path"]] = atlas_record
    entry["files"] = sorted(records.values(), key=lambda item: item["path"])
    registry_path.write_text(json.dumps(registry, indent=2) + "\n")
    return manifest


def build_backgrounds(root: Path = ROOT) -> dict[str, dict[str, object]]:
    source_dir = root / "art/premium-2d/source"
    output_dir = root / "assets/environment/premium-2d"
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict[str, object]] = {}
    output_size = (768, 1152)

    for character, filename in BACKGROUND_SOURCES.items():
        source_path = source_dir / filename
        output_path = output_dir / f"{character}_backdrop.jpg"
        with Image.open(source_path) as opened:
            source = ImageOps.exif_transpose(opened).convert("RGB")
            # Godot's distant environment card uses a 2:3 portrait ratio.
            artwork = ImageOps.fit(
                source,
                output_size,
                method=Image.Resampling.LANCZOS,
                centering=(0.5, 0.56),
            )
            artwork.save(output_path, "JPEG", quality=88, optimize=True, progressive=True)
        manifest[character] = {
            "source": record(source_path),
            "output": record(output_path),
            "dimensions": list(output_size),
            "crop": "centered 2:3 portrait, optimized JPEG quality 88",
            "prompt": BACKGROUND_PROMPTS[character],
        }

    provenance_path = output_dir / "PROVENANCE.json"
    provenance_path.write_text(json.dumps({
        "schema": 1,
        "generator": "Replit image-generation tool",
        "pipeline": "tools/build_premium_2d_assets.py",
        "commercial_use_claimed": False,
        "external_reference_images": [],
        "backgrounds": manifest,
    }, indent=2) + "\n")

    registry_path = root / "assets/asset_registry.json"
    registry = json.loads(registry_path.read_text())
    registry["coverage_roots"] = list(dict.fromkeys(
        registry["coverage_roots"] + ["assets/environment/premium-2d"]
    ))
    source_records = [
        record(source_dir / filename) for filename in BACKGROUND_SOURCES.values()
    ]
    output_records = [item["output"] for item in manifest.values()]
    license_evidence = record(root / BACKGROUND_LICENSE)
    entry = next(
        (item for item in registry["assets"] if item["id"] == BACKGROUND_ASSET_ID),
        None,
    )
    if entry is None:
        entry = {
            "cost_usd": 0,
            "commercial_use": False,
            "modification": True,
            "game_distribution": True,
            "attribution_required": False,
            "id": BACKGROUND_ASSET_ID,
            "publisher": "Replit image-generation tool",
            "license": "LicenseRef-MysticRun-Replit-Generated-NonCommercial",
            "sources": [],
            "edition": "Generated for MysticRun in Replit",
            "license_evidence": license_evidence,
            "modifications": [],
            "derived_from": [],
            "files": [],
        }
        registry["assets"].append(entry)
    entry["sources"] = list(dict.fromkeys(entry["sources"] + [
        "tools/build_premium_2d_assets.py",
        "assets/environment/premium-2d/PROVENANCE.json",
        *[item["source"]["path"] for item in manifest.values()],
    ]))
    entry["license_evidence"] = license_evidence
    entry["modifications"] = [
        "Generated three original, character-free fantasy backgrounds with Replit image generation.",
        "Preserved the original generated PNGs; made portrait 2:3 JPEG gameplay crops without changing the character concept artwork.",
        "Use is recorded as noncommercial project art; no commercial-use claim is made.",
    ]
    records = {item["path"]: item for item in entry["files"]}
    for item in source_records + output_records:
        records[item["path"]] = item
    entry["files"] = sorted(records.values(), key=lambda item: item["path"])
    registry_path.write_text(json.dumps(registry, indent=2) + "\n")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    atlases = build_character_atlases(args.root)
    backgrounds = build_backgrounds(args.root)
    print(
        f"PREMIUM_2D_ASSETS_PASS atlases={len(atlases)} "
        f"backdrops={len(backgrounds)} action_pose_frames=0"
    )


if __name__ == "__main__":
    main()
