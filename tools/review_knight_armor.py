#!/usr/bin/env python3
"""Compare actual MR-ART-038 GLBs and matched, game-owned Godot captures."""
import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from verify_knight_glb import MORPHS, load_glb, stream


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def unchanged_regions(glb):
    """Witness unchanged geometry/paint/weights/morphs outside upper armor.

    Canonical records ignore exported vertex ordering and normal-split duplicates.
    Upperarm and spine_03 groups include the intentionally replaced armor, so
    they are excluded. This is not a triangle-intersection or clip detector.
    """
    _, doc, binary = load_glb(glb)
    joint_names = [doc["nodes"][n]["name"] for n in doc["skins"][0]["joints"]]
    regions = defaultdict(set)
    for primitive in doc["meshes"][0]["primitives"]:
        attrs = {name: stream(doc, binary, index) for name, index in primitive["attributes"].items()}
        morphs = [stream(doc, binary, target["POSITION"]) for target in primitive["targets"]]
        for i, weights in enumerate(attrs["WEIGHTS_0"]):
            skin = tuple(sorted((joint_names[j], round(w, 6)) for j, w in
                                zip(attrs["JOINTS_0"][i], weights) if w > .000001))
            if any(name in ("spine_03", "upperarm_l", "upperarm_r") for name, _ in skin):
                continue
            values = [attrs[name][i] for name in ("POSITION", "COLOR_0", "TEXCOORD_0", "TEXCOORD_1")]
            values += [target[i] for target in morphs]
            record = (skin, tuple(round(v, 6) for row in values for v in row))
            region = "+".join(name for name, _ in skin)
            regions[region].add(record)
    assert regions and "Head" in regions, "Missing unchanged-region witness"
    return {name: {"canonical_vertices": len(records),
                   "sha256": hashlib.sha256(json.dumps(sorted(records)).encode()).hexdigest()}
            for name, records in sorted(regions.items())}


def make_sheet(before, after, views, output, title, crop=None):
    font = ImageFont.load_default(size=20)
    small = ImageFont.load_default(size=16)
    width, height = 540, 960
    if crop:
        width, height = crop[2]-crop[0], crop[3]-crop[1]
    canvas = Image.new("RGB", (width*2, 116+(height+38)*len(views)), "#171c29")
    draw = ImageDraw.Draw(canvas)
    draw.text((18, 14), title, font=font, fill="white")
    draw.text((18, 46), "SOURCE BASELINE - 24,350 tris", font=small, fill="#d9dfee")
    draw.text((width+18, 46), "MR-ART-038 - 23,242 tris", font=small, fill="#d9dfee")
    draw.text((18, 78), "Actual Godot 4.7.2 frames | TECHNICAL PASS / VISUAL HOLD", font=small, fill="#f2cc8f")
    for row, view in enumerate(views):
        y = 116+row*(height+38)
        for column, root in enumerate((before, after)):
            path = root / view
            with Image.open(path) as image:
                assert image.size == (540, 960), f"Capture dimensions changed: {path}"
                image = image.convert("RGB")
                if crop:
                    image = image.crop(crop)
                canvas.paste(image, (column*width, y+30))
            draw.text((column*width+12, y+4), path.stem, font=small, fill="white")
    canvas.save(output, quality=88)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--before-glb", type=Path, required=True,
                        help="Rebuild of unchanged source with the same Blender version")
    parser.add_argument("--after-glb", type=Path, default=Path("assets/characters/knight/knight.glb"))
    parser.add_argument("--before-renders", type=Path, required=True)
    parser.add_argument("--after-renders", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    before = unchanged_regions(args.before_glb)
    after = unchanged_regions(args.after_glb)
    assert before == after, "Non-upper-armor geometry, skinning, paint or morph positions changed"
    before_benchmark = json.loads((args.before_renders/"chase/benchmark.json").read_text())
    after_benchmark = json.loads((args.after_renders/"chase/benchmark.json").read_text())
    assert before_benchmark == after_benchmark, "Matched chase-camera benchmark changed"
    assert after_benchmark["selected_character_preserved"] is True
    make_sheet(args.before_renders/"stage", args.after_renders/"stage",
               ["knight-front.png", "knight-side.png", "knight-rear.png"],
               args.output/"upper-armor-comparison.jpg", "Knight replacement-first upper armor",
               crop=(100, 230, 450, 640))
    make_sheet(args.before_renders/"chase", args.after_renders/"chase",
               ["knight-benchmark-0040.png"], args.output/"chase-comparison.jpg",
               "Matched actual chase camera - frame 40")
    make_sheet(args.before_renders/"stage", args.after_renders/"stage",
               ["knight-run.png", "knight-attack.png", "knight-jump.png", "knight-slide.png"],
               args.output/"action-comparison.jpg", "Sampled animation / armor clearance views",
               crop=(70, 220, 525, 835))
    captures = []
    for label, root in [("source-baseline", args.before_renders), ("after", args.after_renders)]:
        for image in sorted(root.rglob("*.png")):
            captures.append({"set": label, "path": image.relative_to(root).as_posix(),
                             "sha256": digest(image), "bytes": image.stat().st_size})
    report = {
        "status": "TECHNICAL PASS / VISUAL HOLD",
        "concept_binary_available": False,
        "visual_approval_blocker": "Approved 1000048042.png and references/01-character-concept.png absent",
        "before_glb_sha256": digest(args.before_glb), "after_glb_sha256": digest(args.after_glb),
        "preserved_non_upper_armor_regions": before,
        "preserved_attributes": ["positions", "vertex paint", "UV", "metallic/roughness",
                                 "skin weights", *MORPHS],
        "excluded_from_region_witness": ["spine_03", "upperarm_l", "upperarm_r"],
        "matched_benchmark": after_benchmark, "captures": captures,
        "limitations": ["No approved-concept side-by-side certification",
                        "Sampled action stills and existing rig/slide checks are not an exhaustive self-intersection test",
                        "No physical Android performance or full-animation art approval"],
    }
    (args.output/"capture-and-region-report.json").write_text(json.dumps(report, indent=2)+"\n")
    print("KNIGHT_ARMOR_REVIEW_PASS", len(before), "unchanged regions;", len(captures), "actual Godot captures")


if __name__ == "__main__":
    main()
