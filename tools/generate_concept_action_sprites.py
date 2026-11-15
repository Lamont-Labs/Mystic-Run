#!/usr/bin/env python3
"""Draw noncommercial, source-controlled action frames with Pillow only.

The illustrations are assembled from local vector-like drawing primitives;
this script makes no network calls and uses no external image service.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/characters/concept-sprites"
SCALE = 3
WIDTH, HEIGHT = 320, 384
Y_OFFSET = 68
POSES = ("run_0", "run_1", "jump", "slide", "attack", "landing", "power")
LICENSE = ROOT / "assets/licenses/mysticrun-owner-provided-noncommercial.txt"
REGISTRY = ROOT / "assets/asset_registry.json"
ASSET_ID = "mysticrun-owner-provided-concept-sprites"
CREDIT = (
    "Character illustrations: MysticRun owner-provided concept art and "
    "locally generated action-pose artwork; noncommercial game use only."
)

INK = "#28344b"
GOLD = "#f6c75e"
PALE_GOLD = "#fff0bd"
SILVER = "#d6e7f3"
STEEL = "#5688ad"
BLUE = "#3474a0"
SKIN = "#f3bd9d"
RED = "#df596c"
PURPLE = "#7144a0"
LILAC = "#b58ddd"
MINT = "#86bbaa"
STONE = "#82958c"


def points(values: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(round(x * SCALE), round((y + Y_OFFSET) * SCALE)) for x, y in values]


class Canvas:
    def __init__(self) -> None:
        self.image = Image.new("RGBA", (WIDTH * SCALE, HEIGHT * SCALE), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)

    def poly(self, coords: list[tuple[float, float]], color: str,
             outline: str = INK, width: float = 2.2) -> None:
        self.draw.polygon(points(coords), fill=color)
        self.draw.line(points(coords + [coords[0]]), fill=outline,
                       width=max(1, round(width * SCALE)), joint="curve")

    def line(self, coords: list[tuple[float, float]], color: str,
             width: float = 5.0, outline: str | None = INK) -> None:
        if outline:
            self.draw.line(points(coords), fill=outline,
                           width=max(1, round((width + 2.4) * SCALE)), joint="curve")
        self.draw.line(points(coords), fill=color,
                       width=max(1, round(width * SCALE)), joint="curve")
        radius = width * SCALE / 2
        for x, y in (coords[0], coords[-1]):
            cx, cy = round(x * SCALE), round((y + Y_OFFSET) * SCALE)
            self.draw.ellipse((cx-radius, cy-radius, cx+radius, cy+radius),
                              fill=color, outline=outline,
                              width=max(1, round(1.5 * SCALE)) if outline else 1)

    def ellipse(self, box: tuple[float, float, float, float], color: str,
                outline: str = INK, width: float = 2.0) -> None:
        x1, y1, x2, y2 = box
        self.draw.ellipse((round(x1*SCALE), round((y1+Y_OFFSET)*SCALE),
                           round(x2*SCALE), round((y2+Y_OFFSET)*SCALE)),
                          fill=color, outline=outline,
                          width=max(1, round(width*SCALE)))

    def finish(self) -> Image.Image:
        return self.image.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)


def skeleton(pose: str) -> dict[str, tuple[float, float]]:
    poses = {
        "run_0": {
            "head": (157, 93), "sl": (135, 137), "sr": (185, 137),
            "hl": (143, 192), "hr": (181, 194),
            "el": (108, 157), "wl": (91, 135), "er": (209, 115), "wr": (229, 91),
            "kl": (111, 232), "al": (82, 278), "kr": (214, 219), "ar": (245, 263),
        },
        "run_1": {
            "head": (157, 93), "sl": (135, 137), "sr": (185, 137),
            "hl": (143, 192), "hr": (181, 194),
            "el": (108, 115), "wl": (91, 91), "er": (209, 157), "wr": (229, 135),
            "kl": (111, 219), "al": (82, 263), "kr": (214, 232), "ar": (245, 278),
        },
        "jump": {
            "head": (158, 74), "sl": (135, 117), "sr": (185, 117),
            "hl": (143, 172), "hr": (181, 174),
            "el": (111, 91), "wl": (96, 68), "er": (208, 91), "wr": (225, 67),
            "kl": (112, 211), "al": (84, 200), "kr": (214, 207), "ar": (243, 195),
        },
        "slide": {
            "head": (82, 216), "sl": (116, 198), "sr": (165, 199),
            "hl": (153, 229), "hr": (191, 231),
            "el": (92, 231), "wl": (76, 246), "er": (155, 242), "wr": (174, 251),
            "kl": (219, 231), "al": (253, 248), "kr": (211, 250), "ar": (246, 270),
        },
        "attack": {
            "head": (148, 105), "sl": (126, 150), "sr": (178, 147),
            "hl": (136, 205), "hr": (176, 207),
            "el": (96, 171), "wl": (77, 193), "er": (205, 157), "wr": (240, 164),
            "kl": (111, 247), "al": (91, 294), "kr": (208, 239), "ar": (226, 287),
        },
        "landing": {
            "head": (158, 126), "sl": (132, 162), "sr": (184, 162),
            "hl": (143, 211), "hr": (181, 211),
            "el": (105, 186), "wl": (79, 204), "er": (211, 184), "wr": (239, 202),
            "kl": (116, 241), "al": (101, 265), "kr": (211, 241), "ar": (229, 265),
        },
        "power": {
            "head": (158, 88), "sl": (132, 132), "sr": (184, 132),
            "hl": (143, 188), "hr": (181, 190),
            "el": (107, 111), "wl": (91, 79), "er": (211, 108), "wr": (231, 66),
            "kl": (111, 229), "al": (94, 276), "kr": (212, 225), "ar": (241, 270),
        },
    }
    return poses[pose]


def mid(a: tuple[float, float], b: tuple[float, float],
        dx: float = 0, dy: float = 0) -> tuple[float, float]:
    return ((a[0] + b[0]) / 2 + dx, (a[1] + b[1]) / 2 + dy)


def draw_limb(c: Canvas, shoulder: tuple[float, float], elbow: tuple[float, float],
              wrist: tuple[float, float], color: str, width: float = 12) -> None:
    c.line([shoulder, elbow, wrist], color, width)
    c.ellipse((wrist[0]-7, wrist[1]-7, wrist[0]+7, wrist[1]+7),
              color, INK, 2)


def draw_legs(c: Canvas, j: dict[str, tuple[float, float]], kind: str) -> None:
    hip_l, hip_r = j["hl"], j["hr"]
    for hip, knee, ankle in ((hip_l, j["kl"], j["al"]), (hip_r, j["kr"], j["ar"])):
        if kind == "knight":
            color, boot = BLUE, STEEL
        elif kind == "gargoyle":
            color, boot = STONE, MINT
        else:
            color, boot = PURPLE, "#3f315e"
        c.line([hip, knee, ankle], color, 17 if kind == "gargoyle" else 13)
        c.line([hip, knee], "#ffffff" if kind == "knight" else color,
               2.2, None)
        foot = [(ankle[0]-9, ankle[1]-1), (ankle[0]+12, ankle[1]-2),
                (ankle[0]+16, ankle[1]+7), (ankle[0]-11, ankle[1]+8)]
        c.poly(foot, boot)
        if kind == "knight":
            c.line([(ankle[0]-7, ankle[1]+1), (ankle[0]+10, ankle[1]+1)], GOLD, 2, None)
        elif kind == "gargoyle":
            for offset in (-7, 0, 7):
                c.poly([(ankle[0]+9, ankle[1]+1+offset/4),
                        (ankle[0]+19, ankle[1]+4+offset/4),
                        (ankle[0]+11, ankle[1]+7+offset/4)], PALE_GOLD, INK, 1)
        else:
            c.line([(ankle[0]-7, ankle[1]+2), (ankle[0]+10, ankle[1]+2)], GOLD, 2, None)


def torso_shape(j: dict[str, tuple[float, float]], inset: float = 0) -> list[tuple[float, float]]:
    return [
        (j["sl"][0]-9+inset, j["sl"][1]-3),
        (j["sr"][0]+9-inset, j["sr"][1]-3),
        (j["hr"][0]+5-inset, j["hr"][1]+10),
        (j["hl"][0]-5+inset, j["hl"][1]+10),
    ]


def draw_knight(c: Canvas, j: dict[str, tuple[float, float]], pose: str,
                rear: bool) -> None:
    h = j["head"]
    shoulders = mid(j["sl"], j["sr"])
    hips = mid(j["hl"], j["hr"])
    cape = [(shoulders[0]-22, shoulders[1]+3), (shoulders[0]+22, shoulders[1]+3),
            (hips[0]+20, hips[1]+49), (hips[0]-27, hips[1]+54)]
    c.poly(cape, "#c64559")
    c.poly([(shoulders[0]-13, shoulders[1]+8), (shoulders[0]+12, shoulders[1]+8),
            (hips[0]+4, hips[1]+44), (hips[0]-13, hips[1]+46)], RED, "#a8354e", 1.3)
    if rear:
        c.poly([(hips[0]-8, hips[1]+17), (hips[0]+8, hips[1]+17),
                (hips[0]+5, hips[1]+28), (hips[0]-5, hips[1]+28)], GOLD, INK, 1)
    draw_legs(c, j, "knight")
    draw_limb(c, j["sl"], j["el"], j["wl"], STEEL, 13)
    draw_limb(c, j["sr"], j["er"], j["wr"], SILVER, 13)
    c.poly(torso_shape(j), BLUE)
    c.poly([(j["sl"][0]+3, j["sl"][1]+5), (j["sr"][0]-3, j["sr"][1]+5),
            (j["hr"][0]-3, j["hr"][1]+3), (j["hl"][0]+3, j["hl"][1]+3)], STEEL, INK, 1.5)
    c.poly([(shoulders[0], shoulders[1]+7), (shoulders[0]+15, shoulders[1]+17),
            (hips[0]+8, hips[1]+5), (hips[0]-11, hips[1]+7)], SILVER, INK, 1.7)
    c.poly([(hips[0]-7, hips[1]+13), (hips[0]+8, hips[1]+12),
            (hips[0]+12, hips[1]+25), (hips[0]-10, hips[1]+25)], "#704c3c")
    for x in (hips[0]-5, hips[0]+7):
        c.ellipse((x-2, hips[1]+15, x+2, hips[1]+19), GOLD, INK, 0.8)
    # Star shield on the forward arm and a tapered sword on the other.
    sw = j["wl"]
    c.poly([(sw[0]-11, sw[1]-15), (sw[0]+10, sw[1]-13),
            (sw[0]+13, sw[1]+1), (sw[0], sw[1]+17),
            (sw[0]-13, sw[1]+3)], "#39719d")
    star = [(sw[0], sw[1]-8), (sw[0]+2, sw[1]-2), (sw[0]+8, sw[1]-2),
            (sw[0]+3, sw[1]+2), (sw[0]+5, sw[1]+8), (sw[0], sw[1]+4),
            (sw[0]-5, sw[1]+8), (sw[0]-3, sw[1]+2), (sw[0]-8, sw[1]-2),
            (sw[0]-2, sw[1]-2)]
    c.poly(star, GOLD, PALE_GOLD, 0.8)
    sword_base = j["wr"]
    if pose in ("attack", "power"):
        if pose == "power":
            tip = (sword_base[0]+10, sword_base[1]-67)
        else:
            tip = (sword_base[0]+52, sword_base[1]-4)
    elif pose.startswith("run"):
        tip = (sword_base[0]+21, sword_base[1]-31)
    elif pose == "jump":
        tip = (sword_base[0]+28, sword_base[1]-34)
    else:
        tip = (sword_base[0]+31, sword_base[1]-8)
    c.poly([sword_base, (sword_base[0]+5, sword_base[1]-5),
            (tip[0]+2, tip[1]-3), tip], SILVER)
    if pose in ("attack", "power"):
        c.line([(tip[0]-13, tip[1]-13), (tip[0]-3, tip[1]-9)], PALE_GOLD, 2.2, None)
        c.line([(tip[0]-7, tip[1]+8), (tip[0]+4, tip[1]+7)], "#8deaff", 2.2, None)
        c.line([(tip[0]+4, tip[1]-14), (tip[0]+11, tip[1]-8)], PALE_GOLD, 2.2, None)
    if pose == "landing":
        for offset in (-1, 1):
            c.line([(j["al"][0]+offset*13, j["al"][1]+5),
                    (j["al"][0]+offset*25, j["al"][1]+2)], PALE_GOLD, 2, None)
            c.line([(j["ar"][0]+offset*13, j["ar"][1]+5),
                    (j["ar"][0]+offset*25, j["ar"][1]+2)], PALE_GOLD, 2, None)
    elif pose == "power":
        c.line([(tip[0]-18, tip[1]+13), (tip[0]-7, tip[1]+5),
                (tip[0]+5, tip[1]+2), (tip[0]+17, tip[1]+8)], "#8deaff", 3, None)
    c.line([(sword_base[0]-5, sword_base[1]+4),
            (sword_base[0]+9, sword_base[1]-8)], GOLD, 3)
    c.ellipse((h[0]-17, h[1]-22, h[0]+17, h[1]+20), SKIN, INK, 2)
    c.poly([(h[0]-20, h[1]-4), (h[0]-19, h[1]-22), (h[0]-7, h[1]-33),
            (h[0]+10, h[1]-31), (h[0]+20, h[1]-18), (h[0]+17, h[1]-4)], STEEL)
    c.poly([(h[0]-13, h[1]-20), (h[0]+13, h[1]-20),
            (h[0]+10, h[1]-11), (h[0]-11, h[1]-11)], SILVER, INK, 1.4)
    c.line([(h[0], h[1]-28), (h[0], h[1]-12)], GOLD, 2.1)
    if not rear:
        c.ellipse((h[0]-8, h[1]-1, h[0]-4, h[1]+3), INK, INK, 0.5)
        c.ellipse((h[0]+4, h[1]-1, h[0]+8, h[1]+3), INK, INK, 0.5)
        c.line([(h[0]-5, h[1]+9), (h[0]+5, h[1]+9)], "#a85458", 1.5, None)
    else:
        c.poly([(h[0]-9, h[1]-20), (h[0]+11, h[1]-20),
                (h[0]+10, h[1]+15), (h[0]-10, h[1]+15)], "#47728f", INK, 1)
    # Red ponytail plume stays visible from front and rear.
    c.poly([(h[0]-9, h[1]-29), (h[0]-23, h[1]-43),
            (h[0]-29, h[1]-29), (h[0]-24, h[1]-16)], RED, "#a83d51", 1.3)
    c.ellipse((h[0]-13, h[1]-32, h[0]+13, h[1]-27), GOLD, INK, 1)


def draw_gargoyle(c: Canvas, j: dict[str, tuple[float, float]], pose: str,
                  rear: bool) -> None:
    h = j["head"]
    sl, sr = j["sl"], j["sr"]
    wings = {
        "run_0": (54, -29, 268, -31), "run_1": (62, -23, 257, -25),
        "jump": (22, -66, 297, -63), "slide": (80, 2, 249, 5),
        "attack": (44, -36, 286, -27), "landing": (68, 4, 252, 4),
        "power": (14, -69, 304, -67),
    }[pose]
    left_tip = (wings[0], sl[1]+wings[1])
    right_tip = (wings[2], sr[1]+wings[3])
    c.poly([sl, (sl[0]-14, sl[1]-19), (sl[0]-33, sl[1]-39),
            left_tip, (sl[0]+5, sl[1]+33)], "#765c94", "#394759", 3)
    c.poly([sr, (sr[0]+14, sr[1]-19), (sr[0]+33, sr[1]-39),
            right_tip, (sr[0]-5, sr[1]+33)], "#8c70a9", "#394759", 3)
    for end in (left_tip, right_tip):
        c.line([mid(sl, sr), end], "#c2a2d2", 2, "#5b4a73")
    draw_legs(c, j, "gargoyle")
    draw_limb(c, sl, j["el"], j["wl"], STONE, 22)
    draw_limb(c, sr, j["er"], j["wr"], "#91a69a", 22)
    for wrist in (j["wl"], j["wr"]):
        for dx in (-5, 1, 7):
            c.poly([(wrist[0]+dx, wrist[1]+2), (wrist[0]+dx+4, wrist[1]+5),
                    (wrist[0]+dx+7, wrist[1]+14)], PALE_GOLD, INK, 1)
    if pose in ("attack", "power"):
        for offset in (-9, 0, 9):
            c.line([(j["wr"][0]+10, j["wr"][1]+offset),
                    (j["wr"][0]+22, j["wr"][1]+offset-3)],
                   "#8deaff" if pose == "power" else PALE_GOLD, 2, None)
    if pose == "landing":
        for x in (j["al"][0], j["ar"][0]):
            c.line([(x-19, 278), (x-8, 275)], PALE_GOLD, 2, None)
            c.line([(x+8, 275), (x+19, 278)], PALE_GOLD, 2, None)
    elif pose == "power":
        c.ellipse((h[0]-31, h[1]-29, h[0]+31, h[1]+32), None, "#8deaff", 2)
        c.ellipse((h[0]-39, h[1]-37, h[0]+39, h[1]+40), None, PALE_GOLD, 1)
    c.poly(torso_shape(j), STONE, "#3d4e54", 3)
    shoulder_mid = mid(sl, sr)
    hip_mid = mid(j["hl"], j["hr"])
    c.poly([(shoulder_mid[0]-14, shoulder_mid[1]+7),
            (shoulder_mid[0]+14, shoulder_mid[1]+7),
            (hip_mid[0]+13, hip_mid[1]+14), (hip_mid[0]-13, hip_mid[1]+14)],
           "#9daf9f", "#40534f", 2)
    for offset in (-11, 0, 11):
        c.line([(shoulder_mid[0]+offset, shoulder_mid[1]+13),
                (hip_mid[0]+offset*.7, hip_mid[1]+5)], "#d0d4b9", 2, "#667871")
    c.poly([(hip_mid[0]-18, hip_mid[1]+11), (hip_mid[0]+18, hip_mid[1]+11),
            (hip_mid[0]+26, hip_mid[1]+46), (hip_mid[0]+3, hip_mid[1]+38),
            (hip_mid[0]-19, hip_mid[1]+47)], PURPLE, "#44334f", 2)
    c.poly([(hip_mid[0]-3, hip_mid[1]+14), (hip_mid[0]+5, hip_mid[1]+15),
            (hip_mid[0]+3, hip_mid[1]+34), (hip_mid[0]-4, hip_mid[1]+34)], GOLD, INK, 1)
    c.ellipse((h[0]-19, h[1]-17, h[0]+19, h[1]+21), STONE, "#3d4e54", 3)
    c.poly([(h[0]-17, h[1]-9), (h[0]-31, h[1]-29),
            (h[0]-13, h[1]-20), (h[0]-6, h[1]-12)], "#9dac9d")
    c.poly([(h[0]+17, h[1]-9), (h[0]+31, h[1]-29),
            (h[0]+13, h[1]-20), (h[0]+6, h[1]-12)], "#aab5a1")
    if not rear:
        c.ellipse((h[0]-12, h[1]-1, h[0]-5, h[1]+5), "#ffcf5f", INK, 1)
        c.ellipse((h[0]+5, h[1]-1, h[0]+12, h[1]+5), "#ffcf5f", INK, 1)
        c.line([(h[0]-7, h[1]+12), (h[0], h[1]+15), (h[0]+8, h[1]+11)],
               "#536762", 2, None)
        for x in (h[0]-4, h[0]+4):
            c.poly([(x-2, h[1]+13), (x+2, h[1]+13), (x, h[1]+19)], PALE_GOLD, INK, 1)
    else:
        c.poly([(h[0]-12, h[1]-13), (h[0]+12, h[1]-13),
                (h[0]+14, h[1]+16), (h[0]-13, h[1]+16)], "#91a69a", "#44565a", 2)
        c.line([(h[0], h[1]-11), (h[0]-2, h[1]+14)], "#d0d4b9", 2, None)


def draw_witch(c: Canvas, j: dict[str, tuple[float, float]], pose: str,
               rear: bool) -> None:
    h = j["head"]
    shoulders = mid(j["sl"], j["sr"])
    hips = mid(j["hl"], j["hr"])
    draw_legs(c, j, "witch")
    # Split robe panels move with the hip and keep the legs readable.
    c.poly([(j["sl"][0]-8, j["sl"][1]), (j["sr"][0]+8, j["sr"][1]),
            (hips[0]+24, hips[1]+49), (hips[0]+3, hips[1]+37),
            (hips[0]-19, hips[1]+52), (hips[0]-25, hips[1]+10)], PURPLE, "#42304f", 2.5)
    c.poly([(shoulders[0]-5, shoulders[1]+4),
            (shoulders[0]+7, shoulders[1]+4), (hips[0]+1, hips[1]+31),
            (hips[0]-6, hips[1]+39)], "#895ab3", "#513b68", 1.5)
    c.line([(hips[0]-18, hips[1]+27), (hips[0]+20, hips[1]+27)], GOLD, 2, None)
    draw_limb(c, j["sl"], j["el"], j["wl"], "#986dc0", 10)
    draw_limb(c, j["sr"], j["er"], j["wr"], "#b68bd2", 10)
    c.poly(torso_shape(j), "#7b4a9b")
    c.poly([(j["sl"][0]+3, j["sl"][1]+4), (j["sr"][0]-3, j["sr"][1]+4),
            (hips[0]+10, hips[1]+13), (hips[0]-10, hips[1]+13)], "#a777c3", "#4a345d", 2)
    c.poly([(shoulders[0], shoulders[1]+8), (shoulders[0]+5, shoulders[1]+17),
            (shoulders[0], shoulders[1]+27), (shoulders[0]-5, shoulders[1]+17)], GOLD, INK, 1)
    # Long silver braid is visible on both sides of the hat.
    braid = [(h[0]-17, h[1]+7), (h[0]-22, h[1]+23), (h[0]-18, h[1]+37),
             (h[0]-26, h[1]+50), (h[0]-20, h[1]+63)]
    c.line(braid, "#d9dce8", 8, "#716b85")
    for x, y in braid[1:-1]:
        c.ellipse((x-4, y-4, x+4, y+4), "#eef0f6", "#8a819d", 1)
    c.ellipse((h[0]-16, h[1]-18, h[0]+16, h[1]+19), SKIN, INK, 2)
    if not rear:
        c.ellipse((h[0]-8, h[1]-1, h[0]-4, h[1]+3), INK, INK, .5)
        c.ellipse((h[0]+4, h[1]-1, h[0]+8, h[1]+3), INK, INK, .5)
        c.line([(h[0]-4, h[1]+9), (h[0]+4, h[1]+9)], "#a85458", 1.4, None)
    else:
        c.poly([(h[0]-13, h[1]-12), (h[0]+13, h[1]-12),
                (h[0]+10, h[1]+14), (h[0]-10, h[1]+14)], "#c8bfd6", "#6d5e7d", 1)
    # Wide, unmistakable pointed hat, with a gold band and star.
    c.poly([(h[0]-35, h[1]-15), (h[0]-28, h[1]-36),
            (h[0]+3, h[1]-59), (h[0]+20, h[1]-33),
            (h[0]+43, h[1]-22), (h[0]+30, h[1]-12)], "#483365", "#302543", 2.5)
    c.poly([(h[0]-32, h[1]-17), (h[0]+38, h[1]-17),
            (h[0]+46, h[1]-8), (h[0]-41, h[1]-8)], "#67448b", "#302543", 2)
    c.line([(h[0]-27, h[1]-16), (h[0]+36, h[1]-16)], GOLD, 3, None)
    c.poly([(h[0]+1, h[1]-34), (h[0]+4, h[1]-27), (h[0]+11, h[1]-26),
            (h[0]+6, h[1]-21), (h[0]+8, h[1]-14),
            (h[0]+1, h[1]-18), (h[0]-5, h[1]-14),
            (h[0]-3, h[1]-22), (h[0]-9, h[1]-26), (h[0]-2, h[1]-27)], GOLD, PALE_GOLD, 1)
    # Staff follows the caster's raised hand and carries a bright crystal.
    hand = j["wr"]
    if pose == "slide":
        top = (hand[0]+8, hand[1]-74)
    elif pose == "attack":
        top = (hand[0]+19, hand[1]-49)
    elif pose == "power":
        top = (hand[0]+20, hand[1]-96)
    else:
        top = (hand[0]+11, hand[1]-69)
    c.line([hand, top], "#875f3f", 6, "#473650")
    c.line([(hand[0]+2, hand[1]-4), (top[0]+2, top[1]+8)], "#d6a357", 1.8, None)
    c.poly([(top[0], top[1]-15), (top[0]+11, top[1]),
            (top[0], top[1]+15), (top[0]-11, top[1])], "#61d6ee", "#fff1c9", 2)
    c.ellipse((top[0]-4, top[1]-4, top[0]+4, top[1]+4), "#d9ffff", "#74c9dc", 1)
    if pose in ("attack", "power"):
        if pose == "power":
            c.ellipse((top[0]-29, top[1]-28, top[0]+29, top[1]+28),
                      None, "#8deaff", 2)
            c.ellipse((top[0]-38, top[1]-37, top[0]+38, top[1]+37),
                      None, PALE_GOLD, 1)
        for dx, dy in ((-13, -7), (14, -9), (-9, 13), (13, 12)):
            c.line([(top[0]+dx, top[1]+dy),
                    (top[0]+dx*1.55, top[1]+dy*1.55)],
                   "#8deaff" if pose == "power" else PALE_GOLD, 2, None)
    elif pose == "landing":
        for x in (j["al"][0], j["ar"][0]):
            c.line([(x-16, 278), (x-6, 275)], PALE_GOLD, 2, None)
            c.line([(x+7, 275), (x+17, 278)], PALE_GOLD, 2, None)


def render(kind: str, pose: str, rear: bool) -> Image.Image:
    c = Canvas()
    j = skeleton(pose)
    if kind == "knight":
        draw_knight(c, j, pose, rear)
    elif kind == "gargoyle":
        draw_gargoyle(c, j, pose, rear)
    else:
        draw_witch(c, j, pose, rear)
    return c.finish()


def update_registry(sprites: dict[str, dict[str, object]]) -> None:
    registry = json.loads(REGISTRY.read_text())
    entry = next((item for item in registry["assets"] if item["id"] == ASSET_ID), None)
    if entry is None:
        raise RuntimeError(f"Asset registry is missing {ASSET_ID}")
    entry["sources"] = list(dict.fromkeys(entry["sources"] + [
        "tools/generate_concept_action_sprites.py",
        "assets/characters/concept-sprites/ACTION_PROVENANCE.json",
    ]))
    entry["modifications"] = [
        "Cropped the six front/rear character views from the owner-provided approved sheet and removed only edge-connected pale background.",
        "Added locally drawn front/rear running, jumping, sliding, basic attack, landing, and special-power pose frames for Knight, Gargoyle, and Witch; generated at no cost from authored drawing primitives, guided by the supplied concept sheet.",
        "Use is limited to noncommercial distribution as part of MysticRun; commercial use is not authorized.",
        f"Required credit: {CREDIT}",
    ]
    action_paths = {item["path"] for item in sprites.values()}
    original_files = [item for item in entry["files"] if item["path"] not in action_paths]
    entry["files"] = original_files + [
        {
            "path": str(item["path"]),
            "sha256": str(item["sha256"]),
            "bytes": int(item["bytes"]),
        }
        for item in sprites.values()
    ]
    license_bytes = LICENSE.read_bytes()
    entry["license_evidence"] = {
        "path": LICENSE.relative_to(ROOT).as_posix(),
        "sha256": hashlib.sha256(license_bytes).hexdigest(),
        "bytes": len(license_bytes),
    }
    REGISTRY.write_text(json.dumps(registry, indent=2) + "\n")


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    sprites: dict[str, dict[str, object]] = {}
    for kind in ("knight", "gargoyle", "witch"):
        for pose in POSES:
            for view, rear in (("front", False), ("rear", True)):
                name = f"{kind}_{pose}_{view}"
                path = DEST / f"{name}.png"
                image = render(kind, pose, rear)
                image.save(path, optimize=True)
                sprites[name] = {
                    "path": path.relative_to(ROOT).as_posix(),
                    "dimensions": list(image.size),
                    "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "bytes": path.stat().st_size,
                    "pose": pose,
                    "view": view,
                }
                print(f"{name}: {image.width}x{image.height} {path.stat().st_size} bytes")
    manifest = {
        "source": "references/01-character-concept.png",
        "source_sha256": hashlib.sha256(
            (ROOT / "references/01-character-concept.png").read_bytes()
        ).hexdigest(),
        "method": "locally authored Pillow vector-like drawings guided by the supplied character sheet",
        "generator": "tools/generate_concept_action_sprites.py",
        "external_services": [],
        "cost_usd": 0,
        "commercial_use": False,
        "credit": CREDIT,
        "poses": list(POSES),
        "sprites": sprites,
    }
    (DEST / "ACTION_PROVENANCE.json").write_text(json.dumps(manifest, indent=2) + "\n")
    update_registry(sprites)
    print(f"ACTION_SPRITES {len(sprites)} frames; $0; noncommercial")


if __name__ == "__main__":
    main()
