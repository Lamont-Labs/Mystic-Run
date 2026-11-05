"""Publish the exact locally verified art preview without storing signing keys."""
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

from publish_android_release import command, sha256, zip_layout, REPOSITORY, PACKAGE as OWNER_PACKAGE

SCHEMA='mystic-run-isolated-art-preview/v1'
PACKAGE='com.lamontlabs.knightgargoylewitch.artpreview'
CERTIFICATE='cced8d8dca20fd35d169f546802953375c76fad3559cdbcbe896271c61f26f5e'
LABEL='Mystic Run Art Preview'
RUNTIME_PREFIXES=('assets/','game/','core/','content/','scenes/')


def validate_record(record):
    manifest=record['signed_manifest']
    compilation=record['compilation']
    builder=compilation['builder']
    if record.get('schema')!=SCHEMA:
        raise ValueError('Unexpected preview record schema')
    if manifest.get('package_id')!=PACKAGE or manifest.get('certificate_sha256')!=CERTIFICATE:
        raise ValueError('Wrong preview application or preserved certificate')
    if manifest.get('build_variant')!='isolated-art-preview' or manifest.get('owner_game_update_compatible') is not False:
        raise ValueError('Preview must remain a separate installation')
    if not manifest.get('signature_verified') or manifest.get('requires_owner_signing'):
        raise ValueError('Preview must already be signed and verified')
    if manifest.get('builder',{}).get('service')!='local':
        raise ValueError('This preview record describes a locally exported APK')
    if builder.get('service')!='github-actions' or builder.get('repository')!=REPOSITORY:
        raise ValueError('Expected the canonical GitHub compilation base')
    if not re.fullmatch(r'[0-9a-f]{40}',manifest['git_commit']) or builder.get('commit')!=manifest['git_commit']:
        raise ValueError('Compilation and preview must use the same source commit')
    if not re.fullmatch(r'[0-9]+',str(builder.get('run_id',''))):
        raise ValueError('Invalid compilation run')
    if type(manifest['version_code']) is not int or manifest['version_code']<=0 or not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+',manifest['version_name']):
        raise ValueError('Invalid preview version')
    if not re.fullmatch(r'Mystic_Run_[A-Za-z0-9_.-]+_Art_Preview_Build[0-9]+\.apk',manifest['apk']):
        raise ValueError('Unsafe preview APK name')
    if type(manifest['bytes']) is not int or not 0<manifest['bytes']<100*1024*1024:
        raise ValueError('Invalid preview byte count')
    for digest in [manifest['sha256'],compilation['apk_sha256'],compilation['manifest_sha256']]:
        if not re.fullmatch(r'[0-9a-f]{64}',digest):
            raise ValueError('Invalid preview digest')
    return manifest


def apply_record(unsigned, manifest_bytes, record):
    target=validate_record(record)
    compilation=record['compilation']
    if sha256(unsigned)!=compilation['apk_sha256'] or sha256(manifest_bytes)!=compilation['manifest_sha256']:
        raise ValueError('Compilation base bytes changed')
    original=json.loads(manifest_bytes)
    if original['builder']!=compilation['builder'] or original['git_commit']!=target['git_commit']:
        raise ValueError('Compilation provenance changed')
    if original.get('package_id')!=OWNER_PACKAGE or not original.get('requires_owner_signing') or original.get('signature_verified'):
        raise ValueError('Expected the unsigned owner-package compilation base')
    if original['sha256']!=compilation['apk_sha256']:
        raise ValueError('Compilation manifest digest mismatch')
    runtime={k:v for k,v in target['source_sha256'].items() if k.startswith(RUNTIME_PREFIXES)}
    if not runtime or any(original['source_sha256'].get(k)!=v for k,v in runtime.items()):
        raise ValueError('Preview runtime source differs from GitHub compilation')
    zip_layout(unsigned)
    segments=record['segments']
    if not segments or len(segments)>8000:
        raise ValueError('Invalid preview reconstruction segment count')
    restored=bytearray()
    literal_bytes=0
    for part in segments:
        if set(part)=={'offset','length'}:
            offset,length=part['offset'],part['length']
            if type(offset) is not int or type(length) is not int or offset<0 or length<0 or offset+length>len(unsigned):
                raise ValueError('Invalid compilation copy range')
            restored.extend(unsigned[offset:offset+length])
        elif set(part)=={'data'}:
            data=base64.b64decode(part['data'],validate=True)
            literal_bytes+=len(data)
            if literal_bytes>1024*1024:
                raise ValueError('Preview record contains excessive literal bytes')
            restored.extend(data)
        else:
            raise ValueError('Unknown preview reconstruction operation')
        if len(restored)>target['bytes']:
            raise ValueError('Preview reconstruction exceeds its expected size')
    result=bytes(restored)
    if len(result)!=target['bytes'] or sha256(result)!=target['sha256']:
        raise ValueError('Preview signed APK digest mismatch')
    zip_layout(result)
    return result


def make_record(unsigned_path, signed_path, unsigned_manifest_path, signed_manifest_path):
    """Copy identical byte ranges, storing only small public export/signature deltas."""
    unsigned=unsigned_path.read_bytes()
    signed=signed_path.read_bytes()
    target=json.loads(signed_manifest_path.read_text())
    original_bytes=unsigned_manifest_path.read_bytes()
    original=json.loads(original_bytes)
    target['source_sha256']={k:v for k,v in target['source_sha256'].items() if k.startswith(RUNTIME_PREFIXES)}
    target.pop('git_worktree_changes',None)
    parts=[]

    def literal(data):
        if not data: return
        if parts and set(parts[-1])=={'data'}:
            data=base64.b64decode(parts.pop()['data'])+data
        parts.append({'data':base64.b64encode(data).decode()})

    def copy(offset,length):
        if not length: return
        if parts and set(parts[-1])=={'offset','length'} and parts[-1]['offset']+parts[-1]['length']==offset:
            parts[-1]['length']+=length
        else: parts.append({'offset':offset,'length':length})

    def data_start(blob,entry):
        if blob[entry.header_offset:entry.header_offset+4]!=b'PK\x03\x04':
            raise ValueError('Invalid ZIP entry header')
        a,b=struct.unpack_from('<HH',blob,entry.header_offset+26)
        return entry.header_offset+30+a+b

    def delta(source,target,base_offset):
        width=32
        index={}
        for i in range(0,len(source)-width+1,width):
            key=source[i:i+width]
            positions=index.setdefault(key,[])
            if len(positions)<4: positions.append(i)
        position=0
        pending=bytearray()
        while position<len(target):
            candidates=index.get(target[position:position+width],[]) if position+width<=len(target) else []
            best_offset,best_length=0,0
            for candidate in candidates:
                length=width
                limit=min(len(source)-candidate,len(target)-position)
                while length+4096<=limit and source[candidate+length:candidate+length+4096]==target[position+length:position+length+4096]:
                    length+=4096
                while length<limit and source[candidate+length]==target[position+length]:
                    length+=1
                if length>best_length: best_offset,best_length=candidate,length
            if best_length:
                literal(bytes(pending));pending.clear()
                copy(base_offset+best_offset,best_length)
                position+=best_length
            else:
                pending.append(target[position]);position+=1
        literal(bytes(pending))

    cursor=0
    with zipfile.ZipFile(unsigned_path) as source,zipfile.ZipFile(signed_path) as dest:
        entries={e.filename:e for e in source.infolist()}
        if len(entries)!=len(source.infolist()) or len(dest.namelist())!=len(set(dest.namelist())):
            raise ValueError('Duplicate ZIP entries')
        for entry in sorted(dest.infolist(),key=lambda e:e.header_offset):
            start=data_start(signed,entry)
            if start<cursor: raise ValueError('Overlapping ZIP entries')
            literal(signed[cursor:start])
            payload=signed[start:start+entry.compress_size]
            if entry.filename in entries:
                before=entries[entry.filename]
                original_start=data_start(unsigned,before)
                original_payload=unsigned[original_start:original_start+before.compress_size]
                if original_payload==payload: copy(original_start,len(payload))
                else: delta(original_payload,payload,original_start)
            else: literal(payload)
            cursor=start+entry.compress_size
    literal(signed[cursor:])
    record={'schema':SCHEMA,'compilation':{'builder':original['builder'],'apk_sha256':sha256(unsigned),
            'manifest_sha256':sha256(original_bytes)},'signed_manifest':target,'segments':parts}
    if apply_record(unsigned,original_bytes,record)!=signed:
        raise ValueError('Preview reconstruction did not reproduce the exact APK')
    return record


def verify_apk(apk,sdk,manifest):
    tools=sdk/'build-tools/35.0.1'
    if apk.stat().st_size!=manifest['bytes'] or sha256(apk.read_bytes())!=manifest['sha256']:
        raise ValueError('Preview APK bytes do not match the verified artifact')
    signature=command([tools/'apksigner','verify','--verbose','--print-certs',apk])
    fingerprint=re.search(r'certificate SHA-256 digest: ([0-9a-fA-F]+)',signature)
    if not fingerprint or fingerprint.group(1).lower()!=CERTIFICATE:
        raise ValueError('Preview signing certificate mismatch')
    command([tools/'zipalign','-c','-P','16','4',apk])
    metadata=command([tools/'aapt','dump','badging',apk])
    package=re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",metadata)
    if not package or package.groups()!=(PACKAGE,str(manifest['version_code']),manifest['version_name']):
        raise ValueError('Preview package or version mismatch')
    if "native-code: 'arm64-v8a'" not in metadata or f"application-label:'{LABEL}'" not in metadata:
        raise ValueError('Preview architecture or label mismatch')
    permissions=set(re.findall(r"^uses-permission(?:-[0-9]+)?: name='([^']+)'",metadata,re.M))
    if permissions!={'android.permission.VIBRATE'} or "sdkVersion:'24'" not in metadata or "targetSdkVersion:'36'" not in metadata:
        raise ValueError('Preview offline manifest policy changed')
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None: raise ValueError('Preview ZIP integrity failed')
        libraries=[n for n in archive.namelist() if n.endswith('.so')]
        if not libraries: raise ValueError('Preview contains no native library')
        for name in libraries:
            data=archive.read(name)
            if data[:6]!=b'\x7fELF\x02\x01': raise ValueError('Unsupported native library format')
            offset=struct.unpack_from('<Q',data,32)[0]
            size,count=struct.unpack_from('<HH',data,54)
            loads=[struct.unpack_from('<IIQQQQQQ',data,offset+i*size) for i in range(count)]
            loads=[s for s in loads if s[0]==1]
            if not loads or not all(s[7]>=16384 and s[2]%16384==s[3]%16384 for s in loads):
                raise ValueError('Preview native library has invalid 16 KB alignment')
    apk.with_suffix('.manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (apk.parent/'APK-SIGNATURE.txt').write_text(signature)
    (apk.parent/'SHA256SUMS').write_text(manifest['sha256']+'  '+apk.name+'\n')


def publish(record,output_directory,sdk):
    if os.environ.get('GITHUB_REPOSITORY')!=REPOSITORY:
        raise ValueError('Preview publication requires the canonical repository')
    manifest=validate_record(record)
    tag=f"v{manifest['version_name']}-art-preview-build{manifest['version_code']}"
    output_directory.mkdir(parents=True,exist_ok=True)
    apk=output_directory/manifest['apk']
    existing=subprocess.run(['gh','release','view',tag,'--repo',REPOSITORY],capture_output=True,text=True,timeout=60)
    if existing.returncode==0:
        command(['gh','release','download',tag,'--repo',REPOSITORY,'--pattern',apk.name,'--dir',output_directory])
        verify_apk(apk,sdk,manifest)
        print(command(['gh','release','view',tag,'--repo',REPOSITORY,'--json','url,assets']))
        return
    if 'release not found' not in existing.stderr.lower():
        raise RuntimeError('Could not inspect preview release')
    builder=record['compilation']['builder'];run_id=str(builder['run_id'])
    run=json.loads(command(['gh','api',f'repos/{REPOSITORY}/actions/runs/{run_id}']))
    if run['conclusion']!='success' or run['head_sha']!=manifest['git_commit'] or run['path']!='.github/workflows/android-compile.yml':
        raise ValueError('Preview compilation base was not verified successful')
    with tempfile.TemporaryDirectory(prefix='mystic-art-preview-') as temporary:
        directory=Path(temporary)
        command(['gh','run','download',run_id,'--repo',REPOSITORY,'--name','mystic-run-unsigned-android','--dir',directory/'input'])
        paths=list((directory/'input').rglob('apk-manifest.json'))
        if len(paths)!=1: raise ValueError('Expected one compilation manifest')
        original=json.loads(paths[0].read_text())
        if Path(original['apk']).name!=original['apk']: raise ValueError('Unsafe compilation filename')
        unsigned=(paths[0].parent/original['apk']).read_bytes()
        apk.write_bytes(apply_record(unsigned,paths[0].read_bytes(),record))
        verify_apk(apk,sdk,manifest)
        notes=directory/'release-notes.md'
        notes.write_text('Installable Mystic Run Art Preview with the refined Knight, Gargoyle, Witch and free scenery.\n\n'
            'Download the APK below and open it on your Android phone. It installs as Mystic Run Art Preview alongside the existing game and keeps separate saves.\n\n'
            f"Exact verified APK SHA-256: {manifest['sha256']}\n\nSource: {manifest['git_commit']}\n\n"
            'This APK was exported and signed locally with the preserved preview key. This workflow reconstructs those exact bytes against the successful GitHub compilation base, then verifies the signature, package, permissions and alignment before publication. No private key is stored in GitHub.\n\n'
            'Physical-phone testing remains open. This preview is separate from the owner-signed update and is not a Google Play release.\n')
        assets=[apk,apk.with_suffix('.manifest.json'),output_directory/'APK-SIGNATURE.txt',output_directory/'SHA256SUMS']
        command(['gh','release','create',tag,'--repo',REPOSITORY,'--target',manifest['git_commit'],
                 '--title',f"Mystic Run Art Preview {manifest['version_name']} - build {manifest['version_code']}",
                 '--notes-file',notes,'--prerelease','--latest=false',*assets])
        command(['gh','release','download',tag,'--repo',REPOSITORY,'--pattern',apk.name,'--dir',directory/'published'])
        if sha256((directory/'published'/apk.name).read_bytes())!=manifest['sha256']:
            raise ValueError('Published GitHub preview download differs from verified APK')
        print(command(['gh','release','view',tag,'--repo',REPOSITORY,'--json','url,assets']))
