#!/usr/bin/env python3
"""Lossless painted-part extraction. Never synthesize poses or overwrite source."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/characters/concept-sprites/knight_rear.png"
OUT = ROOT / "experiments/knight_rig/art"
# Joint positions are authored in the original 306x361 rear-view painting.
# Overlapping cuts keep the visible joint surfaces covered as they rotate.
PARTS = [
    ("pelvis", "", (142, 219), 0, [(76, 194), (178, 190), (198, 233), (81, 241)]),
    ("thigh_l", "pelvis", (108, 222), 1, [(91, 207), (131, 216), (113, 260), (77, 260)]),
    ("shin_l", "thigh_l", (95, 266), 2, [(77, 250), (115, 256), (96, 313), (87, 334), (52, 335), (64, 303)]),
    ("boot_l", "shin_l", (77, 326), 3, [(62, 310), (93, 316), (99, 344), (91, 351), (44, 351), (46, 332)]),
    ("thigh_r", "pelvis", (169, 222), 1, [(148, 211), (180, 207), (200, 260), (163, 260)]),
    ("shin_r", "thigh_r", (185, 266), 2, [(168, 253), (198, 251), (207, 305), (216, 332), (182, 337), (175, 298)]),
    ("boot_r", "shin_r", (195, 327), 3, [(176, 312), (208, 309), (218, 328), (234, 339), (233, 351), (177, 351)]),
    ("torso", "pelvis", (141, 113), 4, [(96, 78), (161, 76), (184, 115), (178, 185), (162, 222), (93, 221), (78, 161)]),
    ("cape", "torso", (135, 91), 6, [(105, 81), (157, 80), (169, 101), (174, 140), (188, 184), (197, 214), (167, 226), (139, 225), (112, 215), (91, 224), (74, 214), (48, 225), (61, 187), (78, 155), (92, 109)]),
    ("shield", "torso", (96, 105), 7, [(84, 86), (111, 89), (114, 118), (99, 144), (96, 193), (60, 250), (46, 238), (31, 204), (26, 163), (31, 138), (59, 112), (78, 121)]),
    ("upperarm_r", "torso", (184, 107), 7, [(168, 87), (195, 87), (204, 112), (199, 135), (219, 149), (204, 164), (183, 145), (179, 122), (169, 116)]),
    ("forearm_r", "upperarm_r", (202, 149), 8, [(192, 136), (211, 134), (219, 156), (220, 175), (235, 184), (229, 208), (210, 207), (199, 193), (203, 177), (193, 159)]),
    ("sword", "forearm_r", (223, 202), 9, [(219, 192), (238, 197), (242, 221), (302, 318), (294, 323), (220, 237), (212, 222), (208, 214)]),
    ("head", "torso", (144, 82), 10, [(77, 1), (179, 1), (189, 67), (175, 86), (112, 89), (103, 71), (78, 69)]),
]


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    # A small enclosed backdrop island remains between the upper legs. Use an
    # explicit negative-space mask: pink bounce-light also exists on the steel
    # boots/blade, so global color-key cleanup would punch holes in the armor.
    cleaned_alpha = source.getchannel("A")
    ImageDraw.Draw(cleaned_alpha).polygon(
        [(129, 233), (147, 237), (155, 233), (158, 253), (123, 253)], fill=0)
    atlas = Image.new("RGBA", (1024, 512))
    parts = []
    x = y = row_h = 0
    for name, parent, joint, z, polygon in PARTS:
        mask = Image.new("L", source.size)
        ImageDraw.Draw(mask).polygon(polygon, fill=255)
        alpha = ImageChops.multiply(mask, cleaned_alpha)
        box = alpha.getbbox()
        layer = source.copy()
        layer.putalpha(alpha)
        layer = layer.crop(box)
        w, h = layer.size
        if x + w + 4 > atlas.width:
            x = 0
            y += row_h + 4
            row_h = 0
        if y + h + 4 > atlas.height:
            raise ValueError("Layer atlas overflow")
        atlas.paste(layer, (x + 2, y + 2))
        parts.append(dict(name=name, parent=parent, joint=list(joint), z=z,
                          source_rect=list(box), region=[x + 2, y + 2, w, h],
                          polygon=polygon))
        x += w + 4
        row_h = max(row_h, h)
    atlas.save(OUT / "knight_layers.png", optimize=True)
    manifest = dict(source=str(SOURCE.relative_to(ROOT)),
                    source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                    method="original painted pixels, hand-authored overlapping masks; no AI repaint",
                    license="Original concept: noncommercial game use only",
                    source_size=list(source.size), viewport_size=[384, 448],
                    offset=[39, 40], ground_y=351, parts=parts)
    (OUT / "rig.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(parts)} original painted parts into one 1024x512 atlas")


if __name__ == "__main__":
    build()
