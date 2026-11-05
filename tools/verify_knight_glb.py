#!/usr/bin/env python3
"""Fail-closed validation of an authored Knight GLB and its provenance."""
import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

def check(glb: Path, provenance: Path):
    raw = glb.read_bytes()
    assert len(raw) >= 20 and raw[:4] == b"glTF", "Not a GLB"
    magic, version, total = struct.unpack_from("<4sII", raw)
    assert version == 2 and total == len(raw), "Invalid GLB header"
    length, kind = struct.unpack_from("<II", raw, 12)
    assert kind == 0x4E4F534A and 20 + length <= len(raw), "Missing JSON chunk"
    doc = json.loads(raw[20:20 + length])
    manifest = json.loads(provenance.read_text())
    sha = hashlib.sha256(raw).hexdigest()
    assert sha == manifest["asset_sha256"], "Provenance SHA mismatch"
    assert len(raw) == manifest["asset_bytes"], "Provenance size mismatch"
    assert manifest["character"] == "knight"
    assert manifest["triangles"] > 0 and manifest["bones"] >= 60
    assert set(["Blink", "PlumeSway", "Smile", "Focus", "Surprised", "Hurt"]) <= set(manifest["morph_targets"])
    assert all(manifest["morph_affected_vertices"].get(n, 0) > 0 for n in ["Blink", "PlumeSway"])
    meshes = doc.get("meshes", [])
    assert meshes and any(m.get("primitives") for m in meshes), "No mesh primitives"
    assert doc.get("skins"), "No rig skin"
    accessors = doc.get("accessors", [])
    for a in accessors:
        assert a.get("count", 0) >= 0
        for key in ("min", "max"):
            assert all(math.isfinite(v) for v in a.get(key, [])), "Non-finite accessor bound"
    attrs = [p.get("attributes", {}) for m in meshes for p in m.get("primitives", [])]
    assert any("JOINTS_0" in a and "WEIGHTS_0" in a for a in attrs), "Missing skin attributes"
    targets = [p.get("targets", []) for m in meshes for p in m.get("primitives", [])]
    assert any(len(t) >= 6 for t in targets), "Missing six morph target streams"
    result = {"status": "GLB_STRUCTURAL_PASS", "sha256": sha, "bytes": len(raw),
              "mesh_count": len(meshes), "skin_count": len(doc["skins"]),
              "morph_targets": manifest["morph_targets"], "triangles": manifest["triangles"],
              "scope": "GLB structure/provenance; not visual, animation, or phone approval"}
    print(json.dumps(result, indent=2))
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--glb", type=Path, default=Path("assets/characters/knight/knight.glb"))
    parser.add_argument("--provenance", type=Path, default=Path("assets/characters/knight/PROVENANCE.json"))
    args = parser.parse_args()
    check(args.glb, args.provenance)
