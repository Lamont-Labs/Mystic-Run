#!/usr/bin/env python3
"""Acquire the exact reviewed free KayKit selection; never download at runtime."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import urllib.request

ROOT=Path(__file__).resolve().parents[1]
BATCH=ROOT/'art/asset_batch_01'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cached-source',type=Path)
    args=parser.parse_args()
    lock=json.loads((BATCH/'kaykit-dungeon.lock.json').read_text())
    assert lock['license']=='CC0-1.0'
    assert len(lock['commit'])==40
    pending=[]
    for item in lock['files']:
        path=PurePosixPath(item['source_path'])
        assert not path.is_absolute() and '..' not in path.parts
        if args.cached_source:
            data=(args.cached_source/item['path']).read_bytes()
        else:
            url=f"https://raw.githubusercontent.com/{lock['repository']}/{lock['commit']}/{path}"
            with urllib.request.urlopen(url,timeout=40) as stream:data=stream.read(4*1024*1024)
        if len(data)!=item['bytes'] or hashlib.sha256(data).hexdigest()!=item['sha256']:
            raise ValueError('Source mismatch: '+str(path))
        output=BATCH/('review/assets/kaykit' if item['path'].endswith('.glb') else 'licenses/kaykit-dungeon')/item['path']
        pending.append((output,data))
    # Commit the selection only after every exact source payload passes.
    for output,data in pending:
        output.parent.mkdir(parents=True,exist_ok=True);output.write_bytes(data)
    print(json.dumps({'status':'PASS','files':len(pending),'models':sum(p.suffix=='.glb' for p,_ in pending),'bytes':sum(len(d) for _,d in pending)}))


if __name__=='__main__':main()
