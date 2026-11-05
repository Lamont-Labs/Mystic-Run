#!/usr/bin/env python3
"""Export a signed development APK or an explicitly unsigned CI compilation."""
import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile
from android_policy import inspect_package
from asset_foundry import verify as verify_assets

OWNER_CERTIFICATE='6cae555cdc35ea335e5ca6f29252bfad9ebc1cbc9a12c83e18c7eb1038a6a8cf'
ART_PREVIEW_CERTIFICATE='cced8d8dca20fd35d169f546802953375c76fad3559cdbcbe896271c61f26f5e'


def run(command, **kwargs):
    result = subprocess.run([str(x) for x in command],text=True,capture_output=True,**kwargs)
    if result.returncode:
        raise RuntimeError(result.stdout[-3500:] + result.stderr[-3500:])
    return result.stdout


def signing_certificate(keystore, java, password):
    """Read the public certificate without putting the password in argv or logs."""
    key_env=os.environ.copy()
    key_env['RELAY_VERIFY_KEY_PASSWORD']=password
    certificate=subprocess.run(
        [str(java/'bin/keytool'),'-exportcert','-alias','androiddebugkey',
         '-keystore',str(keystore),'-storepass:env','RELAY_VERIFY_KEY_PASSWORD'],
        capture_output=True,env=key_env,timeout=30,
    )
    if certificate.returncode:
        raise RuntimeError('Unable to read the development signing certificate')
    return hashlib.sha256(certificate.stdout).hexdigest()


@contextmanager
def export_configuration(root, version_code, version_name, package_id, app_name, signed):
    """Apply one APK preset temporarily; restore source even if export fails."""
    preset=root/'export_presets.cfg'
    project=root/'project.godot'
    original_preset=preset.read_bytes()
    original_project=project.read_bytes()
    try:
        text=original_preset.decode('utf-8')
        # Only the Android APK preset changes. The Play preset keeps its identity.
        apk, separator, remaining=text.partition('[preset.1]')
        replacements={
            r'version/code=\d+':f'version/code={version_code}',
            r'version/name="[^"]+"':f'version/name="{version_name}"',
            r'package/signed=(?:true|false)':'package/signed='+('true' if signed else 'false'),
            r'package/unique_name="[^"]+"':f'package/unique_name="{package_id}"',
            r'package/name="[^"]+"':f'package/name="{app_name}"',
        }
        for pattern, replacement in replacements.items():
            apk,count=re.subn(pattern,replacement,apk)
            if count!=1:
                raise RuntimeError('Expected exactly one APK preset value for '+pattern)
        preset.write_text(apk+separator+remaining)
        updated,count=re.subn(r'config/version="[^"]+"',f'config/version="{version_name}"',original_project.decode('utf-8'))
        if count!=1:
            raise RuntimeError('Expected exactly one project version')
        project.write_text(updated)
        yield {'export_presets_sha256':hashlib.sha256(preset.read_bytes()).hexdigest(),
               'project_sha256':hashlib.sha256(project.read_bytes()).hexdigest()}
    finally:
        preset.write_bytes(original_preset)
        project.write_bytes(original_project)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--sdk',type=Path,required=True)
    parser.add_argument('--keystore',type=Path)
    parser.add_argument('--unsigned',action='store_true',help='Compile without a key; output requires owner signing before installation')
    parser.add_argument('--version-code',type=int,default=1014)
    parser.add_argument('--version-name',default='0.6.1')
    parser.add_argument('--output',type=Path)
    parser.add_argument('--art-preview',action='store_true',help='Build a separately installed art preview; never an update to the owner-signed game')
    args=parser.parse_args()
    package_id='com.lamontlabs.knightgargoylewitch.artpreview' if args.art_preview else 'com.lamontlabs.knightgargoylewitch.dev'
    app_name='Mystic Run Art Preview' if args.art_preview else 'Mystic Run'
    root=Path(__file__).resolve().parents[1]
    asset_inventory=verify_assets(root)
    args.godot=args.godot.resolve();args.sdk=args.sdk.resolve()
    if args.keystore:
        args.keystore=args.keystore.resolve()
    if not args.unsigned and (not args.keystore or not args.keystore.is_file()):
        raise SystemExit('Persistent development keystore is required; do not replace it on every build.')
    if args.unsigned and args.keystore:
        raise SystemExit('Choose unsigned compilation or owner signing, not both')
    if args.version_code<=0 or not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+',args.version_name):
        raise SystemExit('Invalid development version')
    tools=args.sdk/'build-tools/35.0.1'
    for name in ['apksigner','zipalign','aapt']:
        if not(tools/name).is_file():
            raise SystemExit(f'Missing SDK tool: {name}')
    adb=args.sdk/'platform-tools/adb'
    if adb.is_file():
        subprocess.run([str(adb),'start-server'],text=True,capture_output=True,timeout=20)
    run([args.godot,'--headless','--path',root,'--editor','--import','--quit'],timeout=120)
    settings=Path.home()/'.config/godot/editor_settings-4.7.tres'
    if not settings.is_file():
        raise SystemExit('Expected Linux Godot 4.7 editor settings after import')
    java_home=os.environ.get('JAVA_HOME_17_X64') or os.environ.get('JAVA_HOME')
    if not java_home:
        java_binary=shutil.which('java')
        if not java_binary:
            raise SystemExit('A Java SDK with keytool is required for Android export')
        java_home=Path(java_binary).resolve().parent.parent
    java=Path(java_home)
    if not (java/'bin/keytool').is_file():
        raise SystemExit('The configured Java SDK has no keytool')
    password=os.environ.get('RELAY_KEY_PASSWORD') or 'android'
    expected_certificate=ART_PREVIEW_CERTIFICATE if args.art_preview else OWNER_CERTIFICATE
    if not args.unsigned and signing_certificate(args.keystore,java,password)!=expected_certificate:
        raise SystemExit('Signing identity does not match the selected build variant; the owner game and Art Preview use separate preserved keys')
    replacements={
        'export/android/android_sdk_path':str(args.sdk),
        'export/android/java_sdk_path':str(java),
    }
    if not args.unsigned:
        replacements.update({
            'export/android/debug_keystore':str(args.keystore),
            'export/android/debug_keystore_pass':password,
        })
    text=settings.read_text()
    for key,value in replacements.items():
        line=key+' = '+json.dumps(value)
        pattern=r'^'+re.escape(key)+r' = .*?\n'
        if re.search(pattern,text,re.M):text=re.sub(pattern,line+'\n',text,flags=re.M)
        else:text+='\n'+line+'\n'
    settings.write_text(text)
    suffix='_unsigned' if args.unsigned else ''
    output=args.output.resolve() if args.output else root/'build'/f'Mystic_Run_{args.version_name}{suffix}.apk'
    output.parent.mkdir(parents=True,exist_ok=True)
    output.unlink(missing_ok=True)
    with export_configuration(root,args.version_code,args.version_name,package_id,app_name,not args.unsigned) as exported_configuration:
        exported=subprocess.run([str(args.godot),'--headless','--path',str(root),'--export-debug','Android',str(output)],text=True,capture_output=True,timeout=180)
    (output.parent/'android-export.log').write_text(exported.stdout+exported.stderr)
    if exported.returncode or not output.is_file():
        raise RuntimeError('Android export failed; inspect android-export.log')
    if re.search(r'^(?:SCRIPT )?ERROR:',exported.stdout+'\n'+exported.stderr,re.M):
        raise RuntimeError('Android export reported an engine error; inspect android-export.log')
    certificate_sha=None
    if args.unsigned:
        verification=subprocess.run([str(tools/'apksigner'),'verify',str(output)],capture_output=True,text=True,timeout=30)
        if verification.returncode==0:
            raise RuntimeError('Unsigned compilation unexpectedly contains a valid signing identity')
        signature='UNSIGNED COMPILATION: owner signing is required before installation.\n'
    else:
        signature=run([tools/'apksigner','verify','--verbose','--print-certs',output],timeout=30)
    alignment=run([tools/'zipalign','-c','-P','16','4',output],timeout=30)
    metadata=run([tools/'aapt','dump','badging',output],timeout=30)
    android_policy=inspect_package(metadata)
    package=re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",metadata)
    if not package or package.group(1)!=package_id:
        raise RuntimeError('Unexpected package identity')
    if int(package.group(2))!=args.version_code or package.group(3)!=args.version_name:
        raise RuntimeError('Exported version does not match the requested version')
    if "application-label:'"+app_name+"'" not in metadata or "native-code: 'arm64-v8a'" not in metadata:
        raise RuntimeError('Unexpected application label or Android architecture')
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise RuntimeError('APK ZIP integrity check failed')
    if not args.unsigned:
        fingerprint=re.search(r'certificate SHA-256 digest: ([0-9a-fA-F]+)',signature)
        if not fingerprint:
            raise RuntimeError('No signing certificate fingerprint reported')
        certificate_sha=fingerprint.group(1).lower()
        if certificate_sha!=expected_certificate:
            raise RuntimeError('APK signing certificate differs from the preserved build identity')
        if signing_certificate(args.keystore,java,password)!=certificate_sha:
            raise RuntimeError('APK signing certificate does not match the preserved development keystore')
    source_paths=run(['git','ls-files'],cwd=root).splitlines() if(root/'.git').exists() else []
    manifest={
        'asset_inventory':asset_inventory,
        **android_policy,
        'apk':output.name,'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
        'package_id':package.group(1),'version_code':int(package.group(2)),'version_name':package.group(3),
        'build_variant':'isolated-art-preview' if args.art_preview else 'owner-development',
        'exported_configuration_sha256':exported_configuration,
        'source_configuration_restored':True,
        'owner_game_update_compatible':not args.art_preview and not args.unsigned,
        'certificate_sha256':certificate_sha,'signature_verified':not args.unsigned,'alignment_16k_verified':True,
        'preserved_keystore_matched':not args.unsigned,'requires_owner_signing':args.unsigned,'zip_integrity_verified':True,
        'engine':run([args.godot,'--version']).strip(),'physical_phone_tested':False,
        'git_commit':run(['git','rev-parse','HEAD'],cwd=root).strip() if(root/'.git').exists() else None,
        'git_worktree_changes':run(['git','status','--porcelain'],cwd=root).splitlines() if(root/'.git').exists() else [],
        'source_sha256':{path:hashlib.sha256((root/path).read_bytes()).hexdigest() for path in source_paths if(root/path).is_file()},
        'builder':{
            'service':'github-actions' if os.environ.get('GITHUB_ACTIONS')=='true' else 'local',
            'repository':os.environ.get('GITHUB_REPOSITORY'),
            'run_id':os.environ.get('GITHUB_RUN_ID'),
            'run_attempt':os.environ.get('GITHUB_RUN_ATTEMPT'),
            'workflow':os.environ.get('GITHUB_WORKFLOW'),
            'commit':os.environ.get('GITHUB_SHA'),
        },
    }
    (output.parent/'apk-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (output.parent/'apk-signature.txt').write_text(signature)
    (output.parent/'apk-package.txt').write_text(metadata)
    print(json.dumps({k:v for k,v in manifest.items() if k!='source_sha256'},indent=2))


if __name__=='__main__':
    main()
