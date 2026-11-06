#!/usr/bin/env python3
"""Import the 57-asset MysticRun Batch01 handoff with complete hash validation.

Supports both the standalone Batch01 ZIP and the nested next-chat handoff ZIP.
All GLB files must match their recorded SHA-256 values before any file is written.
The import stages assets; it does not replace active character models.
"""
import argparse
from pathlib import Path

from import_handoff_assets import extract


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    count = extract(args.archive, args.root)
    if count != 57:
        raise RuntimeError("Incomplete handoff import: expected 57 verified GLBs")
    print("Batch01: 57 checksum-verified assets staged; no gameplay replacement performed.")


if __name__ == "__main__":
    main()
