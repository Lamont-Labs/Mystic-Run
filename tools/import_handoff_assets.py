#!/usr/bin/env python3
"""Import the preserved MysticRun asset handoff into a local Godot checkout.

Accepts either MysticRun_Next_Chat_Handoff_2026-11-05.zip or the nested
MysticRun_3D_Assets_Batch01_2026-11-05.zip. Fails closed on missing or
modified files. Does not replace any playable character.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile

INNER = "asset_batch/MysticRun_3D_Assets_Batch01_2026-11-05.zip"
PREFIX = "MysticRun_Assets_Batch01/art/asset_batch_01/"
OUTPUT = Path("assets/replacement_batch01")

def extract(archive_path: Path, project: Path) -> int:
    with zipfile.ZipFile(archive_path) as outer:
        if INNER in outer.namelist():
            inner_bytes = outer.read(INNER)
            source = zipfile.ZipFile(io.BytesIO(inner_bytes))
        else:
            source = outer
        with source:
            original = json.loads(source.read(PREFIX + "original-assets.json"))
            outfits = json.loads(source.read(PREFIX + "outfit-assets.json"))
            hashes = {item["path"]: item["sha256"] for item in original["assets"]}
            # Outfit manifests use assets/outfits/... while ZIP review files
            # use review/assets/outfits/...
            hashes.update({"review/" + item["path"]: item["sha256"]
                           for item in outfits["assets"]})
            kaykit = json.loads(source.read(PREFIX + "kaykit-dungeon.lock.json"))
            hashes.update({"review/assets/kaykit/" + Path(item["path"]).name: item["sha256"]
                           for item in kaykit["files"] if item["path"].endswith(".glb")})
            members = sorted(n for n in source.namelist()
                             if n.startswith(PREFIX + "review/assets/") and n.endswith(".glb"))
            if len(members) != 57:
                raise ValueError("Expected exactly 57 GLB files; found %d" % len(members))
            pending = []
            for name in members:
                rel = name[len(PREFIX):]
                payload = source.read(name)
                if payload[:4] != b"glTF":
                    raise ValueError("Invalid GLB magic: " + rel)
                if rel not in hashes:
                    raise ValueError("Unpinned asset: " + rel)
                if hashlib.sha256(payload).hexdigest() != hashes[rel]:
                    raise ValueError("Asset hash mismatch: " + rel)
                target_rel = Path(rel).relative_to("review/assets")
                pending.append((OUTPUT / target_rel, payload))
            for name in source.namelist():
                if name.startswith(PREFIX + "licenses/") and not name.endswith("/"):
                    rel = name[len(PREFIX + "licenses/"):]
                    pending.append((OUTPUT / "licenses" / rel, source.read(name)))
            for rel, payload in pending:
                destination = project / rel
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(payload)
            print("Imported %d verified GLB files; runtime status: STAGED" % len(members))
            return len(members)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("handoff", type=Path)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    extract(args.handoff, args.project)
