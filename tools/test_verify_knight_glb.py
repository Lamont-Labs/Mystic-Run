"""Contract tests against the real Knight GLB, including adversarial exports."""
import contextlib
import copy
import hashlib
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest

from verify_knight_glb import check, load_glb, stream


ROOT = Path(__file__).resolve().parents[1]
GLB = ROOT / "assets/characters/knight/knight.glb"
PROVENANCE = ROOT / "assets/characters/knight/PROVENANCE.json"


class KnightContractTests(unittest.TestCase):
    def setUp(self):
        _, self.doc, self.binary = load_glb(GLB)
        self.manifest = json.loads(PROVENANCE.read_text())
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.glb = Path(self.temp.name) / "candidate.glb"
        self.provenance = Path(self.temp.name) / "provenance.json"

    def write(self):
        encoded = json.dumps(self.doc).encode()
        encoded += b" " * (-len(encoded) % 4)
        binary = self.binary + b"\0" * (-len(self.binary) % 4)
        raw = (struct.pack("<4sII", b"glTF", 2, 28+len(encoded)+len(binary))
               + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
               + struct.pack("<II", len(binary), 0x004E4942) + binary)
        self.glb.write_bytes(raw)
        manifest = copy.deepcopy(self.manifest)
        manifest["asset_sha256"] = hashlib.sha256(raw).hexdigest()
        manifest["asset_bytes"] = len(raw)
        self.provenance.write_text(json.dumps(manifest))

    def verify(self, baseline=None):
        with contextlib.redirect_stdout(io.StringIO()):
            return check(self.glb, self.provenance, baseline)

    def test_real_asset_and_unchanged_rig_pass(self):
        self.write()
        result = self.verify(GLB)
        self.assertEqual(result["triangles"], self.manifest["triangles"])
        self.assertTrue(result["baseline_rig_preserved"])
        self.assertEqual(len(result["bones"]), 65)

    def test_falsified_triangle_manifest_fails(self):
        self.manifest["triangles"] -= 1
        self.write()
        with self.assertRaisesRegex(AssertionError, "Actual triangle"):
            self.verify()

    def test_actual_triangle_cap_is_enforced(self):
        # Keep all other real streams valid; append an oversized index stream.
        values = b"\0\0" * (25001 * 3)
        offset = len(self.binary)
        self.binary += values
        self.doc["buffers"][0]["byteLength"] = len(self.binary)
        self.doc["bufferViews"].append({"buffer": 0, "byteOffset": offset, "byteLength": len(values)})
        self.doc["accessors"].append({"bufferView": len(self.doc["bufferViews"])-1,
                                     "componentType": 5123, "count": 25001*3, "type": "SCALAR"})
        self.doc["meshes"][0]["primitives"][0]["indices"] = len(self.doc["accessors"])-1
        self.manifest["triangles"] = 25001
        self.write()
        with self.assertRaisesRegex(AssertionError, "Mobile triangle cap"):
            self.verify()

    def test_missing_morph_stream_fails(self):
        self.doc["meshes"][0]["primitives"][0]["targets"].pop()
        self.write()
        with self.assertRaisesRegex(AssertionError, "six morph"):
            self.verify()

    def test_morph_rename_fails(self):
        self.doc["meshes"][0]["extras"]["targetNames"][0] = "NotBlink"
        self.write()
        with self.assertRaisesRegex(AssertionError, "morph names"):
            self.verify()

    def test_rest_rig_change_fails(self):
        node = self.doc["nodes"][self.doc["skins"][0]["joints"][0]]
        node["translation"] = [100, 0, 0]
        self.write()
        with self.assertRaisesRegex(AssertionError, "rig/rest"):
            self.verify(GLB)

    def test_duplicate_bone_name_fails(self):
        a, b = self.doc["skins"][0]["joints"][:2]
        self.doc["nodes"][a]["name"] = self.doc["nodes"][b]["name"]
        self.write()
        with self.assertRaisesRegex(AssertionError, "65 unique"):
            self.verify()

    def test_nonfinite_exported_position_fails(self):
        index = self.doc["meshes"][0]["primitives"][0]["attributes"]["POSITION"]
        accessor = self.doc["accessors"][index]
        view = self.doc["bufferViews"][accessor["bufferView"]]
        offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        data = bytearray(self.binary)
        struct.pack_into("<f", data, offset, float("nan"))
        self.binary = bytes(data)
        self.write()
        with self.assertRaisesRegex(AssertionError, "Non-finite"):
            self.verify()

    def test_sparse_morph_decodes_real_position(self):
        data = b"\x01\0\0\0" + struct.pack("<fff", 1, 2, 3)
        doc = {"bufferViews": [{"byteOffset": 0, "byteLength": 1},
                              {"byteOffset": 4, "byteLength": 12}],
               "accessors": [{"componentType": 5126, "type": "VEC3", "count": 3,
                              "sparse": {"count": 1, "indices": {"bufferView": 0, "componentType": 5121},
                                         "values": {"bufferView": 1}}}]}
        self.assertEqual(stream(doc, data, 0), [(0, 0, 0), (1, 2, 3), (0, 0, 0)])


if __name__ == "__main__":
    unittest.main()
