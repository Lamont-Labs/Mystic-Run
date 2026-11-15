#!/usr/bin/env python3
"""Pack approved character cutouts and prepare mobile-ready painted backdrops.

Character pixels are copied byte-for-byte from the owner-approved concept crops.
This tool deliberately does not use the older locally drawn action studies.
"""
from __future__ import annotations

import argparse
from collections import deque
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
POSE_ASSET_ID = "mysticrun-replit-generated-character-poses"
BACKGROUND_LICENSE = "assets/licenses/mysticrun-replit-generated-art-noncommercial.txt"
POSE_SOURCES = {
    "knight": (
        {"name": "run_rear_0", "source": "knight_run_rear_phase_0.png",
         "prompt": "Rear run cycle phase one; preserve the star cape, left shield, right sword and armor."},
        {"name": "run_rear_1", "source": "knight_run_rear_phase_1.png",
         "prompt": "Rear run cycle phase two; preserve the star cape, left shield, right sword and armor."},
        {"name": "jump_rear", "source": "knight_jump_rear.png",
         "prompt": "Airborne rear jump with both feet lifted and the cape rising."},
        {"name": "slide_rear", "source": "knight_slide_rear.png",
         "prompt": "Low rear running slide with knees bent and cape trailing."},
        {"name": "fall_rear", "source": "knight_fall_rear.png",
         "prompt": "Rear falling pose with arms open and legs trailing."},
        {"name": "attack_rear", "source": "knight_attack_rear.png",
         "prompt": "Rear sword strike with the shield held on the left."},
        {"name": "block_rear", "source": "knight_block_rear.png",
         "prompt": "Rear defensive pose with the shield raised."},
        {"name": "damage_rear", "source": "knight_damage_rear.png",
         "prompt": "Rear damage flinch with shoulders hunched and sword lowered."},
        {"name": "special_rear", "source": "knight_special_rear.png",
         "prompt": "Rear special-ability stance with sword and shield spread wide."},
        {"name": "land_rear", "source": "knight_land_rear.png",
         "prompt": "Rear landing recovery with both boots planted."},
        {"name": "dodge_rear", "source": "knight_dodge_rear.png",
         "prompt": "Rear sidestep dodge with the shield and sword held in their original hands."},
        {"name": "victory_rear", "source": "knight_victory_rear.png",
         "prompt": "Rear victory pose with the sword and shield raised."},
        {"name": "defeat_rear", "source": "knight_defeat_rear.png",
         "prompt": "Rear kneeling defeat pose with head bowed."},
        {"name": "dodge_right_rear", "source": "knight_dodge_right_rear.png",
         "prompt": "Rear sidestep dodge to the right, preserving shield and sword hands."},
    ),
    "gargoyle": (
        {"name": "run_rear_0", "source": "gargoyle_run_rear_phase_0.png",
         "prompt": "Rear run cycle phase one; preserve stone anatomy, horns, wings and star cloth."},
        {"name": "run_rear_1", "source": "gargoyle_run_rear_phase_1.png",
         "prompt": "Rear run cycle phase two; preserve stone anatomy, horns, wings and star cloth."},
        {"name": "jump_rear", "source": "gargoyle_jump_rear.png",
         "prompt": "Airborne rear jump with the wings spread and legs tucked."},
        {"name": "slide_rear", "source": "gargoyle_slide_rear.png",
         "prompt": "Low rear running slide with wings swept back."},
        {"name": "attack_rear", "source": "gargoyle_attack_rear.png",
         "prompt": "Rear punch attack with the wings open and feet braced."},
        {"name": "damage_rear", "source": "gargoyle_damage_rear.png",
         "prompt": "Rear damage flinch with hunched shoulders and wings drawn inward."},
        {"name": "special_rear", "source": "gargoyle_special_rear.png",
         "prompt": "Rear special stance with raised fists and high-spread wings."},
        {"name": "land_rear", "source": "gargoyle_land_rear.png",
         "prompt": "Rear landing recovery with claws planted and wings settling."},
        {"name": "dodge_rear", "source": "gargoyle_dodge_rear.png",
         "prompt": "Rear sidestep dodge balanced by the original wings."},
        {"name": "fall_rear", "source": "gargoyle_fall_rear.png",
         "prompt": "Rear fall pose with arms spread and legs trailing."},
        {"name": "block_rear", "source": "gargoyle_block_rear.png",
         "prompt": "Rear defensive block with arms crossed and wings folded."},
        {"name": "victory_rear", "source": "gargoyle_victory_rear.png",
         "prompt": "Rear victory pose with fists raised and wings open."},
        {"name": "defeat_rear", "source": "gargoyle_defeat_rear.png",
         "prompt": "Rear low defeat pose with head bowed and wings drooped."},
        {"name": "dodge_right_rear", "source": "gargoyle_dodge_right_rear.png",
         "prompt": "Rear sidestep dodge to the right, balanced by the wings."},
    ),
    "witch": (
        {"name": "run_rear_0", "source": "witch_run_rear_phase_0.png",
         "prompt": "Rear run cycle phase one; preserve the hat, braid, robe, pouch and right-hand staff."},
        {"name": "run_rear_1", "source": "witch_run_rear_phase_1.png",
         "prompt": "Rear run cycle phase two; preserve the hat, braid, robe, pouch and right-hand staff."},
        {"name": "jump_rear", "source": "witch_jump_rear.png",
         "prompt": "Airborne rear jump with bent knees, lifted robe and right-hand staff."},
        {"name": "slide_rear", "source": "witch_slide_rear.png",
         "prompt": "Rear low running slide with the right-hand staff and robe trailing."},
        {"name": "attack_rear", "source": "witch_attack_rear.png",
         "prompt": "Rear spell attack with the original staff thrust to the right."},
        {"name": "damage_rear", "source": "witch_damage_rear.png",
         "prompt": "Rear damage flinch with the staff lowered on the right."},
        {"name": "special_rear", "source": "witch_special_rear.png",
         "prompt": "Rear special stance with the original staff raised."},
        {"name": "land_rear", "source": "witch_land_rear.png",
         "prompt": "Rear landing recovery with both boots planted and staff held right."},
        {"name": "dodge_rear", "source": "witch_dodge_rear.png",
         "prompt": "Rear sidestep dodge with the original staff held right."},
        {"name": "fall_rear", "source": "witch_fall_rear.png",
         "prompt": "Rear fall pose with arms open and the staff held right."},
        {"name": "block_rear", "source": "witch_block_rear.png",
         "prompt": "Rear defensive block with the staff and left arm guarding."},
        {"name": "victory_rear", "source": "witch_victory_rear.png",
         "prompt": "Rear victory pose with the staff and left arm raised."},
        {"name": "defeat_rear", "source": "witch_defeat_rear.png",
         "prompt": "Rear kneeling defeat pose with staff lowered."},
        {"name": "dodge_right_rear", "source": "witch_dodge_right_rear.png",
         "prompt": "Rear sidestep dodge to the right with the staff still in her right hand."},
    ),
}
CYAN_KEY = (100, 205, 205, 25)
CYAN_FRINGE_PX = 10


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(path: Path) -> dict[str, object]:
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": sha256(path),
        "bytes": path.stat().st_size,
    }


def _remove_edge_connected_cyan(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    width, height = image.size
    pixels = image.load()
    visited = bytearray(width * height)
    queue: deque[int] = deque()
    red_limit, green_floor, blue_floor, channel_delta = CYAN_KEY

    def is_background(x: int, y: int) -> bool:
        red, green, blue, _alpha = pixels[x, y]
        return (
            red < red_limit
            and green > green_floor
            and blue > blue_floor
            and abs(green - blue) < channel_delta
        )

    for x in range(width):
        for y in (0, height - 1):
            if is_background(x, y):
                index = y * width + x
                if not visited[index]:
                    visited[index] = 1
                    queue.append(index)
    for y in range(height):
        for x in (0, width - 1):
            if is_background(x, y):
                index = y * width + x
                if not visited[index]:
                    visited[index] = 1
                    queue.append(index)

    while queue:
        index = queue.popleft()
        x, y = index % width, index // width
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                neighbor = ny * width + nx
                if not visited[neighbor] and is_background(nx, ny):
                    visited[neighbor] = 1
                    queue.append(neighbor)

    frontier = [index for index, is_background_pixel in enumerate(visited) if is_background_pixel]
    for _pass in range(CYAN_FRINGE_PX):
        next_frontier: list[int] = []
        for index in frontier:
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if not (0 <= nx < width and 0 <= ny < height):
                    continue
                neighbor = ny * width + nx
                red, green, blue, _alpha = pixels[nx, ny]
                cyan_fringe = (
                    red < 180
                    and green > 140
                    and blue > 140
                    and abs(green - blue) < 75
                )
                if not visited[neighbor] and cyan_fringe:
                    visited[neighbor] = 1
                    next_frontier.append(neighbor)
        frontier = next_frontier

    removed = 0
    for index, is_removed in enumerate(visited):
        if is_removed:
            x, y = index % width, index // width
            red, green, blue, _alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 0)
            removed += 1
    if removed < width * height // 4:
        raise ValueError("Expected the connected cyan studio background in pose source")
    return image


def _normalize_action_pose(
    source: Path, target_size: tuple[int, int]
) -> Image.Image:
    image = _remove_edge_connected_cyan(Image.open(source))
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"Pose source has no visible character: {source}")
    cropped = image.crop(bounds)
    scale = min(target_size[0] / cropped.width, target_size[1] / cropped.height)
    resized = cropped.resize(
        (round(cropped.width * scale), round(cropped.height * scale)),
        Image.Resampling.LANCZOS,
    )
    aligned = Image.new("RGBA", target_size, (0, 0, 0, 0))
    aligned.alpha_composite(
        resized,
        ((target_size[0] - resized.width) // 2, target_size[1] - resized.height),
    )
    return aligned


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
                    "This atlas contains only the exact approved front/rear views. "
                    "Generated action frames are kept in a separate action atlas "
                    "and tracked with their own provenance."
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
    entry["modifications"] = [
        "Cropped the six front/rear character views from the owner-provided approved sheet and removed only edge-connected pale background.",
        "Preserved older locally drawn action studies as source material; they are not loaded by current gameplay.",
        "Packed the approved front/rear cutouts into per-character atlases without changing any character pixels; gameplay reads the atlas regions.",
        "Source-conditioned rear action poses are tracked separately from the exact approved front/rear concept cutouts.",
        "Use is limited to noncommercial distribution as part of MysticRun; commercial use is not authorized.",
        "Required credit: Character illustrations: MysticRun owner-provided concept art and generated source-conditioned poses; noncommercial game use only.",
    ]
    records = {item["path"]: item for item in entry["files"]}
    for item in manifest.values():
        atlas_record = item["atlas"]
        records[atlas_record["path"]] = atlas_record
    entry["files"] = sorted(records.values(), key=lambda item: item["path"])
    registry_path.write_text(json.dumps(registry, indent=2) + "\n")
    return manifest


def build_action_atlases(root: Path = ROOT) -> dict[str, dict[str, object]]:
    source_dir = root / "art/premium-2d/source"
    output_dir = root / "assets/characters/action-atlases"
    output_dir.mkdir(parents=True, exist_ok=True)
    characters: dict[str, dict[str, object]] = {}

    for character, poses in POSE_SOURCES.items():
        rear_path = root / f"assets/characters/concept-sprites/{character}_rear.png"
        with Image.open(rear_path) as rear_image:
            frame_size = rear_image.size
        frames: list[tuple[dict[str, str], Image.Image]] = []
        for pose in poses:
            source = source_dir / pose["source"]
            frames.append((pose, _normalize_action_pose(source, frame_size)))

        gutter = 4
        columns = min(4, len(frames))
        rows = (len(frames) + columns - 1) // columns
        atlas_width = columns * frame_size[0] + gutter * (columns - 1)
        atlas_height = rows * frame_size[1] + gutter * (rows - 1)
        atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
        frame_manifest: dict[str, dict[str, object]] = {}
        for index, (pose, frame) in enumerate(frames):
            x = (index % columns) * (frame.width + gutter)
            y = (index // columns) * (frame.height + gutter)
            atlas.alpha_composite(frame, (x, y))
            frame_manifest[pose["name"]] = {
                "region": [x, y, frame.width, frame.height],
                "source": record(source_dir / pose["source"]),
                "prompt_summary": pose["prompt"],
            }

        atlas_path = output_dir / f"{character}_actions.png"
        atlas.save(atlas_path, optimize=True)
        characters[character] = {
            "atlas": record(atlas_path),
            "atlas_dimensions": list(atlas.size),
            "frame_size": list(frame_size),
            "gutter_px": gutter,
            "columns": columns,
            "rows": rows,
            "frames": frame_manifest,
        }

    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(json.dumps({
        "schema": 1,
        "generator": "Replit image-editing tool",
        "pipeline": "tools/build_premium_2d_assets.py",
        "source_authority": "references/01-character-concept.png",
        "source_sha256": sha256(root / "references/01-character-concept.png"),
        "commercial_use_claimed": False,
        "background_processing": "Remove only edge-connected bright cyan studio background; crop and bottom-align to the approved rear frame size.",
        "characters": characters,
    }, indent=2) + "\n")

    registry_path = root / "assets/asset_registry.json"
    registry = json.loads(registry_path.read_text())
    registry["coverage_roots"] = list(dict.fromkeys(
        registry["coverage_roots"] + ["assets/characters/action-atlases"]
    ))
    license_evidence = record(root / BACKGROUND_LICENSE)
    entry = next(
        (item for item in registry["assets"] if item["id"] == POSE_ASSET_ID),
        None,
    )
    if entry is None:
        entry = {
            "cost_usd": 0,
            "commercial_use": False,
            "modification": True,
            "game_distribution": True,
            "attribution_required": False,
            "id": POSE_ASSET_ID,
            "publisher": "Replit image-editing tool",
            "license": "LicenseRef-MysticRun-Replit-Generated-NonCommercial",
            "sources": [],
            "edition": "Source-conditioned for noncommercial MysticRun use",
            "license_evidence": license_evidence,
            "modifications": [],
            "derived_from": ["mysticrun-owner-provided-concept-sprites"],
            "files": [],
        }
        registry["assets"].append(entry)
    entry["sources"] = list(dict.fromkeys(entry["sources"] + [
        "references/01-character-concept.png",
        "tools/build_premium_2d_assets.py",
        "assets/characters/action-atlases/manifest.json",
        *[frame["source"]["path"] for character in characters.values()
          for frame in character["frames"].values()],
    ]))
    entry["license_evidence"] = license_evidence
    entry["modifications"] = [
        "Created source-conditioned rear run, jump, fall, landing, slide, dodge, attack, block, damage, defeat, victory, and special poses for all three heroes, guided by the owner-provided concept sheet.",
        "Removed edge-connected cyan studio backgrounds, normalized each pose to its original rear-frame dimensions, and packed the frames into compact grid atlases.",
        "Use is recorded as noncommercial MysticRun artwork; no commercial-use claim is made.",
    ]
    records = {item["path"]: item for item in entry["files"]}
    for character in characters.values():
        records[character["atlas"]["path"]] = character["atlas"]
        for frame in character["frames"].values():
            source_record = frame["source"]
            records[source_record["path"]] = source_record
    records[manifest_path.relative_to(root).as_posix()] = record(manifest_path)
    entry["files"] = sorted(records.values(), key=lambda item: item["path"])
    registry_path.write_text(json.dumps(registry, indent=2) + "\n")
    return characters


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
    action_atlases = build_action_atlases(args.root)
    backgrounds = build_backgrounds(args.root)
    print(
        f"PREMIUM_2D_ASSETS_PASS atlases={len(atlases)} "
        f"backdrops={len(backgrounds)} "
        f"action_pose_frames={sum(len(item['frames']) for item in action_atlases.values())}"
    )


if __name__ == "__main__":
    main()
