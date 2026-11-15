#!/usr/bin/env python3
"""Package generated living-world artwork; keep raw sources in generated-artifacts."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/environment/living-world"
SOURCE = ROOT / "generated-artifacts/gameplay-overhaul/source"


def record(path):
    return {"path": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    provenance = {"generator": "Replit image generation", "commercial_use_claimed": False,
                  "raw_source_archive": "generated-artifacts/gameplay-overhaul/source",
                  "outputs": []}
    for kind in ("castle", "wilds", "ember"):
        for category in ("vista", "stone"):
            source = SOURCE / f"{kind}_{category}.png"
            target = OUT / f"{kind}_{category}.jpg"
            with Image.open(source) as opened:
                image = ImageOps.exif_transpose(opened).convert("RGB")
                image.thumbnail((1024, 1024) if category == "vista" else (512, 512), Image.Resampling.LANCZOS)
                image.save(target, quality=91, optimize=True)
            provenance["outputs"].append({"source_sha256": record(source)["sha256"], **record(target)})
        source = SOURCE / f"{kind}_landmark.png"
        target = OUT / f"{kind}_landmark.png"
        with Image.open(source) as opened:
            image = opened.convert("RGBA")
            bounds = image.getchannel("A").getbbox()
            if not bounds:
                raise ValueError("Empty generated landmark")
            image = image.crop(bounds)
            image.thumbnail((768, 768), Image.Resampling.LANCZOS)
            image.save(target, optimize=True)
        provenance["outputs"].append({"source_sha256": record(source)["sha256"], **record(target)})
    manifest = OUT / "PROVENANCE.json"
    manifest.write_text(json.dumps(provenance, indent=2) + "\n")
    registry_path = ROOT / "assets/asset_registry.json"
    registry = json.loads(registry_path.read_text())
    registry["coverage_roots"] = list(dict.fromkeys(registry["coverage_roots"] + ["assets/environment/living-world"]))
    registry["assets"] = [a for a in registry["assets"] if a["id"] != "mysticrun-living-world"]
    registry["assets"].append({
        "id": "mysticrun-living-world", "cost_usd": 0, "commercial_use": False,
        "modification": True, "game_distribution": True, "attribution_required": False,
        "publisher": "Replit image-generation tool",
        "license": "LicenseRef-MysticRun-Replit-Generated-NonCommercial",
        "edition": "Original generated environments and stone materials for MysticRun",
        "sources": ["tools/build_living_world_art.py", "assets/environment/living-world/PROVENANCE.json"],
        "license_evidence": record(ROOT / "assets/licenses/mysticrun-replit-generated-art-noncommercial.txt"),
        "modifications": ["Generated three original environment paintings, three transparent landmark paintings, and three detailed running-surface materials.",
                          "Optimized mobile runtime JPEGs; raw PNGs retained in the workspace generated-artifacts archive."],
        "derived_from": [], "files": [record(p) for p in sorted(OUT.glob("*")) if p.suffix in (".jpg", ".png", ".json")],
    })
    registry_path.write_text(json.dumps(registry, indent=2) + "\n")
    print("Packaged nine living-world textures and registered provenance")


if __name__ == "__main__":
    main()
