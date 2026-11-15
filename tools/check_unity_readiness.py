#!/usr/bin/env python3
"""Observe editor availability without reading licenses, credentials or backups."""
import argparse
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    editor = shutil.which("Unity") or shutil.which("unity-editor")
    report = {
        "editor_version_pinned": "6000.3.28f1",
        "editor_revision": "8f082d2fe476",
        "editor_on_path": editor is not None,
        "unity_hub_on_path": shutil.which("unityhub") is not None,
        "integration_search": "No Unity integration returned by catalog search",
        "status": "blocked_editor_unavailable" if editor is None else "activation_and_import_not_verified",
        "unity_import_compilation_tested": False,
        "unity_rendering_tested": False,
        "unity_physics_tested": False,
        "android_build_tested": False,
        "personal_activation": "Official documentation requires Unity Hub; CLI activation does not apply to Personal",
        "owner_action": "Make an authorized, activated Unity 6000.3 editor/build runner available; do not send passwords in chat",
        "license_contents_accessed": False,
        "signing_credentials_accessed": False,
        "sources": [
            "https://unity.com/releases/editor/whats-new/6000.3.28f1",
            "https://docs.unity.com/en-us/engine/6000.3/manual/get-started/install-and-upgrade/licenses-and-activation/license-activation-methods",
        ],
        "note": "Missing local binaries is not a claim that Unity cannot run on any other machine. No paid service or license was purchased.",
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
