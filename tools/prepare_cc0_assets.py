#!/usr/bin/env python3
"""Prepare only used geometry from Quaternius's free Standard downloads.

Requires the three publisher ZIPs in --pack-dir; see docs/ART_DIRECTION.md.
After importing, run Godot --headless --script tools/bake_motion.gd and remove
UAL1/UAL2_Standard.glb. The committed runner-motion.res is the baked result.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

PACKS={
 'universal-base-characters-standard.zip':'fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40',
 'universal-animation-library-standard.zip':'cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724',
 'universal-animation-library-2-standard.zip':'4008ea208a604773a2b2177d965f0f5d3195498b5bf838c3f5785d68e95f2a68',
}
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--pack-dir',type=Path,required=True)
 args=parser.parse_args()
 root=Path(__file__).resolve().parents[1]/'assets/models/quaternius'
 for filename,digest in PACKS.items():
  if hashlib.sha256((args.pack_dir/filename).read_bytes()).hexdigest()!=digest: raise SystemExit('Archive hash differs: '+filename)
 with ZipFile(args.pack_dir/'universal-base-characters-standard.zip') as archive:
  members=archive.namelist()
  selected=[next(n for n in members if n.endswith('Godot - UE/'+name+'.gltf')) for name in ['Superhero_Male_FullBody','Superhero_Female_FullBody']]
  selected.append(next(n for n in members if n.endswith('Origin at 0/glTF (Godot)/Hair_Long.gltf')))
  for member in selected:
   folder=root/('hair' if 'Hairstyles/' in member else 'base')
   folder.mkdir(parents=True,exist_ok=True)
   document=json.loads(archive.read(member))
   for key in ['materials','textures','images','samplers']: document.pop(key,None)
   for mesh in document['meshes']:
    for primitive in mesh['primitives']: primitive.pop('material',None)
   (folder/PurePosixPath(member).name).write_text(json.dumps(document,separators=(',',':'))+'\n')
   for buffer in document.get('buffers',[]):
    uri=PurePosixPath(buffer['uri'])
    if '..' in uri.parts or uri.is_absolute(): raise SystemExit('Unsafe buffer path')
    (folder/uri).write_bytes(archive.read(str(PurePosixPath(member).parent/uri)))
 for filename,name in [('universal-animation-library-standard.zip','UAL1_Standard'),('universal-animation-library-2-standard.zip','UAL2_Standard')]:
  with ZipFile(args.pack_dir/filename) as archive:
   member=next(n for n in archive.namelist() if n.endswith('Unreal-Godot/'+name+'.glb'))
   (root/'animations').mkdir(parents=True,exist_ok=True)
   (root/'animations'/(name+'.glb')).write_bytes(archive.read(member))
 print('Prepared geometry and animation sources. Import, then run tools/bake_motion.gd.')
if __name__=='__main__': main()
