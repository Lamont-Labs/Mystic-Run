#!/usr/bin/env python3
"""Copy only approved public artwork into the isolated Unity project."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "experiments/unity-runner/Assets/MysticRun/Art"
SOURCES = [
    "assets/characters/concept-sprites/knight_rear.png",
    "assets/environment/living-world/castle_stone.jpg",
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records = []
    for name in SOURCES:
        source = ROOT / name
        dest = OUT / source.name
        shutil.copyfile(source, dest)
        assert source.read_bytes() == dest.read_bytes()
        records.append({"source": name, "copy": str(dest.relative_to(ROOT)),
                        "sha256": hashlib.sha256(source.read_bytes()).hexdigest()})
    (OUT / "provenance.json").write_text(json.dumps({
        "rights": "Noncommercial game use only; original artwork remains untouched",
        "purpose": "Static evaluation reference, not a completed animated Knight",
        "files": records,
    }, indent=2) + "\n")
    print("Copied and hash-verified two existing approved art files; no generated art or credentials")


if __name__ == "__main__":
    main()
