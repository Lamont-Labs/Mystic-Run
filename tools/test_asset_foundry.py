"""Failure-oriented checks for inventory admission and safe glTF dependencies."""
import copy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from asset_foundry import ROOT, REGISTRY, local_path, verify, file_record


class AssetAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        registry = json.loads((ROOT / REGISTRY).read_text())
        files = {REGISTRY}
        for asset in registry["assets"]:
            files.add(asset["license_evidence"]["path"])
            files.update(f["path"] for f in asset["files"])
        for name in files:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        self.registry = registry

    def tearDown(self):
        self.temp.cleanup()

    def save(self):
        (self.root / REGISTRY).write_text(json.dumps(self.registry))

    def test_current_inventory(self):
        result = verify(self.root)
        self.assertEqual(result["status"], "PASS")
        self.assertGreater(result["runtime_files"], 20)

    def test_unknown_nc_and_nd_licenses_fail(self):
        for license_id in ["UNKNOWN", "CC-BY-NC-4.0", "CC-BY-ND-4.0", "QAL-unreviewed"]:
            with self.subTest(license=license_id):
                self.registry["assets"][0]["license"] = license_id
                self.save()
                with self.assertRaisesRegex(ValueError, "Unapproved license"):
                    verify(self.root)

    def test_changed_buffer_fails(self):
        path = self.root / "assets/environment/kaykit/market.bin"
        path.write_bytes(path.read_bytes() + b"changed")
        with self.assertRaisesRegex(ValueError, "Asset bytes changed"):
            verify(self.root)

    def test_unregistered_asset_fails(self):
        (self.root / "assets/environment/kaykit/unreviewed.glb").write_bytes(b"unreviewed")
        with self.assertRaisesRegex(ValueError, "Unregistered runtime asset"):
            verify(self.root)

    def test_missing_license_fails(self):
        (self.root / self.registry["assets"][-1]["license_evidence"]["path"]).unlink()
        with self.assertRaisesRegex(ValueError, "Missing file"):
            verify(self.root)

    def test_claiming_external_art_as_original_fails(self):
        self.registry["assets"][0]["license"] = "LicenseRef-LamontLabs-Original"
        self.save()
        with self.assertRaisesRegex(ValueError, "external publisher"):
            verify(self.root)

    def test_denied_commercial_rights_fail(self):
        self.registry["assets"][0]["commercial_use"] = False
        self.save()
        with self.assertRaisesRegex(ValueError, "commercial_use"):
            verify(self.root)

    def test_cyclic_provenance_fails(self):
        self.registry["assets"][0]["derived_from"] = ["mysticrun-authored-knight"]
        self.save()
        with self.assertRaisesRegex(ValueError, "Cyclic provenance"):
            verify(self.root)

    def test_unsafe_paths_fail(self):
        for path in ["../escape.bin", "/tmp/escape.bin", "https://host/model.bin", "a/../x", "a\\x", "a/%2e%2e/x", "a/./x"]:
            with self.subTest(path=path), self.assertRaises(ValueError):
                local_path(self.root, path)
        (self.root / "outside").symlink_to(self.root.parent, target_is_directory=True)
        with self.assertRaises(ValueError):
            local_path(self.root, "outside/escape.bin")

    def test_gltf_cannot_fetch_remote_buffer_even_with_updated_hash(self):
        name = "assets/environment/kaykit/home.gltf"
        path = self.root / name
        document = json.loads(path.read_text())
        document["buffers"][0]["uri"] = "https://unreviewed.invalid/body.bin"
        path.write_text(json.dumps(document))
        entry = next(e for e in self.registry["assets"] if e["id"] == "kaykit-medieval-districts")
        entry["files"] = [file_record(path, self.root) if f["path"] == name else f for f in entry["files"]]
        self.save()
        with self.assertRaisesRegex(ValueError, "Invalid local asset path"):
            verify(self.root)


if __name__ == "__main__":
    unittest.main()
