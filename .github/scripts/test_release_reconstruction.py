"""ZIP reconstruction contracts; Android signatures are checked by apksigner."""
import base64
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

import publish_android_release as release


class ReconstructionTests(unittest.TestCase):
    def setUp(self):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, 'w') as archive:
            archive.writestr('compiled-game', b'unchanged compiled content'*300)
            archive.writestr('resources', b'original resource bytes')
        self.unsigned = buffer.getvalue()
        offset, _end, _size = release.zip_layout(self.unsigned)
        public_metadata = b'public signature fixture'
        signed = bytearray(self.unsigned[:offset]+public_metadata+self.unsigned[offset:])
        struct.pack_into('<I', signed, len(signed)-22+16, offset+len(public_metadata))
        self.signed = bytes(signed)
        builder = {'service':'github-actions', 'repository':release.REPOSITORY, 'run_id':'1', 'commit':'1'*40}
        original = {'apk':'original.apk', 'package_id':release.PACKAGE, 'git_commit':'1'*40,
                    'builder':builder, 'bytes':len(self.unsigned), 'sha256':release.sha256(self.unsigned),
                    'requires_owner_signing':True, 'signature_verified':False}
        self.original_manifest = json.dumps(original).encode()
        manifest = dict(original)
        manifest.update({'apk':'Mystic_Run_0.1.2_GitHub_Build1003.apk', 'sha256':release.sha256(self.signed),
                         'bytes':len(self.signed), 'unsigned_apk_sha256':original['sha256'],
                         'signature_verified':True, 'requires_owner_signing':False,
                         'certificate_sha256':release.CERTIFICATE, 'version_name':'0.1.2', 'version_code':1003})
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name, data in [('original.apk',self.unsigned), ('signed.apk',self.signed),
                               ('original.json',self.original_manifest), ('signed.json',json.dumps(manifest).encode())]:
                (root/name).write_bytes(data)
            self.record = release.make_record(root/'original.apk',root/'signed.apk',root/'original.json',root/'signed.json')

    def test_exact_archive_round_trip(self):
        self.assertEqual(release.apply_record(self.unsigned,self.original_manifest,self.record), self.signed)

    def test_changed_compilation_is_rejected(self):
        modified = bytearray(self.unsigned)
        modified[50] ^= 1
        with self.assertRaises(ValueError):
            release.apply_record(bytes(modified),self.original_manifest,self.record)

    def test_changed_manifest_is_rejected(self):
        with self.assertRaises(ValueError):
            release.apply_record(self.unsigned,self.original_manifest+b' ',self.record)

    def test_changed_public_archive_bytes_are_rejected(self):
        record = copy.deepcopy(self.record)
        data = bytearray(base64.b64decode(record['segments'][0]['data']))
        data[0] ^= 1
        record['segments'][0]['data'] = base64.b64encode(data).decode()
        with self.assertRaises(ValueError):
            release.apply_record(self.unsigned,self.original_manifest,record)

    def test_out_of_bounds_copy_is_rejected(self):
        record = copy.deepcopy(self.record)
        segment = next(s for s in record['segments'] if 'offset' in s)
        segment['offset'] = len(self.unsigned)+1
        with self.assertRaises(ValueError):
            release.apply_record(self.unsigned,self.original_manifest,record)

    def test_different_signing_identity_is_rejected(self):
        record = copy.deepcopy(self.record)
        record['signed_manifest']['certificate_sha256'] = '0'*64
        with self.assertRaises(ValueError):
            release.apply_record(self.unsigned,self.original_manifest,record)

    def permanent_record(self):
        record = copy.deepcopy(self.record)
        record['signed_manifest'].update({
            'certificate_sha256':'6cae555cdc35ea335e5ca6f29252bfad9ebc1cbc9a12c83e18c7eb1038a6a8cf',
            'permanent_signing_identity':True,
            'owner_game_update_compatible':False,
            'updates_legacy_owner_installation':False,
        })
        return record

    def test_permanent_identity_round_trip_preserves_game_bytes(self):
        self.assertEqual(release.apply_record(self.unsigned,self.original_manifest,self.permanent_record()),self.signed)

    def test_permanent_identity_cannot_claim_legacy_upgrade(self):
        for field in ('owner_game_update_compatible','updates_legacy_owner_installation'):
            with self.subTest(field=field):
                record = self.permanent_record()
                record['signed_manifest'][field] = True
                with self.assertRaises(ValueError):
                    release.validate_record(record)

    def test_permanent_identity_requires_explicit_marker(self):
        record = self.permanent_record()
        del record['signed_manifest']['permanent_signing_identity']
        with self.assertRaises(ValueError):
            release.validate_record(record)

    def test_permanent_release_notes_explain_certificate_boundary(self):
        notes = release.signing_note(self.permanent_record()['signed_manifest'])
        self.assertIn('cannot update',notes)
        self.assertIn('6cae555c',notes)
        self.assertIn('Do not uninstall',notes)

    def test_legacy_release_notes_preserve_original_identity(self):
        notes = release.signing_note(self.record['signed_manifest'])
        self.assertIn('preserves the original signing identity',notes)


from test_art_preview_release import ArtPreviewReconstructionTests


if __name__ == '__main__':
    unittest.main()

