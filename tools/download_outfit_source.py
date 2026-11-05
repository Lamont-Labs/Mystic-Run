#!/usr/bin/env python3
"""Download the pinned public FREE Standard outfit archive without an account."""
from __future__ import annotations
import argparse
import hashlib
import http.cookiejar
import json
import os
from pathlib import Path
import re
import urllib.parse
import urllib.request

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'build/asset_sources/quaternius-fantasy-standard.zip')
    args=parser.parse_args()
    lock=json.loads((ROOT/'art/asset_batch_01/quaternius-outfits.lock.json').read_text())['archive']
    if args.output.is_file() and hashlib.sha256(args.output.read_bytes()).hexdigest()==lock['sha256']:
        print(args.output.resolve());return
    args.output.parent.mkdir(parents=True,exist_ok=True)
    opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    url=lock['source_page']
    with opener.open(url,timeout=30) as stream:page=stream.read().decode()
    token=re.search(r'name="csrf_token" value="([^"]+)"',page)
    if not token:raise RuntimeError('Publisher download form changed; review it before retrying')
    request=urllib.request.Request(url+'/file/'+str(lock['upload_id']),data=urllib.parse.urlencode({'csrf_token':token.group(1)}).encode(),headers={'Referer':url,'X-Requested-With':'XMLHttpRequest'})
    with opener.open(request,timeout=30) as stream:response=json.loads(stream.read())
    if response.get('errors') or not response.get('url'):raise RuntimeError('Publisher refused the free download: '+str(response.get('errors',[])))
    pending=args.output.with_suffix('.partial');digest=hashlib.sha256();size=0
    try:
        with opener.open(response['url'],timeout=60) as source,pending.open('wb') as output:
            while block:=source.read(1024*1024):
                size+=len(block)
                if size>lock['bytes']:raise ValueError('Archive exceeds pinned size')
                output.write(block);digest.update(block)
        if size!=lock['bytes'] or digest.hexdigest()!=lock['sha256']:raise ValueError('Archive hash or size differs from the reviewed edition')
        os.replace(pending,args.output)
    except BaseException:
        pending.unlink(missing_ok=True);raise
    print(args.output.resolve())


if __name__=='__main__':main()
