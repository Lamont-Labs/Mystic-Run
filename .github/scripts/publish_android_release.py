#!/usr/bin/env python3
"""Restore and publish an already signed APK using public archive/signature data."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import zipfile

REPOSITORY = 'Lamont-Labs/Mystic-Run'
PACKAGE = 'com.lamontlabs.knightgargoylewitch.dev'
CERTIFICATE = 'f5ee5d42ec692e402b52c0457be35c24fe1f92229005002155f675040dddb9c9'
SCHEMA = 'mystic-run-signed-apk-reconstruction/v1'


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def command(arguments, **kwargs):
    result = subprocess.run([str(a) for a in arguments], text=True, capture_output=True, timeout=120, **kwargs)
    if result.returncode:
        raise RuntimeError(result.stdout[-2500:] + result.stderr[-2500:])
    return result.stdout


def zip_layout(data):
    position = data.rfind(b'PK\x05\x06', max(0, len(data)-65557))
    if position < 0 or position+22 > len(data):
        raise ValueError('Missing ZIP end record')
    fields = struct.unpack_from('<4s4H2IH', data, position)
    if fields[1:3] != (0, 0) or fields[3] != fields[4] or fields[4] == 65535:
        raise ValueError('Multi-disk and ZIP64 archives are unsupported')
    size, offset, comment_length = fields[5:8]
    if offset+size != position or position+22+comment_length != len(data):
        raise ValueError('Unexpected central directory or ZIP end-record layout')
    return offset, position, size


def validate_record(record):
    manifest = record['signed_manifest']
    builder = manifest['builder']
    if record.get('schema') != SCHEMA or builder.get('repository') != REPOSITORY or builder.get('service') != 'github-actions':
        raise ValueError('Wrong release record or compilation origin')
    if manifest.get('package_id') != PACKAGE or manifest.get('certificate_sha256') != CERTIFICATE:
        raise ValueError('Wrong Android application or signing identity')
    if not manifest.get('signature_verified') or manifest.get('requires_owner_signing'):
        raise ValueError('The release must be an owner-signed APK')
    if not re.fullmatch(r'[0-9a-f]{40}', manifest['git_commit']) or builder.get('commit') != manifest['git_commit']:
        raise ValueError('Invalid source commit')
    if not re.fullmatch(r'[0-9]+', str(builder['run_id'])):
        raise ValueError('Invalid compilation run')
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', manifest['version_name']) or not isinstance(manifest['version_code'], int):
        raise ValueError('Invalid Android version')
    if not re.fullmatch(r'Mystic_Run_[A-Za-z0-9_.-]+\.apk', manifest['apk']):
        raise ValueError('Unsafe APK asset name')
    for digest in (manifest['sha256'], manifest['unsigned_apk_sha256'], record['unsigned_manifest_sha256']):
        if not re.fullmatch(r'[0-9a-f]{64}', digest):
            raise ValueError('Invalid release digest')
    return manifest


def apply_record(unsigned, unsigned_manifest_bytes, record):
    manifest = validate_record(record)
    if sha256(unsigned) != manifest['unsigned_apk_sha256'] or sha256(unsigned_manifest_bytes) != record['unsigned_manifest_sha256']:
        raise ValueError('Original GitHub compilation does not match the release record')
    original = json.loads(unsigned_manifest_bytes)
    if original['sha256'] != manifest['unsigned_apk_sha256'] or original['git_commit'] != manifest['git_commit'] or original['builder'] != manifest['builder']:
        raise ValueError('Compilation provenance mismatch')
    if not original.get('requires_owner_signing') or original.get('signature_verified'):
        raise ValueError('Expected the unsigned compilation input')
    zip_layout(unsigned)
    segments = record['segments']
    if not segments or len(segments) > 2000:
        raise ValueError('Invalid reconstruction segment count')
    restored = bytearray()
    literal_bytes = 0
    for segment in segments:
        if set(segment) == {'offset', 'length'}:
            offset, length = segment['offset'], segment['length']
            if type(offset) is not int or type(length) is not int or offset < 0 or length < 0 or offset+length > len(unsigned):
                raise ValueError('Invalid compilation copy range')
            restored.extend(unsigned[offset:offset+length])
        elif set(segment) == {'data'}:
            data = base64.b64decode(segment['data'], validate=True)
            literal_bytes += len(data)
            if literal_bytes > 1024*1024:
                raise ValueError('Excessive archive/signature metadata')
            restored.extend(data)
        else:
            raise ValueError('Unknown reconstruction operation')
        if len(restored) > manifest['bytes']:
            raise ValueError('Reconstruction exceeds the expected APK size')
    signed = bytes(restored)
    if len(signed) != manifest['bytes'] or sha256(signed) != manifest['sha256']:
        raise ValueError('Restored signed APK digest mismatch')
    zip_layout(signed)
    return signed


def make_record(unsigned_path, signed_path, unsigned_manifest_path, signed_manifest_path):
    unsigned = unsigned_path.read_bytes()
    signed = signed_path.read_bytes()
    manifest = json.loads(signed_manifest_path.read_text())
    zip_layout(unsigned)
    zip_layout(signed)
    segments = []
    cursor = 0
    def data_start(blob, entry):
        if blob[entry.header_offset:entry.header_offset+4] != b'PK\x03\x04':
            raise ValueError('Invalid ZIP entry header')
        name_length, extra_length = struct.unpack_from('<HH', blob, entry.header_offset+26)
        return entry.header_offset+30+name_length+extra_length
    with zipfile.ZipFile(unsigned_path) as source, zipfile.ZipFile(signed_path) as target:
        entries = {entry.filename:entry for entry in source.infolist()}
        if len(entries) != len(source.infolist()) or set(entries) != set(target.namelist()):
            raise ValueError('Signed APK entry set changed')
        for entry in sorted(target.infolist(), key=lambda value:value.header_offset):
            original = entries[entry.filename]
            start = data_start(signed, entry)
            original_start = data_start(unsigned, original)
            if (original.CRC, original.file_size, original.compress_size, original.compress_type) != (entry.CRC, entry.file_size, entry.compress_size, entry.compress_type):
                raise ValueError('Signing changed a packaged game file')
            if signed[start:start+entry.compress_size] != unsigned[original_start:original_start+original.compress_size]:
                raise ValueError('Signing changed compressed game payload bytes')
            if start < cursor:
                raise ValueError('Overlapping ZIP entries')
            if start > cursor:
                segments.append({'data':base64.b64encode(signed[cursor:start]).decode()})
            if entry.compress_size:
                segments.append({'offset':original_start,'length':entry.compress_size})
            cursor = start+entry.compress_size
    if cursor < len(signed):
        segments.append({'data':base64.b64encode(signed[cursor:]).decode()})
    record = {
        'schema': SCHEMA,
        'unsigned_manifest_sha256': sha256(unsigned_manifest_path.read_bytes()),
        'segments': segments,
        'signed_manifest': manifest,
    }
    if apply_record(unsigned, unsigned_manifest_path.read_bytes(), record) != signed:
        raise ValueError('Signed APK did not round-trip exactly')
    return record


def verify_apk(apk, sdk, manifest):
    tools = sdk/'build-tools/35.0.1'
    signature = command([tools/'apksigner', 'verify', '--verbose', '--print-certs', apk])
    fingerprint = re.search(r'certificate SHA-256 digest: ([0-9a-fA-F]+)', signature)
    if not fingerprint or fingerprint.group(1).lower() != CERTIFICATE:
        raise ValueError('APK signing certificate mismatch')
    command([tools/'zipalign', '-c', '-P', '16', '4', apk])
    metadata = command([tools/'aapt', 'dump', 'badging', apk])
    version = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", metadata)
    if not version or version.groups() != (PACKAGE, str(manifest['version_code']), manifest['version_name']):
        raise ValueError('APK package or version mismatch')
    if "native-code: 'arm64-v8a'" not in metadata or "application-label:'Mystic Run'" not in metadata:
        raise ValueError('APK architecture or application label mismatch')
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None:
            raise ValueError('APK ZIP integrity check failed')
        libraries = [n for n in archive.namelist() if n.endswith('.so')]
        if not libraries:
            raise ValueError('APK has no Android native libraries')
        for name in libraries:
            data = archive.read(name)
            if data[:6] != b'\x7fELF\x02\x01':
                raise ValueError('Unsupported native library format')
            offset = struct.unpack_from('<Q', data, 32)[0]
            size, count = struct.unpack_from('<HH', data, 54)
            loads = [struct.unpack_from('<IIQQQQQQ', data, offset+i*size) for i in range(count)]
            loads = [s for s in loads if s[0] == 1]
            if not loads or not all(s[7] >= 16384 and s[2] % 16384 == s[3] % 16384 for s in loads):
                raise ValueError('Native library is not aligned for 16 KB pages')
    return signature


def write_verification(apk, sdk, manifest):
    if sha256(apk.read_bytes()) != manifest['sha256']:
        raise ValueError('APK bytes do not match the signed release')
    signature = verify_apk(apk, sdk, manifest)
    apk.with_suffix('.manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    (apk.parent/'APK-SIGNATURE.txt').write_text(signature)
    (apk.parent/'SHA256SUMS').write_text(manifest['sha256']+'  '+apk.name+'\n')


def prepare(record, input_directory, output_directory, sdk):
    manifest = validate_record(record)
    candidates = list(input_directory.rglob('apk-manifest.json'))
    if len(candidates) != 1:
        raise ValueError('Expected one original compilation manifest')
    original_path = candidates[0]
    original = json.loads(original_path.read_text())
    if Path(original['apk']).name != original['apk']:
        raise ValueError('Unsafe compilation filename')
    unsigned_path = original_path.parent/original['apk']
    signed = apply_record(unsigned_path.read_bytes(), original_path.read_bytes(), record)
    output_directory.mkdir(parents=True, exist_ok=True)
    apk = output_directory/manifest['apk']
    apk.write_bytes(signed)
    write_verification(apk, sdk, manifest)
    return apk


def publish(records_directory, output_directory, sdk):
    if os.environ.get('GITHUB_REPOSITORY') != REPOSITORY:
        raise ValueError('Release job must run in the canonical repository')
    records = [json.loads(p.read_text()) for p in records_directory.glob('*.json')]
    if not records:
        raise ValueError('No signed release records found')
    for record in records:
        validate_record(record)
    record = max(records, key=lambda r:r['signed_manifest']['version_code'])
    manifest = record['signed_manifest']
    tag = f"v{manifest['version_name']}-build{manifest['version_code']}"
    existing = subprocess.run(['gh', 'release', 'view', tag, '--repo', REPOSITORY], capture_output=True, text=True, timeout=60)
    if existing.returncode == 0:
        output_directory.mkdir(parents=True, exist_ok=True)
        command(['gh', 'release', 'download', tag, '--repo', REPOSITORY, '--pattern', manifest['apk'], '--dir', output_directory])
        write_verification(output_directory/manifest['apk'], sdk, manifest)
        print(command(['gh', 'release', 'view', tag, '--repo', REPOSITORY, '--json', 'url,assets']))
        return
    if 'release not found' not in existing.stderr.lower():
        raise RuntimeError('Could not inspect the release: '+existing.stderr[-1000:])
    run_id = str(manifest['builder']['run_id'])
    run = json.loads(command(['gh', 'api', f'repos/{REPOSITORY}/actions/runs/{run_id}']))
    if run['conclusion'] != 'success' or run['head_sha'] != manifest['git_commit'] or run['path'] != '.github/workflows/android-compile.yml':
        raise ValueError('Original GitHub compilation was not verified as successful')
    with tempfile.TemporaryDirectory(prefix='mystic-release-') as temporary:
        directory = Path(temporary)
        command(['gh', 'run', 'download', run_id, '--repo', REPOSITORY, '--name', 'mystic-run-unsigned-android', '--dir', directory/'input'])
        apk = prepare(record, directory/'input', output_directory, sdk)
        notes = directory/'release-notes.md'
        notes.write_text('Installable arm64 Android development alpha. Download the .apk under Assets and open it on your phone.\n\n'
            f"GitHub compilation: {run['html_url']}\n\nSource commit: `{manifest['git_commit']}`.\n\n"
            'The APK preserves the existing signing identity. Signature, package/version, ZIP integrity, APK alignment and native 16 KB alignment were verified. Physical phone testing remains pending.\n')
        assets = [apk, output_directory/apk.with_suffix('.manifest.json').name, output_directory/'APK-SIGNATURE.txt', output_directory/'SHA256SUMS']
        command(['gh', 'release', 'create', tag, '--repo', REPOSITORY, '--target', manifest['git_commit'], '--title', f"Mystic Run {manifest['version_name']} - Android build {manifest['version_code']}", '--notes-file', notes, '--prerelease', *assets])
        command(['gh', 'release', 'download', tag, '--repo', REPOSITORY, '--pattern', apk.name, '--dir', directory/'published'])
        if sha256((directory/'published'/apk.name).read_bytes()) != manifest['sha256']:
            raise ValueError('Published GitHub APK bytes do not match the verified build')
        print(command(['gh', 'release', 'view', tag, '--repo', REPOSITORY, '--json', 'url,assets']))


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest='operation', required=True)
    make = commands.add_parser('make')
    for name in ('unsigned', 'signed', 'unsigned-manifest', 'signed-manifest', 'output'):
        make.add_argument('--'+name, type=Path, required=True)
    check = commands.add_parser('prepare')
    check.add_argument('--record', type=Path, required=True)
    check.add_argument('--input', type=Path, required=True)
    release = commands.add_parser('publish')
    release.add_argument('--records', type=Path, required=True)
    for command_parser in (check, release):
        command_parser.add_argument('--output', type=Path, required=True)
        command_parser.add_argument('--sdk', type=Path, required=True)
    args = parser.parse_args()
    if args.operation == 'make':
        record = make_record(args.unsigned, args.signed, args.unsigned_manifest, args.signed_manifest)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(record, indent=2)+'\n')
        print('Public archive/signature record created; signed APK restored byte-for-byte')
    elif args.operation == 'prepare':
        apk = prepare(json.loads(args.record.read_text()), args.input, args.output, args.sdk)
        print('Verified installable release APK:', apk)
    else:
        publish(args.records, args.output, args.sdk)


if __name__ == '__main__':
    main()
