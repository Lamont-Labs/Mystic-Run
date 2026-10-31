#!/usr/bin/env python3
"""Export and independently verify an owner-signed Android development APK."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


def run(command, **kwargs):
    result = subprocess.run([str(x) for x in command],text=True,capture_output=True,**kwargs)
    if result.returncode:
        raise RuntimeError(result.stdout[-3500:] + result.stderr[-3500:])
    return result.stdout


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--sdk',type=Path,required=True)
    parser.add_argument('--keystore',type=Path,required=True)
    parser.add_argument('--version-code',type=int,default=3)
    parser.add_argument('--version-name',default='0.1.2')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    args.godot=args.godot.resolve();args.sdk=args.sdk.resolve();args.keystore=args.keystore.resolve()
    if not args.keystore.is_file():
        raise SystemExit('Persistent development keystore is required; do not replace it on every build.')
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
    java=Path(os.environ.get('JAVA_HOME_17_X64') or os.environ.get('JAVA_HOME') or '/usr/lib/jvm/java-17-openjdk-amd64')
    replacements={
        'export/android/android_sdk_path':str(args.sdk),
        'export/android/java_sdk_path':str(java),
        'export/android/debug_keystore':str(args.keystore),
        'export/android/debug_keystore_pass':os.environ.get('RELAY_KEY_PASSWORD') or 'android',
    }
    text=settings.read_text()
    for key,value in replacements.items():
        line=key+' = '+json.dumps(value)
        pattern=r'^'+re.escape(key)+r' = .*?\n'
        if re.search(pattern,text,re.M):text=re.sub(pattern,line+'\n',text,flags=re.M)
        else:text+='\n'+line+'\n'
    settings.write_text(text)
    preset=root/'export_presets.cfg'
    text=preset.read_text()
    text=re.sub(r'version/code=\d+',f'version/code={args.version_code}',text)
    text=re.sub(r'version/name="[^"]+"',f'version/name="{args.version_name}"',text)
    preset.write_text(text)
    project=root/'project.godot'
    project.write_text(re.sub(r'config/version="[^"]+"',f'config/version="{args.version_name}"',project.read_text()))
    output=args.output.resolve() if args.output else root/'build'/f'Mystic_Run_{args.version_name}.apk'
    output.parent.mkdir(parents=True,exist_ok=True)
    output.unlink(missing_ok=True)
    exported=subprocess.run([str(args.godot),'--headless','--path',str(root),'--export-debug','Android',str(output)],text=True,capture_output=True,timeout=180)
    (output.parent/'android-export.log').write_text(exported.stdout+exported.stderr)
    if exported.returncode or not output.is_file():
        raise RuntimeError('Android export failed; inspect android-export.log')
    if re.search(r'^(?:SCRIPT )?ERROR:',exported.stdout+'\n'+exported.stderr,re.M):
        raise RuntimeError('Android export reported an engine error; inspect android-export.log')
    signature=run([tools/'apksigner','verify','--verbose','--print-certs',output],timeout=30)
    alignment=run([tools/'zipalign','-c','-P','16','4',output],timeout=30)
    metadata=run([tools/'aapt','dump','badging',output],timeout=30)
    package=re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",metadata)
    if not package or package.group(1)!='com.lamontlabs.knightgargoylewitch.dev':
        raise RuntimeError('Unexpected package identity')
    if int(package.group(2))!=args.version_code or package.group(3)!=args.version_name:
        raise RuntimeError('Exported version does not match the requested version')
    if "application-label:'Mystic Run'" not in metadata or "native-code: 'arm64-v8a'" not in metadata:
        raise RuntimeError('Unexpected application label or Android architecture')
    fingerprint=re.search(r'certificate SHA-256 digest: ([0-9a-fA-F]+)',signature)
    if not fingerprint:
        raise RuntimeError('No signing certificate fingerprint reported')
    key_env=os.environ.copy()
    key_env['RELAY_VERIFY_KEY_PASSWORD']=replacements['export/android/debug_keystore_pass']
    certificate=subprocess.run([str(java/'bin/keytool'),'-exportcert','-alias','androiddebugkey','-keystore',str(args.keystore),'-storepass:env','RELAY_VERIFY_KEY_PASSWORD'],capture_output=True,env=key_env,timeout=30)
    if certificate.returncode or hashlib.sha256(certificate.stdout).hexdigest()!=fingerprint.group(1).lower():
        raise RuntimeError('APK signing certificate does not match the preserved development keystore')
    source_paths=run(['git','ls-files'],cwd=root).splitlines() if(root/'.git').exists() else []
    manifest={
        'apk':output.name,'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
        'package_id':package.group(1),'version_code':int(package.group(2)),'version_name':package.group(3),
        'certificate_sha256':fingerprint.group(1).lower(),'signature_verified':True,'alignment_16k_verified':True,
        'preserved_keystore_matched':True,
        'engine':run([args.godot,'--version']).strip(),'physical_phone_tested':False,
        'git_commit':run(['git','rev-parse','HEAD'],cwd=root).strip() if(root/'.git').exists() else None,
        'git_worktree_changes':run(['git','status','--porcelain'],cwd=root).splitlines() if(root/'.git').exists() else [],
        'source_sha256':{path:hashlib.sha256((root/path).read_bytes()).hexdigest() for path in source_paths if(root/path).is_file()},
    }
    (output.parent/'apk-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (output.parent/'apk-signature.txt').write_text(signature)
    (output.parent/'apk-package.txt').write_text(metadata)
    print(json.dumps({k:v for k,v in manifest.items() if k!='source_sha256'},indent=2))


if __name__=='__main__':
    main()
