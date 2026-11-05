#!/usr/bin/env python3
"""Convert the pinned free outfit archive to rigged, textured 1024px GLBs.

blender --background --python tools/prepare_outfit_assets.py -- --archive /path/to/Standard.zip

The archive must match the recorded SHA-256. Existing bodies must be removed
under these clothes; the publisher supplies outfit geometry, not a finished
MysticRun Knight, Gargoyle or Witch. Source skeletons and weights are retained.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import sys
from zipfile import ZipFile

import bpy

ROOT=Path(__file__).resolve().parents[1]
BATCH=ROOT/'art/asset_batch_01'
sys.path.insert(0,str(ROOT/'tools'))
from inspect_asset_batch01 import inspect


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive',type=Path,required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    lock=json.loads((BATCH/'quaternius-outfits.lock.json').read_text())
    actual=hashlib.sha256(args.archive.read_bytes()).hexdigest()
    if actual!=lock['archive']['sha256']:raise ValueError('Archive differs from the pinned Standard edition')
    source=BATCH/'source/quaternius-outfits'
    with ZipFile(args.archive) as archive:
        pending=[]
        for item in lock['files']:
            data=archive.read(item['archive_path'])
            if len(data)!=item['bytes'] or hashlib.sha256(data).hexdigest()!=item['sha256']:
                raise ValueError('Source mismatch: '+item['archive_path'])
            pending.append((BATCH/item['path'],data))
        for path,data in pending:path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    cache=BATCH/'.texture-cache';cache.mkdir(exist_ok=True)
    target=BATCH/'review/assets/outfits';target.mkdir(parents=True,exist_ok=True)
    records=[]
    for item in lock['files']:
        if not item['path'].endswith('.gltf'):continue
        for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
        for image in list(bpy.data.images):
            if image.type=='IMAGE':bpy.data.images.remove(image)
        bpy.ops.import_scene.gltf(filepath=str(BATCH/item['path']))
        rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
        assert len(rigs)==1
        assembly='/Outfits/' in item['archive_path']
        texture_limit=1024 if assembly else 512
        textures=[]
        for image in list(bpy.data.images):
            if image.type!='IMAGE':continue
            old=list(image.size)
            if min(old)<1:raise ValueError('Cannot decode source texture: '+image.name)
            if max(old)>texture_limit:
                factor=texture_limit/max(old);image.scale(round(old[0]*factor),round(old[1]*factor))
            image.filepath_raw=str(cache/(Path(image.filepath).stem+'.png'));image.file_format='PNG';image.save()
            # glTF imports may retain the original packed 4K payload. Drop it
            # and reload the saved 1K PNG before exporting self-contained GLB.
            if image.packed_file:image.unpack(method='REMOVE')
            image.reload();image.pack()
            textures.append({'name':image.name,'source_dimensions':old,'output_dimensions':list(image.size),'color_space':image.colorspace_settings.name})
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        tri=0
        for mesh in meshes:mesh.data.calc_loop_triangles();tri+=len(mesh.data.loop_triangles)
        assert tri<=40000
        name=Path(item['path']).stem;path=target/(name+'.glb')
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False)
        raw=path.read_bytes()
        metrics=inspect(path)
        records.append({'id':'outfit_'+name.lower(),'label':name.replace('_',' ') + (' Outfit' if assembly else ' Part'),
            'path':path.relative_to(BATCH/'review').as_posix(),'source_path':item['archive_path'],'source_sha256':item['sha256'],
            'publisher':'Quaternius','license':'CC0-1.0','kind':'outfit_assembly' if assembly else 'modular_clothing_part',
            'triangles':metrics['triangles'],'rigged':True,'bones':len(rigs[0].data.bones),'meshes':metrics['mesh_instances'],'sha256':hashlib.sha256(raw).hexdigest(),
            'bytes':len(raw),'textures':textures,'status':'REVIEW_ONLY',
            'modifications':[f'PBR maps downsampled to at most {texture_limit}px','Self-contained GLB packaging','Original rig and skin weights retained','No gameplay animation retargeting or hero identity replacement']})
        print('OUTFIT',name,tri,len(raw),flush=True)
    # The exporter can leave sidecar PNGs even for a fully embedded GLB. Every
    # output was inspected above; remove only this generator's named sidecars.
    for item in lock['files']:
        if item['path'].endswith('.gltf'):
            for image_path in target.glob(Path(item['path']).stem+'_T_*.png'):
                image_path.unlink()
                image_path.with_suffix('.png.import').unlink(missing_ok=True)
    result={'schema':1,'archive_sha256':actual,'blender':bpy.app.version_string,'assemblies':sum(r['kind']=='outfit_assembly' for r in records),'modular_parts':sum(r['kind']=='modular_clothing_part' for r in records),'assets':records}
    (BATCH/'outfit-assets.json').write_text(json.dumps(result,indent=2)+'\n')
    print('OUTFITS COMPLETE',result['assemblies'],result['modular_parts'],flush=True)


if __name__=='__main__':main()
