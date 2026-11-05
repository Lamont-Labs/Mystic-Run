"""Verify isolated preview reconstruction without relaxing owner release checks."""
import base64
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

import publish_art_preview as preview


class ArtPreviewReconstructionTests(unittest.TestCase):
    def setUp(self):
        def archive(files):
            result=io.BytesIO()
            with zipfile.ZipFile(result,'w',compression=zipfile.ZIP_STORED) as z:
                for name,data in files.items(): z.writestr(name,data)
            return result.getvalue()
        payload=bytes(range(256))*200
        self.unsigned=archive({'native.so':payload,'scene.scn':payload+b'old'+payload,
                               'META-INF/old.version':b'old metadata'})
        self.signed=archive({'native.so':payload,'scene.scn':payload+b'new identifier'+payload,
                             'META-INF/ANDROIDD.SF':b'public signature metadata'})
        builder={'service':'github-actions','repository':preview.REPOSITORY,
                 'run_id':'1','commit':'1'*40}
        original={'apk':'original.apk','package_id':preview.OWNER_PACKAGE,
                  'git_commit':'1'*40,'builder':builder,'sha256':preview.sha256(self.unsigned),
                  'requires_owner_signing':True,'signature_verified':False,
                  'source_sha256':{'game/main.gd':'2'*64}}
        target={'apk':'Mystic_Run_0.6.2_Art_Preview_Build1017.apk',
                'package_id':preview.PACKAGE,'certificate_sha256':preview.CERTIFICATE,
                'git_commit':'1'*40,'builder':{'service':'local'},
                'build_variant':'isolated-art-preview','owner_game_update_compatible':False,
                'sha256':preview.sha256(self.signed),'bytes':len(self.signed),
                'requires_owner_signing':False,'signature_verified':True,
                'source_sha256':{'game/main.gd':'2'*64},'version_name':'0.6.2','version_code':1017}
        self.original_manifest=json.dumps(original).encode()
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary)
            for name,data in [('base.apk',self.unsigned),('target.apk',self.signed),
                              ('base.json',self.original_manifest),('target.json',json.dumps(target).encode())]:
                (root/name).write_bytes(data)
            self.record=preview.make_record(root/'base.apk',root/'target.apk',root/'base.json',root/'target.json')

    def test_exact_signed_preview_round_trip_with_changed_import_bytes(self):
        self.assertEqual(preview.apply_record(self.unsigned,self.original_manifest,self.record),self.signed)
        self.assertTrue(any(set(p)=={'offset','length'} for p in self.record['segments']))
        self.assertLess(sum(len(base64.b64decode(p['data'])) for p in self.record['segments'] if 'data' in p),4096)

    def test_preview_rejects_owner_package_or_changed_key(self):
        for key,value in [('package_id',preview.OWNER_PACKAGE),('certificate_sha256','0'*64),
                          ('owner_game_update_compatible',True)]:
            record=copy.deepcopy(self.record);record['signed_manifest'][key]=value
            with self.assertRaises(ValueError):
                preview.apply_record(self.unsigned,self.original_manifest,record)

    def test_changed_runtime_source_is_rejected(self):
        record=copy.deepcopy(self.record)
        record['signed_manifest']['source_sha256']['game/main.gd']='3'*64
        with self.assertRaisesRegex(ValueError,'runtime source'):
            preview.apply_record(self.unsigned,self.original_manifest,record)

    def test_wrong_base_or_compilation_commit_is_rejected(self):
        with self.assertRaises(ValueError):
            preview.apply_record(self.unsigned+b'changed',self.original_manifest,self.record)
        record=copy.deepcopy(self.record)
        record['compilation']['builder']['commit']='4'*40
        with self.assertRaises(ValueError):
            preview.apply_record(self.unsigned,self.original_manifest,record)

    def test_changed_signature_metadata_is_rejected(self):
        record=copy.deepcopy(self.record)
        part=next(p for p in record['segments'] if 'data' in p)
        value=bytearray(base64.b64decode(part['data']));value[0]^=1
        part['data']=base64.b64encode(value).decode()
        with self.assertRaises(ValueError):
            preview.apply_record(self.unsigned,self.original_manifest,record)

    def test_out_of_bounds_copy_is_rejected(self):
        record=copy.deepcopy(self.record)
        part=next(p for p in record['segments'] if 'offset' in p)
        part['offset']=len(self.unsigned)+1
        with self.assertRaises(ValueError):
            preview.apply_record(self.unsigned,self.original_manifest,record)
