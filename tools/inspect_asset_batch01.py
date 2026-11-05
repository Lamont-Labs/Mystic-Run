#!/usr/bin/env python3
"""Inspect actual GLB payloads and produce the standalone asset review catalog."""
from __future__ import annotations
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parents[1]
BATCH=ROOT/'art/asset_batch_01'
WIDTH={5120:1,5121:1,5122:2,5123:2,5125:4,5126:4}
FORMAT={5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'}
SIZE={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}


def inspect(path):
    raw=path.read_bytes()
    assert len(raw)>20 and raw[:4]==b'glTF'
    version,total=struct.unpack_from('<II',raw,4)
    assert version==2 and total==len(raw)
    offset=12;chunks={}
    while offset<len(raw):
        length,kind=struct.unpack_from('<II',raw,offset)
        assert length%4==0 and offset+8+length<=len(raw)
        chunks[kind]=raw[offset+8:offset+8+length];offset+=8+length
    doc=json.loads(chunks[0x4e4f534a]);binary=chunks[0x004e4942]
    assert len(doc['buffers'])==1 and 'uri' not in doc['buffers'][0]
    assert len(binary)-3<=doc['buffers'][0]['byteLength']<=len(binary)
    for view in doc.get('bufferViews',[]):
        assert view.get('buffer',0)==0
        assert view.get('byteOffset',0)>=0
        assert view.get('byteOffset',0)+view['byteLength']<=len(binary)
    def accessor(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
        assert 'sparse' not in a,'Review sparse accessors explicitly'
        width=WIDTH[a['componentType']]*SIZE[a['type']]
        stride=v.get('byteStride',width)
        assert stride>=width and a['count']>0
        start=v.get('byteOffset',0)+a.get('byteOffset',0)
        assert a.get('byteOffset',0)+(a['count']-1)*stride+width<=v['byteLength']
        fmt='<'+FORMAT[a['componentType']]*SIZE[a['type']]
        return [struct.unpack_from(fmt,binary,start+i*stride) for i in range(a['count'])]
    triangles=vertices=surfaces=0
    for model_index,model in enumerate(doc['meshes']):
        copies=sum(1 for node in doc['nodes'] if node.get('mesh')==model_index)
        assert copies>0,'Unreferenced mesh in candidate'
        for primitive in model['primitives']:
            assert primitive.get('mode',4)==4,'Only triangle meshes are admitted'
            attributes=primitive['attributes'];p=accessor(attributes['POSITION'])
            assert all(math.isfinite(v) for row in p for v in row)
            assert 'NORMAL' in attributes
            normals=accessor(attributes['NORMAL'])
            assert len(normals)==len(p) and all(math.isfinite(v) for row in normals for v in row)
            if 'indices' in primitive:
                indices=accessor(primitive['indices'])
                assert all(0<=row[0]<len(p) for row in indices)
                count=len(indices)
            else:count=len(p)
            assert count%3==0
            if 'material' in primitive:assert primitive['material']<len(doc.get('materials',[]))
            for attr in ['COLOR_0','TEXCOORD_0','TEXCOORD_1']:
                if attr in attributes:
                    values=accessor(attributes[attr])
                    assert len(values)==len(p) and all(math.isfinite(v) for row in values for v in row)
            triangles+=(count//3)*copies;vertices+=len(p);surfaces+=copies
    for skin in doc.get('skins',[]):
        assert skin['joints'] and all(0<=j<len(doc['nodes']) for j in skin['joints'])
        if 'inverseBindMatrices' in skin:
            matrices=accessor(skin['inverseBindMatrices'])
            assert len(matrices)==len(skin['joints']) and all(math.isfinite(v) for row in matrices for v in row)
    textures=[]
    for image in doc.get('images',[]):
        assert 'uri' not in image,'GLB candidates must contain all texture bytes'
        view=doc['bufferViews'][image['bufferView']]
        start=view.get('byteOffset',0);data=binary[start:start+view['byteLength']]
        assert data.startswith(b'\x89PNG\r\n\x1a\n')
        w,h=struct.unpack_from('>II',data,16)
        assert max(w,h)<=2048
        textures.append({'width':w,'height':h,'sha256':hashlib.sha256(data).hexdigest()})
    assert triangles>0
    return {'triangles':triangles,'exported_vertices':vertices,'mesh_instances':sum('mesh' in n for n in doc['nodes']),'surfaces':surfaces,'materials':len(doc.get('materials',[])),
        'textures':textures,'rigged':bool(doc.get('skins')),'animations':len(doc.get('animations',[])),
        'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def main():
    originals=json.loads((BATCH/'original-assets.json').read_text())['assets']
    locked=json.loads((BATCH/'kaykit-dungeon.lock.json').read_text())['files']
    asset_list=[]
    for item in originals:
        path=BATCH/item['path'];actual=inspect(path)
        assert actual['sha256']==item['sha256'] and actual['triangles']==item['triangles']
        asset_list.append({'id':item['id'],'label':item['id'].replace('_',' ').title(),'path':str(path.relative_to(BATCH/'review')),
            'publisher':'Lamont Labs','license':item['license'],'purpose':item['purpose'],'status':'REVIEW_ONLY',**actual})
    for item in locked:
        if not item['path'].endswith('.glb'):continue
        path=BATCH/'review/assets/kaykit'/item['path'];actual=inspect(path)
        assert actual['sha256']==item['sha256'] and actual['bytes']==item['bytes']
        asset_list.append({'id':'kaykit_'+path.stem,'label':path.stem.replace('_',' ').title(),'path':str(path.relative_to(BATCH/'review')),
            'publisher':'Kay Lousberg / KayKit','license':'CC0-1.0','status':'REVIEW_ONLY',**actual})
    outfit_file=BATCH/'outfit-assets.json'
    outfit_items=json.loads(outfit_file.read_text())['assets'] if outfit_file.is_file() else []
    for item in outfit_items:
        path=BATCH/'review'/item['path'];actual=inspect(path)
        assert actual['sha256']==item['sha256'] and actual['triangles']==item['triangles']
        assert actual['rigged']
        asset_list.append({**item,**actual})
    result={'schema':1,'status':'PASS','scope':'Exact file hashes, GLB 2 structure, embedded dependencies, finite attributes, index bounds, skin joint and inverse-bind bounds, PNG dimensions and source correspondence',
        'models':len(asset_list),'original_models':len(originals),'downloaded_models':len(asset_list)-len(originals),
        'outfit_assemblies':sum(a['kind']=='outfit_assembly' for a in outfit_items),
        'modular_clothing_parts':sum(a['kind']=='modular_clothing_part' for a in outfit_items),
        'bytes':sum(a['bytes'] for a in asset_list),'runtime_integration':False,'assets':asset_list}
    (BATCH/'review/asset_catalog.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='assets'}))


if __name__=='__main__':main()
