#!/usr/bin/env python3
"""Read only the official Android APK entries from the matching export ZIP."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

URL = 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
EXPECTED = {
    'android_debug.apk':'59e0073f0fa59f552684a861d8f4266b0b34b488a140d6657eac7dd70d1a0a0d',
    'android_release.apk':'6d1bb2cfa126a1b1c87e064a35b3cbd181bef0ec784dec1efd1d64dffa8be6cb',
    'version.txt':'38885c88f75abbc797a1db7559719800279a00cfb9fa8b2e2868a7f6f84bad2e',
}


class RemoteZip(io.RawIOBase):
    def __init__(self):
        with urllib.request.urlopen(urllib.request.Request(URL, method='HEAD'), timeout=40) as r:
            self.size = int(r.headers['Content-Length'])
            self.url = r.geturl()
        self.position = 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        return self.position

    def tell(self):
        return self.position

    def read(self, count=-1):
        if count < 0:
            count = self.size - self.position
        count = min(count, self.size - self.position)
        if count <= 0:
            return b''
        request = urllib.request.Request(self.url, headers={'Range': f'bytes={self.position}-{self.position + count - 1}'})
        with urllib.request.urlopen(request, timeout=90) as r:
            if r.status != 206:
                raise RuntimeError('Template host did not support bounded range extraction')
            data = r.read()
        if len(data) != count:
            raise RuntimeError('Unexpected template range length')
        self.position += len(data)
        return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--destination', type=Path, default=Path.home()/'.local/share/godot/export_templates/4.7.2.stable')
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    results = []
    with zipfile.ZipFile(RemoteZip()) as bundle:
        for name in ('android_debug.apk', 'android_release.apk', 'version.txt'):
            member = 'templates/' + name
            data = bundle.read(member)
            if hashlib.sha256(data).hexdigest() != EXPECTED[name]:
                raise RuntimeError('Official template entry differs from the pinned digest: '+name)
            (args.destination/name).write_bytes(data)
            results.append({'file': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    print(json.dumps({'source': URL, 'crc_checked': True, 'files': results}, indent=2))


if __name__ == '__main__':
    main()
