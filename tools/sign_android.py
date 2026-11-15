#!/usr/bin/env python3
"""Sign an existing APK while preserving and checking its compilation provenance."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import zipfile

from build_android import run
from android_policy import inspect_package
from android_verification import PACKAGE, SIGNING_ALIAS, PERMANENT_CERTIFICATE, verify_signature, verify_resources



def validate_input(apk, manifest, expected_commit, expected_run_id=None):
    if type(manifest.get('version_code')) is not int or not 0 < manifest['version_code'] <= 2100000000:
        raise ValueError('Invalid Android version code')
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', manifest.get('version_name', '')):
        raise ValueError('Invalid Android version name')
    if manifest.get('requires_owner_signing') is not True or manifest.get('signature_verified') is not False:
        raise ValueError('Only explicitly unsigned compilation output is accepted')
    if manifest.get('package_id')!=PACKAGE:
        raise ValueError('Unexpected application identity')
    if manifest.get('git_commit')!=expected_commit:
        raise ValueError('Compilation commit does not match the verified source commit')
    if expected_run_id:
        builder=manifest.get('builder',{})
        if builder.get('service')!='github-actions' or builder.get('repository')!='Lamont-Labs/Mystic-Run':
            raise ValueError('Expected the canonical GitHub Actions compilation')
        if str(builder.get('run_id'))!=str(expected_run_id) or builder.get('commit')!=expected_commit:
            raise ValueError('GitHub run identity or source commit mismatch')
    if apk.stat().st_size!=manifest.get('bytes') or hashlib.sha256(apk.read_bytes()).hexdigest()!=manifest.get('sha256'):
        raise ValueError('Compilation bytes do not match the downloaded manifest')


def verify_native(archive):
    libraries=[]
    for name in archive.namelist():
        if not name.endswith('.so'):
            continue
        data=archive.read(name)
        if data[:6]!=b'\x7fELF\x02\x01':
            raise ValueError('Expected a little-endian 64-bit Android library')
        offset=struct.unpack_from('<Q',data,32)[0]
        size,count=struct.unpack_from('<HH',data,54)
        segments=[struct.unpack_from('<IIQQQQQQ',data,offset+i*size) for i in range(count)]
        loads=[s for s in segments if s[0]==1]
        if not loads or not all(s[7]>=16384 and s[2]%16384==s[3]%16384 for s in loads):
            raise ValueError('Native library is not aligned for 16 KB pages: '+name)
        libraries.append({'library':name,'load_segment_alignment':[s[7] for s in loads]})
    if not libraries:
        raise ValueError('APK contains no Android native libraries')
    return libraries


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--apk',type=Path,required=True)
    parser.add_argument('--manifest',type=Path,required=True)
    parser.add_argument('--sdk',type=Path,required=True)
    parser.add_argument('--keystore',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--expected-commit',required=True)
    parser.add_argument('--expected-run-id')
    parser.add_argument('--permanent-identity',action='store_true',help='Compatibility flag; replacement permanent identity is always required')
    args=parser.parse_args()
    expected_certificate=PERMANENT_CERTIFICATE
    source=args.apk.resolve();output=args.output.resolve()
    destinations=[output, output.with_suffix('.manifest.json'), output.with_suffix('.signature.txt'), output.with_suffix('.package.txt')]
    if source in destinations or args.manifest.resolve() in destinations or args.keystore.resolve() in destinations or not args.keystore.is_file() or any(p.exists() for p in destinations):
        raise SystemExit('Unused separate output paths and the preserved keystore are required')
    if not os.environ.get('MYSTICRUN_STORE_PASSWORD') or not os.environ.get('MYSTICRUN_KEY_PASSWORD'):
        raise SystemExit('Configure MYSTICRUN_STORE_PASSWORD and MYSTICRUN_KEY_PASSWORD securely; no password fallback is permitted')
    manifest=json.loads(args.manifest.read_text())
    validate_input(source,manifest,args.expected_commit,args.expected_run_id)
    sdk=args.sdk.resolve()/'build-tools/35.0.1'
    env=os.environ.copy()
    java=Path(os.environ.get('JAVA_HOME_17_X64') or os.environ.get('JAVA_HOME') or '/usr/lib/jvm/java-17-openjdk-amd64')
    certificate=subprocess.run([str(java/'bin/keytool'),'-exportcert','-alias',SIGNING_ALIAS,'-keystore',str(args.keystore.resolve()),'-storepass:env','MYSTICRUN_STORE_PASSWORD'],capture_output=True,env=env,timeout=30)
    if certificate.returncode or hashlib.sha256(certificate.stdout).hexdigest()!=expected_certificate:
        raise SystemExit('Keystore does not match the preserved Mystic Run signing identity')
    with tempfile.TemporaryDirectory(prefix='mystic-verified-') as temporary:
        staged=Path(temporary)/output.name
        sign_and_verify(source, staged, sdk, args.keystore.resolve(), env, manifest, expected_certificate)
        output.parent.mkdir(parents=True,exist_ok=True)
        # The workflow uploads only this directory, after all checks succeed.
        for path in Path(temporary).iterdir():
            shutil.copyfile(path, output.parent/path.name)


def sign_and_verify(source, output, sdk, keystore, env, manifest, expected_certificate):
    with tempfile.TemporaryDirectory(prefix='mystic-sign-') as temporary:
        aligned=Path(temporary)/'aligned.apk'
        run([sdk/'zipalign','-f','-P','16','4',source,aligned],timeout=60)
        run([sdk/'apksigner','sign','--ks',keystore,'--ks-key-alias',SIGNING_ALIAS,'--ks-pass','env:MYSTICRUN_STORE_PASSWORD','--key-pass','env:MYSTICRUN_KEY_PASSWORD','--v1-signing-enabled','false','--v2-signing-enabled','true','--v3-signing-enabled','true','--v4-signing-enabled','false','--out',output,aligned],env=env,timeout=60)
    signature=run([sdk/'apksigner','verify','--verbose','--print-certs',output],timeout=30)
    verify_signature(signature, expected_certificate)
    resources=verify_resources(output, sdk, run)
    run([sdk/'zipalign','-c','-P','16','4',output],timeout=30)
    metadata=run([sdk/'aapt','dump','badging',output],timeout=30)
    android_policy=inspect_package(metadata)
    package=re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",metadata)
    if not package or package.groups()!=(PACKAGE,str(manifest['version_code']),manifest['version_name']):
        raise RuntimeError('Signing changed the expected package or version')
    if "application-label:'Mystic Run'" not in metadata or "native-code: 'arm64-v8a'" not in metadata:
        raise RuntimeError('Unexpected application label or architecture')
    with zipfile.ZipFile(source) as before,zipfile.ZipFile(output) as after:
        if after.testzip() is not None:
            raise RuntimeError('Signed ZIP integrity check failed')
        before_files={f.filename:hashlib.sha256(before.read(f)).hexdigest() for f in before.infolist()}
        after_files={f.filename:hashlib.sha256(after.read(f)).hexdigest() for f in after.infolist()}
        if before_files!=after_files:
            raise RuntimeError('Signing unexpectedly changed packaged game files')
        libraries=verify_native(after)
        notices=[n for n in after.namelist() if n.endswith(('godot-LICENSE.txt','godot-COPYRIGHT.txt','cinzel-OFL.txt','manrope-OFL.txt','bangers-OFL.txt','quaternius-CC0.txt'))]
        if len(notices)!=6:
            raise RuntimeError('Required bundled notices are missing')
    signed=dict(manifest)
    signed.update({
        **android_policy,
        **resources,
        'apk':output.name,'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
        'unsigned_apk_sha256':manifest['sha256'],'certificate_sha256':expected_certificate,
        'signature_verified':True,'requires_owner_signing':False,'preserved_keystore_matched':True,
        'owner_game_update_compatible':False,
        'permanent_signing_identity':True,
        'updates_legacy_owner_installation':False,
        'updates_permanent_identity_installation':True,
        'signature_v2_verified':True,'signature_v3_verified':True,'signing_alias':SIGNING_ALIAS,
        'alignment_16k_verified':True,'native_16k_alignment_verified':True,'zip_integrity_verified':True,
        'packaged_game_files_unchanged_by_signing':True,'signing_service':'preserved-replacement-key',
        'native_libraries':libraries,
    })
    output.with_suffix('.manifest.json').write_text(json.dumps(signed,indent=2)+'\n')
    output.with_suffix('.signature.txt').write_text(signature)
    output.with_suffix('.package.txt').write_text(metadata)
    print(json.dumps({k:v for k,v in signed.items() if k not in ('source_sha256','git_worktree_changes')},indent=2))


if __name__=='__main__':
    main()

