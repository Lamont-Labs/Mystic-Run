"""An isolated preview must never persist its identity in the owner project."""
import configparser
from pathlib import Path
import tempfile
import unittest

from build_android import export_configuration


class ExportConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.directory=tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root=Path(self.directory.name)
        source=Path(__file__).resolve().parents[1]
        self.originals={}
        for name in ('export_presets.cfg','project.godot'):
            self.originals[name]=(source/name).read_bytes()
            (self.root/name).write_bytes(self.originals[name])

    def assert_restored(self):
        for name, data in self.originals.items():
            self.assertEqual((self.root/name).read_bytes(),data,name)

    def test_preview_export_preserves_play_preset_and_restores_owner_source(self):
        original_play=self.originals['export_presets.cfg'].decode().partition('[preset.1]')[2]
        with export_configuration(self.root,1017,'0.6.2',
                                  'com.lamontlabs.knightgargoylewitch.artpreview',
                                  'Mystic Run Art Preview',True) as receipt:
            text=(self.root/'export_presets.cfg').read_text()
            config=configparser.ConfigParser(interpolation=None)
            config.read_string(text)
            apk=config['preset.0.options']
            self.assertEqual(apk['version/code'],'1017')
            self.assertEqual(apk['version/name'],'"0.6.2"')
            self.assertEqual(apk['package/unique_name'],'"com.lamontlabs.knightgargoylewitch.artpreview"')
            self.assertEqual(apk['package/name'],'"Mystic Run Art Preview"')
            self.assertEqual(text.partition('[preset.1]')[2],original_play)
            self.assertEqual(len(receipt['export_presets_sha256']),64)
            self.assertIn('config/version="0.6.2"',(self.root/'project.godot').read_text())
        self.assert_restored()

    def test_export_failure_restores_source_before_a_later_owner_export(self):
        with self.assertRaisesRegex(RuntimeError,'simulated export failure'):
            with export_configuration(self.root,1017,'0.6.2',
                                      'com.lamontlabs.knightgargoylewitch.artpreview',
                                      'Mystic Run Art Preview',True):
                raise RuntimeError('simulated export failure')
        self.assert_restored()
        with export_configuration(self.root,1018,'0.6.2',
                                  'com.lamontlabs.knightgargoylewitch.dev',
                                  'Mystic Run',False):
            config=configparser.ConfigParser(interpolation=None)
            config.read(self.root/'export_presets.cfg')
            self.assertEqual(config['preset.0.options']['package/unique_name'],
                             '"com.lamontlabs.knightgargoylewitch.dev"')
            self.assertEqual(config['preset.0.options']['package/signed'],'false')
        self.assert_restored()

    def test_malformed_preset_fails_before_export_and_is_restored_exactly(self):
        preset=self.root/'export_presets.cfg'
        malformed=preset.read_bytes().replace(b'version/code=1014',b'broken/version=1014',1)
        preset.write_bytes(malformed)
        self.originals['export_presets.cfg']=malformed
        with self.assertRaisesRegex(RuntimeError,'Expected exactly one APK preset'):
            with export_configuration(self.root,1017,'0.6.2',
                                      'com.lamontlabs.knightgargoylewitch.artpreview',
                                      'Mystic Run Art Preview',True):
                self.fail('Malformed preset was accepted')
        self.assert_restored()


if __name__=='__main__':
    unittest.main()
