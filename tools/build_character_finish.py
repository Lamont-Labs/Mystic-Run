#!/usr/bin/env python3
"""Bake the original, periodic four-channel character detail texture offline.

R: painted stone, G: cloth weave, B: leather grain, A: directional hair.
No external art, random seed, account, image model or authoring dependency.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SIZE = 256


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))


def bake() -> bytes:
    def noise(u: float, v: float, period: int) -> float:
        x, y = u * period, v * period
        ix, iy = math.floor(x), math.floor(y)
        fx, fy = x - ix, y - iy
        fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        def sample(a: int, b: int) -> float:
            h = ((a % period) * 374761393 + (b % period) * 668265263 + period * 1274126177) & 0xffffffff
            h = ((h ^ (h >> 13)) * 1274126177) & 0xffffffff
            return ((h ^ (h >> 16)) & 65535) / 32767.5 - 1
        lo = sample(ix, iy) * (1 - fx) + sample(ix + 1, iy) * fx
        hi = sample(ix, iy + 1) * (1 - fx) + sample(ix + 1, iy + 1) * fx
        return lo * (1 - fy) + hi * fy
    raw = bytearray()
    tau = math.tau
    for y in range(SIZE):
        raw.append(0)
        v = y / SIZE
        for x in range(SIZE):
            u = x / SIZE
            cloud = .65 * noise(u, v, 7) + .35 * noise(u, v, 17)
            fleck = noise(u, v, 53)
            weave = math.sin(tau * u * 32) * math.sin(tau * v * 32)
            grain = .65 * noise(u, v, 29) + .35 * fleck
            strands = .65 * math.sin(tau * u * 23 + .28 * math.sin(tau * v * 2)) + .35 * math.sin(tau * u * 47)
            for value in (.65 * cloud + .35 * fleck, weave, grain, strands):
                raw.append(max(0, min(255, round(127.5 + value * 116))))
    header = struct.pack('>IIBBBBB', SIZE, SIZE, 8, 6, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + png_chunk(b'IHDR', header) + png_chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + png_chunk(b'IEND', b'')


def main() -> None:
    path = ROOT / 'assets/characters/finish-detail.png'
    data = bake()
    path.write_bytes(data)
    registry_path = ROOT / 'assets/asset_registry.json'
    registry = json.loads(registry_path.read_text())
    identifier = 'mysticrun-character-finish-detail'
    entry = next((item for item in registry['assets'] if item['id'] == identifier), None)
    if entry is None:
        entry = {'id': identifier}
        registry['assets'].append(entry)
    license_path = ROOT / 'assets/licenses/lamont-labs-original.txt'
    entry.update({
        'publisher': 'Lamont Labs', 'license': 'LicenseRef-LamontLabs-Original',
        'cost_usd': 0, 'commercial_use': True, 'modification': True,
        'game_distribution': True, 'attribution_required': False,
        'sources': ['tools/build_character_finish.py'],
        'modifications': ['Original periodic scalar detail texture; channels encode stone, cloth, leather and hair; sampled as linear data.'],
        'license_evidence': {'path': license_path.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(license_path.read_bytes()).hexdigest(), 'bytes': license_path.stat().st_size},
        'files': [{'path': path.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}],
    })
    registry_path.write_text(json.dumps(registry, indent=2) + '\n')
    print(json.dumps({'path': str(path), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(), 'dimensions': [SIZE, SIZE], 'external_assets': False}))


if __name__ == '__main__':
    main()
