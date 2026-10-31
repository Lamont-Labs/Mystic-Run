#!/usr/bin/env python3
"""Run real Godot checks and bind the result to the tested source hashes."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from bootstrap_godot import engine_version, install


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--cache", type=Path, default=Path.home() / ".cache" / "lamont-runner-godot")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    binary = args.godot.resolve() if args.godot else install(args.cache)
    version = engine_version(binary)
    report_path = root / "tests" / "results.json"
    report_path.unlink(missing_ok=True)
    result = subprocess.run(
        [str(binary), "--headless", "--path", str(root), "--script", "res://tests/run_tests.gd"],
        text=True, capture_output=True, timeout=120,
    )
    print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    if result.returncode != 0 or not report_path.is_file():
        return result.returncode or 1
    report = json.loads(report_path.read_text())
    if report["failed"] != 0 or report["checks"] <= 0:
        return 1
    files = [root / "project.godot"]
    for directory, pattern in (("core", "*.gd"), ("tests", "*.gd"), ("content", "*.json"), ("tools", "*.py")):
        files.extend(sorted((root / directory).glob(pattern)))
    hashes = {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in files}
    evidence = {
        "verified_at_utc": datetime.now(timezone.utc).isoformat(),
        "engine_version": version,
        "scope": "Headless gameplay-core assertions and static handoff-route contracts",
        "checks": report["checks"], "failures": report["failed"],
        "source_sha256": hashes,
        "android_apk_built_by_this_check": False, "physical_device_tested_by_this_check": False,
        "visual_quality_reviewed_by_this_check": False,
        "limitations": [
            "This core-only check does not execute the playable 3D scene or review its art.",
            "Range, lane, line-of-sight and collider behavior require the separate scene checks.",
            "Route metadata checks do not prove physical traversability or camera readability.",
            "This core records a seed; the separate game scene generates encounters using its own seeded stream.",
            "The core uses fixed 14 m/s progression; speed ramps are a later integration task.",
        ],
    }
    output = root / "docs" / "verification_actual.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(evidence, indent=2) + "\n")
    print(f"Verified {report['checks']} checks; evidence written to docs/verification_actual.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
