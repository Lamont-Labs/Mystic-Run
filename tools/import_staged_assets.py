#!/usr/bin/env python3
"""Safely import the verified 52-model staging ZIP into a MysticRun checkout.

Usage: python3 tools/import_staged_assets.py /path/to/MysticRun_Batch01_52_Verified_Assets_Staging.zip
Does not alter active character models or any existing files.
"""
import argparse
import json
import os
from pathlib import Path, PurePosixPath
import tempfile
from zipfile import ZipFile

from verify_staged_assets import verify

PREFIX = "assets/replacement_batch01/"
ALLOWED_META = ("provenance/",)
MAX_BYTES = 100_000_000

def import_archive(archive: Path, root: Path) -> int:
    verify(str(archive))  # Fail closed on every GLB hash, inventory and required license.
    with ZipFile(archive) as z:
        receipt = json.loads(z.read("STAGING_RECEIPT.json"))
        model_names = {row["path"] for row in receipt["files"]}
        files = []
        for name in z.namelist():
            if name.endswith("/"):
                continue
            if name in model_names or name.startswith(PREFIX + "licenses/") or name.startswith(ALLOWED_META):
                pp = PurePosixPath(name)
                if pp.is_absolute() or ".." in pp.parts:
                    raise ValueError("Unsafe path: " + name)
                data = z.read(name)
                if len(data) > MAX_BYTES:
                    raise ValueError("Oversized entry: " + name)
                target = root.joinpath(*pp.parts)
                if target.exists() and target.read_bytes() != data:
                    raise FileExistsError("Refusing to overwrite existing asset: " + name)
                files.append((target, data))
        if len([1 for target, _ in files if target.suffix == ".glb"]) != 52:
            raise ValueError("Incomplete model staging")
        # Check every target before writing any files.
        for target, data in files:
            if target.exists() and target.read_bytes() != data:
                raise FileExistsError("Target changed during validation: " + str(target))
        for target, data in files:
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                continue
            with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as tmp:
                tmp.write(data)
                temp = Path(tmp.name)
            try:
                os.replace(temp, target)
            finally:
                temp.unlink(missing_ok=True)
    print("STAGED 52 verified GLBs and associated licenses/provenance; no active gameplay replacement")
    return 52

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("archive", type=Path)
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    a = p.parse_args()
    import_archive(a.archive, a.root.resolve())
