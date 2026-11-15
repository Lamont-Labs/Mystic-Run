"""Replacement signing gates, with no real key, phone, or release access."""
import copy
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import sign_android as signing
from android_verification import PERMANENT_CERTIFICATE, SIGNING_ALIAS, verify_resources, verify_signature


SIGNATURE = (
    'Verified using v2 scheme (APK Signature Scheme v2): true\n'
    'Verified using v3 scheme (APK Signature Scheme v3): true\n'
    'Number of signers: 1\n'
    f'Signer #1 certificate SHA-256 digest: {PERMANENT_CERTIFICATE}\n'
)
BADGING = (
    f"package: name='{signing.PACKAGE}' versionCode='2042' versionName='0.6.2'\n"
    "sdkVersion:'24'\ntargetSdkVersion:'36'\n"
    "uses-permission: name='android.permission.VIBRATE'\n"
    "application-label:'Mystic Run'\nnative-code: 'arm64-v8a'\n"
)
RESOURCE_TABLE = 'resource 0x7f010000 icon\n () (file) res/mipmap/icon.xml type=XML\n'
ANDROID_TOOL_FIXTURES = Path(__file__).resolve().parent/'fixtures'/'android-build-tools-35.0.1'


def read_android_fixture(name):
    return (ANDROID_TOOL_FIXTURES/name).read_text()


class SigningTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.source = self.root/'unsigned.apk'
        # A minimal ELF fixture for the native 16 KB load-segment policy.
        elf = bytearray(128)
        elf[:6] = b'\x7fELF\x02\x01'
        struct.pack_into('<Q', elf, 32, 64)
        struct.pack_into('<HH', elf, 54, 56, 1)
        struct.pack_into('<IIQQQQQQ', elf, 64, 1, 0, 0, 0, 0, 0, 0, 16384)
        with zipfile.ZipFile(self.source, 'w') as archive:
            archive.writestr('lib/arm64-v8a/libgame.so', elf)
            archive.writestr('AndroidManifest.xml', b'binary xml fixture')
            archive.writestr('resources.arsc', b'resource table fixture')
            archive.writestr('res/mipmap/icon.xml', b'binary icon fixture')
            for name in ('godot-LICENSE.txt', 'godot-COPYRIGHT.txt', 'cinzel-OFL.txt',
                         'manrope-OFL.txt', 'bangers-OFL.txt', 'quaternius-CC0.txt'):
                archive.writestr('assets/'+name, b'notice fixture')
        self.manifest = {
            'version_code': 2042, 'version_name': '0.6.2', 'package_id': signing.PACKAGE,
            'requires_owner_signing': True, 'signature_verified': False,
            'git_commit': 'a'*40, 'sha256': hashlib.sha256(self.source.read_bytes()).hexdigest(),
            'bytes': self.source.stat().st_size,
            'builder': {'service': 'github-actions', 'repository': 'Lamont-Labs/Mystic-Run',
                        'run_id': '42', 'commit': 'a'*40},
        }

    def fake_command(self, command, **kwargs):
        parts = [str(x) for x in command]
        if parts[0].endswith('zipalign') and '-f' in parts:
            Path(parts[-1]).write_bytes(Path(parts[-2]).read_bytes())
        if 'sign' in parts:
            self.assertEqual(parts[parts.index('--ks-key-alias')+1], SIGNING_ALIAS)
            self.assertIn('env:MYSTICRUN_STORE_PASSWORD', parts)
            self.assertIn('env:MYSTICRUN_KEY_PASSWORD', parts)
            Path(parts[parts.index('--out')+1]).write_bytes(Path(parts[-1]).read_bytes())
        if 'verify' in parts:
            return SIGNATURE
        if 'badging' in parts:
            return BADGING
        if 'resources' in parts:
            return RESOURCE_TABLE
        if 'xmltree' in parts:
            return 'E: manifest (line=1)\n'
        return ''

    def test_good_unsigned_provenance(self):
        signing.validate_input(self.source, self.manifest, 'a'*40, '42')

    def test_rejects_changed_provenance_identity_versions_or_bytes(self):
        mutations = {
            'package_id': 'wrong.package', 'git_commit': 'b'*40, 'version_code': 0,
            'version_name': 'invalid', 'sha256': '0'*64, 'bytes': 0,
            'requires_owner_signing': 'true', 'signature_verified': None,
            'builder': dict(self.manifest['builder'], run_id='43'),
        }
        for field, value in mutations.items():
            with self.subTest(field=field):
                manifest = copy.deepcopy(self.manifest)
                manifest[field] = value
                with self.assertRaises(ValueError):
                    signing.validate_input(self.source, manifest, 'a'*40, '42')

    def test_signature_requires_pinned_certificate_and_both_schemes(self):
        verify_signature(SIGNATURE)
        real_report = read_android_fixture('good-apksigner-verify.txt')
        verify_signature(real_report)
        for report in (
            SIGNATURE.replace(PERMANENT_CERTIFICATE, '6cae555c'+'0'*56),
            SIGNATURE.replace('v2): true', 'v2): false'),
            SIGNATURE.replace('v3): true', 'v3): false'),
            real_report.replace('Verified using v2 scheme (APK Signature Scheme v2): true\n', ''),
            real_report.replace('Verified using v3 scheme (APK Signature Scheme v3): true\n', ''),
            SIGNATURE.replace('Number of signers: 1', 'Number of signers: 2'),
            SIGNATURE+f'Signer #2 certificate SHA-256 digest: {PERMANENT_CERTIFICATE}\n',
            '',
        ):
            with self.subTest(report=report), self.assertRaises(ValueError):
                verify_signature(report)

    def test_resource_gate_checks_aapt2_and_every_xml(self):
        calls = []
        def command(args):
            calls.append([str(x) for x in args])
            return self.fake_command(args)
        receipt = verify_resources(self.source, self.root, command)
        self.assertTrue(receipt['resource_integrity_verified'])
        self.assertEqual(receipt['packaged_xml_files_checked'], 2)
        self.assertTrue(all(Path(c[0]).name == 'aapt2' for c in calls))

    def test_empty_legacy_or_missing_resource_reference_is_rejected(self):
        for table in ('', 'resource 0x7f010000 string title', '(file)',
                      '(file) res/mipmap/missing.xml', '(file) ../invalid.xml'):
            with self.subTest(table=table), self.assertRaises(ValueError):
                verify_resources(self.source, self.root, lambda _: table)

    def write_real_output_fixture_apk(self, path, include_themed_icon=True):
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr('AndroidManifest.xml', b'binary manifest fixture')
            archive.writestr('resources.arsc', b'binary resource table fixture')
            archive.writestr('res/mipmap-anydpi-v26/icon.xml', b'binary icon fixture')
            if include_themed_icon:
                archive.writestr('res/mipmap-anydpi-v26/themed_icon.xml', b'binary themed icon fixture')

    def real_output_command(self, args, *, themed_xml=None, resources_fixture='good-aapt2-resources.txt'):
        if 'resources' in args:
            return read_android_fixture(resources_fixture)
        file_name = str(args[args.index('--file')+1])
        fixtures = {
            'AndroidManifest.xml': 'good-xmltree-manifest.txt',
            'icon.xml': 'good-xmltree-icon.txt',
            'themed_icon.xml': themed_xml or 'good-xmltree-themed-icon.txt',
        }
        return read_android_fixture(fixtures[Path(file_name).name])

    def test_real_aapt2_outputs_accept_known_good_icon_resources_and_xml(self):
        apk = self.root/'known-good.apk'
        self.write_real_output_fixture_apk(apk)
        calls = []

        def command(args):
            calls.append([str(part) for part in args])
            return self.real_output_command(args)

        result = verify_resources(apk, self.root, command)
        self.assertTrue(result['resource_integrity_verified'])
        self.assertEqual(result['resource_file_references_checked'], 2)
        self.assertEqual(result['packaged_xml_files_checked'], 3)
        self.assertEqual(sum('xmltree' in call for call in calls), 3)

    def test_real_aapt2_reference_rejects_missing_themed_icon_xml(self):
        apk = self.root/'missing-themed-icon.apk'
        self.write_real_output_fixture_apk(apk, include_themed_icon=False)
        with self.assertRaisesRegex(
                ValueError, r'Resource table references missing packaged files: .*themed_icon\.xml'):
            verify_resources(
                apk, self.root,
                lambda args: self.real_output_command(
                    args, resources_fixture='missing-themed-icon-resources.txt'))

    def test_real_aapt2_xmltree_error_output_is_not_accepted_as_parsed_xml(self):
        apk = self.root/'xmltree-error.apk'
        self.write_real_output_fixture_apk(apk)
        with self.assertRaisesRegex(ValueError, 'Packaged XML did not parse'):
            verify_resources(
                apk, self.root,
                lambda args: self.real_output_command(
                    args, themed_xml='missing-themed-icon-xmltree.txt'))

    def test_empty_and_malformed_legacy_aapt_outputs_fail_closed(self):
        for fixture in ('legacy-aapt-empty.txt', 'legacy-aapt-malformed.txt'):
            with self.subTest(fixture=fixture):
                output = read_android_fixture(fixture)
                with self.assertRaisesRegex(ValueError, 'parse was empty or invalid'):
                    verify_resources(self.source, self.root, lambda _args: output)

    def test_malformed_packaged_xml_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'XML did not parse'):
            verify_resources(self.source, self.root,
                             lambda args: RESOURCE_TABLE if 'resources' in args else '')

    def test_successful_signing_writes_verified_evidence(self):
        output = self.root/'signed.apk'
        with patch.object(signing, 'run', side_effect=self.fake_command), patch('builtins.print'):
            signing.sign_and_verify(self.source, output, self.root, self.root/'existing.key',
                                    {}, self.manifest, PERMANENT_CERTIFICATE)
        manifest = json.loads(output.with_suffix('.manifest.json').read_text())
        for field in ('signature_v2_verified', 'signature_v3_verified', 'resource_integrity_verified',
                      'alignment_16k_verified', 'native_16k_alignment_verified',
                      'updates_permanent_identity_installation'):
            self.assertIs(manifest[field], True)
        self.assertFalse(manifest['updates_legacy_owner_installation'])
        self.assertFalse(manifest['owner_game_update_compatible'])
        self.assertEqual(manifest['signing_alias'], 'mysticrun')

    def test_wrong_package_version_signature_or_alignment_blocks_signing(self):
        original = self.source.read_bytes()
        for failure in ('package', 'version', 'signature', 'alignment', 'resources', 'payload', 'native', 'notices'):
            self.source.write_bytes(original)
            def command(args, **kwargs):
                if failure == 'alignment' and '-c' in args:
                    raise RuntimeError('alignment failure')
                result = self.fake_command(args, **kwargs)
                if 'sign' in args and failure in ('payload', 'native', 'notices'):
                    staged = Path(args[args.index('--out')+1])
                    with zipfile.ZipFile(staged) as archive:
                        files = {n: archive.read(n) for n in archive.namelist()}
                    if failure == 'payload':
                        files['extra-game-file'] = b'changed'
                    elif failure == 'native':
                        files['lib/arm64-v8a/libgame.so'] = b'invalid ELF'
                    else:
                        del files['assets/godot-LICENSE.txt']
                    # Also change input for the latter cases, to reach checks after
                    # the unchanged-payload check (provenance was tested separately).
                    targets = [staged, self.source] if failure != 'payload' else [staged]
                    for target in targets:
                        with zipfile.ZipFile(target, 'w') as archive:
                            for name, data in files.items():
                                archive.writestr(name, data)
                if failure == 'package':
                    return result.replace(signing.PACKAGE, 'wrong.package')
                if failure == 'version':
                    return result.replace("versionCode='2042'", "versionCode='2041'")
                if failure == 'signature':
                    return result.replace('v3): true', 'v3): false')
                if failure == 'resources' and 'resources' in args:
                    return ''
                return result
            output = self.root/f'{failure}.apk'
            with self.subTest(failure=failure), patch.object(signing, 'run', side_effect=command):
                with self.assertRaises((ValueError, RuntimeError)):
                    signing.sign_and_verify(self.source, output, self.root, self.root/'existing.key',
                                            {}, self.manifest, PERMANENT_CERTIFICATE)
                self.assertFalse(output.with_suffix('.manifest.json').exists())

    def invoke_main(self, credentials, expected_error, *, certificate=b'fixture cert', verification_error=False):
        key = self.root/'existing.key'
        key.write_bytes(b'not a real private key')
        manifest = self.root/'input.json'
        manifest.write_text(json.dumps(self.manifest))
        output = self.root/'downloads'/'Mystic_Run.apk'
        argv = ['sign_android.py', '--apk', str(self.source), '--manifest', str(manifest),
                '--sdk', str(self.root), '--keystore', str(key), '--output', str(output),
                '--expected-commit', 'a'*40]
        with patch.object(sys, 'argv', argv), patch.dict(os.environ, credentials, clear=True):
            with patch.object(signing.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, certificate)) as process:
                with patch.object(signing, 'sign_and_verify', side_effect=RuntimeError('resource failure')) as verify:
                    with self.assertRaisesRegex((SystemExit, RuntimeError), expected_error):
                        signing.main()
        self.assertFalse(output.parent.exists())
        self.assertEqual(verify.called, verification_error)
        return process

    def test_no_password_fallback_or_key_access_when_secrets_missing(self):
        process = self.invoke_main({}, 'Configure MYSTICRUN_STORE_PASSWORD')
        process.assert_not_called()

    def test_wrong_keystore_certificate_fails_before_signing(self):
        self.invoke_main({'MYSTICRUN_STORE_PASSWORD': 'fixture', 'MYSTICRUN_KEY_PASSWORD': 'fixture'},
                         'Keystore does not match')

    def test_failed_final_verification_exposes_no_download_or_evidence(self):
        with patch.object(signing, 'PERMANENT_CERTIFICATE', hashlib.sha256(b'fixture cert').hexdigest()):
            process = self.invoke_main(
                {'MYSTICRUN_STORE_PASSWORD': 'fixture', 'MYSTICRUN_KEY_PASSWORD': 'fixture'},
                'resource failure', verification_error=True)
        self.assertIn('mysticrun', process.call_args.args[0])

    def test_normal_direct_signed_export_is_blocked(self):
        import build_android
        with patch.object(sys, 'argv', ['build_android.py', '--godot', 'unused', '--sdk', 'unused']):
            with self.assertRaisesRegex(SystemExit, 'compiled with --unsigned'):
                build_android.main()

    def test_workflow_uploads_only_after_signing_and_never_publishes(self):
        root = Path(__file__).resolve().parents[1]
        workflow = (root/'.github/workflows/android-apk.yml').read_text()
        self.assertNotIn('  push:', workflow)
        self.assertNotIn('contents: write', workflow)
        self.assertNotIn('gh release', workflow)
        self.assertNotIn('androiddebugkey', workflow)
        self.assertNotIn('RELAY_DEVELOPMENT_', workflow)
        self.assertIn('environment: android-signing', workflow)
        self.assertIn(PERMANENT_CERTIFICATE, workflow)
        self.assertIn('--expected-run-id "${GITHUB_RUN_ID}"', workflow)
        self.assertLess(workflow.index('tools/sign_android.py'), workflow.index('actions/upload-artifact@'))
        self.assertIn('path: ${{ runner.temp }}/verified-apk/*', workflow)
        publication = (root/'.github/workflows/publish-android.yml').read_text()
        self.assertNotIn('  push:', publication)
        self.assertIn('inputs.approve_publication == true', publication)


if __name__ == '__main__':
    unittest.main()
