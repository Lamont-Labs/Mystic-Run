#!/usr/bin/env python3
"""Install the checksum-pinned Linux editor used by the core checks."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import urllib.request
import zipfile

VERSION = "4.7.2"
ASSET = f"Godot_v{VERSION}-stable_linux.x86_64.zip"
BINARY = ASSET.removesuffix(".zip")
ARCHIVE_SHA512 = (
    "9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467"
    "edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"
)
URL = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/{ASSET}"


def engine_version(binary: Path) -> str:
    result = subprocess.run([str(binary), "--version"], check=True, capture_output=True, text=True)
    version = result.stdout.strip()
    if not version.startswith(f"{VERSION}.stable"):
        raise RuntimeError(f"Expected Godot {VERSION} stable; received {version}")
    return version


def install(cache: Path) -> Path:
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / ASSET
    if not archive.is_file() or hashlib.sha512(archive.read_bytes()).hexdigest() != ARCHIVE_SHA512:
        pending = archive.with_suffix(".download")
        with urllib.request.urlopen(URL, timeout=60) as source, pending.open("wb") as output:
            while block := source.read(1024 * 1024):
                output.write(block)
        if hashlib.sha512(pending.read_bytes()).hexdigest() != ARCHIVE_SHA512:
            pending.unlink(missing_ok=True)
            raise RuntimeError("Official editor archive did not match the pinned SHA-512 digest")
        os.replace(pending, archive)
    binary = cache / BINARY
    # Extract the expected member only, avoiding archive-path traversal.
    with zipfile.ZipFile(archive) as bundle, bundle.open(BINARY) as source, binary.open("wb") as output:
        while block := source.read(1024 * 1024):
            output.write(block)
    binary.chmod(0o755)
    engine_version(binary)
    return binary.resolve()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache", type=Path, default=Path.home() / ".cache" / "lamont-runner-godot")
    args = parser.parse_args()
    print(install(args.cache))


if __name__ == "__main__":
    main()
