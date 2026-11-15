import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import android_icon_resources as icons


class IconResourceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.apk, self.template = self.root / "game.apk", self.root / "template.apk"
        self.table = "\n".join(
            f"resource 0x7f0a000{i} mipmap/{name}"
            for i, name in enumerate(icons.ICON_NAMES)
        ) + f"\n(anydpi-v26) (file) {icons.THEMED_ICON} type=XML"
        with zipfile.ZipFile(self.apk, "w") as archive:
            archive.writestr("assets/game.pck", b"unchanged-game")
            archive.writestr("resources.arsc", b"unchanged-table")
        with zipfile.ZipFile(self.template, "w") as archive:
            archive.writestr(icons.THEMED_ICON, b"compiled-template-xml")
        digest = hashlib.sha256(self.template.read_bytes()).hexdigest()
        self.enterContext(patch.dict(icons.EXPECTED, {"android_debug.apk": digest}))
        self.inspect = self.enterContext(patch.object(icons, "inspect_table", return_value=self.table))

    def test_restores_only_missing_xml_and_is_idempotent(self):
        result = icons.repair_themed_icon(self.apk, self.template, "aapt")
        self.assertEqual(result["restored"], [icons.THEMED_ICON])
        with zipfile.ZipFile(self.apk) as archive:
            self.assertEqual(archive.read("assets/game.pck"), b"unchanged-game")
            self.assertEqual(archive.read("resources.arsc"), b"unchanged-table")
            self.assertEqual(archive.read(icons.THEMED_ICON), b"compiled-template-xml")
        before = self.apk.read_bytes()
        self.assertEqual(icons.repair_themed_icon(self.apk, self.template, "aapt")["restored"], [])
        self.assertEqual(before, self.apk.read_bytes())

    def test_rejects_unknown_missing_resource(self):
        self.inspect.return_value += "\n(file) res/drawable/missing.xml"
        with self.assertRaisesRegex(ValueError, "Unexpected missing"):
            icons.repair_themed_icon(self.apk, self.template, "aapt")

    def test_rejects_unverified_template(self):
        self.template.write_bytes(b"wrong-template")
        with self.assertRaisesRegex(ValueError, "checksum-pinned"):
            icons.repair_themed_icon(self.apk, self.template, "aapt")

    def test_rejects_mismatched_compiled_resource_ids(self):
        self.inspect.side_effect = [self.table, self.table.replace("0x7f0a0000", "0x7f0a0099")]
        with self.assertRaisesRegex(ValueError, "resource IDs"):
            icons.repair_themed_icon(self.apk, self.template, "aapt")


if __name__ == "__main__":
    unittest.main()
