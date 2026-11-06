#!/usr/bin/env python3
"""Fail-closed, read-only verifier for the 52-model MysticRun staging ZIP."""
import argparse
import hashlib
import json
import struct
from collections import Counter
from pathlib import PurePosixPath
from zipfile import ZipFile

REQUIRED = {
    "provenance/original-assets.json",
    "provenance/outfit-assets.json",
    "provenance/kaykit-dungeon.lock.json",
    "provenance/quaternius-outfits.lock.json",
    "assets/replacement_batch01/licenses/Lamont_Labs_Original.txt",
    "assets/replacement_batch01/licenses/kaykit-dungeon/LICENSE.txt",
    "assets/replacement_batch01/licenses/quaternius-outfits/License_Standard.txt",
}

def verify(path):
    with ZipFile(path) as z:
        if z.testzip() is not None:
            raise ValueError("ZIP CRC failure")
        names = z.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate ZIP entry")
        present = set(names)
        if not REQUIRED <= present:
            raise ValueError("Missing provenance/license evidence: " + repr(sorted(REQUIRED - present)))
        receipt = json.loads(z.read("STAGING_RECEIPT.json"))
        if receipt.get("schema") != 1 or receipt.get("staged_models") != 52:
            raise ValueError("Unexpected receipt schema or count")
        rows = receipt["files"]
        if len(rows) != 52:
            raise ValueError("Receipt must enumerate exactly 52 models")
        declared = set()
        counts = Counter()
        for row in rows:
            name = row["path"]
            pp = PurePosixPath(name)
            if pp.is_absolute() or ".." in pp.parts or not name.endswith(".glb"):
                raise ValueError("Unsafe model path: " + name)
            if name in declared or name not in present:
                raise ValueError("Duplicate or missing model: " + name)
            declared.add(name)
            if len(pp.parts) != 4 or pp.parts[:2] != ("assets", "replacement_batch01"):
                raise ValueError("Unexpected model location: " + name)
            category = pp.parts[2]
            if category not in ("outfits", "kaykit"):
                raise ValueError("Unexpected category: " + category)
            counts[category] += 1
            data = z.read(name)
            if len(data) != row["bytes"] or len(data) < 20:
                raise ValueError("Size mismatch: " + name)
            if data[:4] != b"glTF" or struct.unpack_from("<I", data, 4)[0] != 2 or struct.unpack_from("<I", data, 8)[0] != len(data):
                raise ValueError("Invalid GLB v2 header: " + name)
            if hashlib.sha256(data).hexdigest() != row["sha256"]:
                raise ValueError("SHA-256 mismatch: " + name)
        actual = {n for n in names if n.endswith(".glb")}
        if actual != declared or counts != Counter({"outfits": 24, "kaykit": 28}):
            raise ValueError("Model inventory mismatch")
        if receipt.get("staged_category_counts") != dict(counts):
            raise ValueError("Receipt category count mismatch")
        print(json.dumps({"result": "PASS", "models": len(declared), "categories": dict(counts), "license_evidence": "present", "archive_modified": False}, sort_keys=True))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive")
    verify(parser.parse_args().archive)
