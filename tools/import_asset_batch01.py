#!/usr/bin/env python3
"""Stage verified MysticRun Batch 01 GLBs in Godot runtime asset paths.

Usage: python3 tools/import_asset_batch01.py /path/to/MysticRun_3D_Assets_Batch01_2026-11-05.zip
No scene or character is replaced automatically. This is a reproducible, license-checked import.
"""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

PREFIX = "MysticRun_Assets_Batch01/art/asset_batch_01/"
DEST = Path("assets/replacement_batch01")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    with zipfile.ZipFile(args.archive) as archive:
        index = json.loads(archive.read(PREFIX + "original-assets.json"))
        outfit = json.loads(archive.read(PREFIX + "outfit-assets.json"))
        # The exact original authored models are pinned by their producer's hashes.
        expected = {a["path"]: a["sha256"] for a in index["assets"]}
        for entry in outfit.get("assets", []):
            if isinstance(entry, dict) and "path" in entry and "sha256" in entry:
                expected[entry["path"]] = entry["sha256"]
        members = [n for n in archive.namelist()
                   if n.startswith(PREFIX + "review/assets/") and n.endswith(".glb")]
        if len(members) != 57:
            raise ValueError(f"Expected 57 GLBs, found {len(members)}")
        checked = []
        for member in members:
            data = archive.read(member)
            rel = member[len(PREFIX):]
            if not data.startswith(b"glTF"):
                raise ValueError(f"Not a GLB: {rel}")
            if rel in expected and hashlib.sha256(data).hexdigest() != expected[rel]:
                raise ValueError(f"Hash mismatch: {rel}")
            checked.append((rel, data))
        for rel, data in checked:
            relative = Path(rel).relative_to("review/assets")
            target = args.root / DEST / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        licenses = [n for n in archive.namelist()
                    if n.startswith(PREFIX + "licenses/") and not n.endswith("/")]
        for member in licenses:
            target = args.root / DEST / "licenses" / member.split("/licenses/", 1)[1]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(member))
    print(f"Imported {len(checked)} GLBs with {len(licenses)} license files to {DEST}")
    print("Integration status: STAGED; no gameplay model replacement claimed.")

if __name__ == "__main__":
    main()
