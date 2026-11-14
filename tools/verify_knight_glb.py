#!/usr/bin/env python3
"""Fail-closed validation of an authored Knight GLB and its provenance."""
import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

MORPHS = ["Blink", "PlumeSway", "Smile", "Focus", "Surprised", "Hurt"]
COMPONENTS = {5121: ("B", 1), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(glb: Path):
    raw = glb.read_bytes()
    assert len(raw) >= 20 and raw[:4] == b"glTF", "Not a GLB"
    magic, version, total = struct.unpack_from("<4sII", raw)
    assert version == 2 and total == len(raw), "Invalid GLB header"
    length, kind = struct.unpack_from("<II", raw, 12)
    assert kind == 0x4E4F534A and 20 + length <= len(raw), "Missing JSON chunk"
    doc = json.loads(raw[20:20 + length])
    offset = 20 + length
    assert offset + 8 <= len(raw), "Missing binary chunk"
    size, kind = struct.unpack_from("<II", raw, offset)
    assert kind == 0x004E4942 and offset + 8 + size == len(raw), "Invalid binary chunk"
    binary = raw[offset + 8:]
    assert len(doc.get("buffers", [])) == 1 and "uri" not in doc["buffers"][0], "External buffer"
    assert doc["buffers"][0]["byteLength"] <= len(binary), "Truncated buffer"
    return raw, doc, binary


def stream(doc, binary, index):
    """Read real accessor bytes, including Blender's sparse morph streams."""
    a = doc["accessors"][index]
    code, size = COMPONENTS[a["componentType"]]
    width = WIDTHS[a["type"]]

    def dense(view_index, offset, count, fmt, component_size, components):
        view = doc["bufferViews"][view_index]
        assert view.get("buffer", 0) == 0
        stride = view.get("byteStride", component_size * components)
        start = view.get("byteOffset", 0) + offset
        view_end = view.get("byteOffset", 0) + view["byteLength"]
        assert stride >= component_size * components and view_end <= len(binary), "Invalid buffer view"
        assert offset >= 0 and count >= 0
        if count:
            assert start + (count-1) * stride + component_size * components <= view_end, "Truncated accessor"
        return [struct.unpack_from("<" + fmt * components, binary, start + n * stride)
                for n in range(count)]

    result = (dense(a["bufferView"], a.get("byteOffset", 0), a["count"], code, size, width)
              if "bufferView" in a else [(0,) * width for _ in range(a["count"])])
    if "sparse" in a:
        sparse = a["sparse"]
        indices, values = sparse["indices"], sparse["values"]
        assert indices["componentType"] in (5121, 5123, 5125), "Invalid sparse index type"
        index_code, index_size = COMPONENTS[indices["componentType"]]
        locations = [row[0] for row in dense(indices["bufferView"], indices.get("byteOffset", 0),
                     sparse["count"], index_code, index_size, 1)]
        assert locations == sorted(set(locations)), "Sparse indices must be strictly increasing"
        replacements = dense(values["bufferView"], values.get("byteOffset", 0),
                             sparse["count"], code, size, width)
        for location, value in zip(locations, replacements):
            assert 0 <= location < len(result), "Sparse index out of range"
            result[location] = value
    if a.get("normalized"):
        assert a["componentType"] in (5121, 5123), "Unsupported normalization"
        maximum = 255 if size == 1 else 65535
        result = [tuple(v / maximum for v in row) for row in result]
    assert all(math.isfinite(v) for row in result for v in row), "Non-finite vertex stream"
    return result


def rig_signature(doc, binary):
    skin = doc["skins"][0]
    nodes = doc["nodes"]
    joints = skin["joints"]
    names = [nodes[n]["name"] for n in joints]
    assert len(names) == 65 and len(set(names)) == 65, "Expected exactly 65 unique bones"
    parents = {child: n for n, node in enumerate(nodes) for child in node.get("children", [])}
    matrices = stream(doc, binary, skin["inverseBindMatrices"])
    assert len(matrices) == 65
    # Names, hierarchy, local rest transforms and inverse bind matrices must survive.
    return {name: {
        "parent": nodes[parents[n]].get("name") if n in parents else None,
        "translation": nodes[n].get("translation", [0, 0, 0]),
        "rotation": nodes[n].get("rotation", [0, 0, 0, 1]),
        "scale": nodes[n].get("scale", [1, 1, 1]),
        "matrix": nodes[n].get("matrix"),
        "inverse_bind": matrices[i],
    } for i, (n, name) in enumerate(zip(joints, names))}


def check(glb: Path, provenance: Path, baseline: Path = None):
    raw, doc, binary = load_glb(glb)
    manifest = json.loads(provenance.read_text())
    sha = hashlib.sha256(raw).hexdigest()
    assert sha == manifest["asset_sha256"], "Provenance SHA mismatch"
    assert len(raw) == manifest["asset_bytes"], "Provenance size mismatch"
    assert manifest["character"] == "knight"
    assert manifest["bones"] == 65, "Expected exactly 65 bones in provenance"
    assert manifest["morph_targets"] == MORPHS, "Expected exactly six named morphs"
    assert all(manifest["morph_affected_vertices"].get(n, 0) > 0 for n in MORPHS)
    meshes = doc.get("meshes", [])
    assert len(meshes) == 1 and meshes[0].get("primitives"), "Expected one mesh"
    assert len(doc.get("skins", [])) == 1, "Expected one rig skin"
    accessors = doc.get("accessors", [])
    for a in accessors:
        assert a.get("count", 0) >= 0
        for key in ("min", "max"):
            assert all(math.isfinite(v) for v in a.get(key, [])), "Non-finite accessor bound"
    assert meshes[0].get("extras", {}).get("targetNames") == MORPHS, "GLB morph names changed"
    primitives = meshes[0]["primitives"]
    assert len(primitives) == manifest["material_surfaces"] == 1, "Draw-call contract changed"
    triangles, vertices = 0, 0
    affected = {name: 0 for name in MORPHS}
    for p in primitives:
        assert p.get("mode", 4) == 4, "Non-triangle primitive"
        attrs = p["attributes"]
        assert {"POSITION", "NORMAL", "COLOR_0", "TEXCOORD_0", "TEXCOORD_1",
                "JOINTS_0", "WEIGHTS_0"} <= attrs.keys(), "Missing authored/skin attributes"
        arrays = {key: stream(doc, binary, value) for key, value in attrs.items()}
        count = len(arrays["POSITION"])
        assert count > 0 and all(len(rows) == count for rows in arrays.values()), "Attribute count mismatch"
        indices = stream(doc, binary, p["indices"])
        assert len(indices) % 3 == 0 and all(0 <= row[0] < count for row in indices), "Invalid triangle indices"
        triangles += len(indices) // 3
        vertices += count
        for weights, joints in zip(arrays["WEIGHTS_0"], arrays["JOINTS_0"]):
            assert all(0 <= w <= 1 for w in weights) and abs(sum(weights)-1) < .0001, "Invalid skin weights"
            assert all(isinstance(j, int) and 0 <= j < 65 for j in joints), "Invalid joint index"
        assert len(p.get("targets", [])) == 6, "Expected six morph streams"
        for name, target in zip(MORPHS, p["targets"]):
            assert "POSITION" in target, "Missing morph position stream"
            for key, accessor in target.items():
                values = stream(doc, binary, accessor)
                assert len(values) == count, "Morph count mismatch"
                if key == "POSITION":
                    affected[name] += sum(any(abs(v) > .000001 for v in row) for row in values)
    assert 0 < triangles <= 25000, f"Mobile triangle cap exceeded: {triangles}"
    assert triangles == manifest["triangles"], "Actual triangle count differs from provenance"
    assert all(affected.values()), "Morph must affect real exported vertices"
    rig = rig_signature(doc, binary)
    materials = [m.get("name", "") for m in doc.get("materials", [])]
    baseline_rig_preserved = None
    if baseline is not None:
        _, old_doc, old_binary = load_glb(baseline)
        assert rig == rig_signature(old_doc, old_binary), "Baseline rig/rest transforms changed"
        assert materials == [m.get("name", "") for m in old_doc.get("materials", [])], "Material slots changed"
        baseline_rig_preserved = True
    result = {"status": "GLB_STRUCTURAL_PASS", "sha256": sha, "bytes": len(raw),
              "mesh_count": len(meshes), "skin_count": len(doc["skins"]),
              "morph_targets": MORPHS, "morph_exported_affected_vertices": affected,
              "triangles": triangles, "triangle_headroom": 25000-triangles,
              "exported_vertices": vertices, "bones": list(rig), "rig": rig,
              "materials": materials, "baseline_rig_preserved": baseline_rig_preserved,
              "scope": "GLB structure/provenance; not visual, animation, or phone approval"}
    print(json.dumps(result, indent=2))
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--glb", type=Path, default=Path("assets/characters/knight/knight.glb"))
    parser.add_argument("--provenance", type=Path, default=Path("assets/characters/knight/PROVENANCE.json"))
    parser.add_argument("--baseline", type=Path, help="Require identical 65-bone rest rig and material slots")
    args = parser.parse_args()
    check(args.glb, args.provenance, args.baseline)
