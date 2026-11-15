#!/usr/bin/env python3
"""Fail-closed orchestration for trusted-main Android releases. No key handling."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess

from android_verification import PACKAGE, PERMANENT_CERTIFICATE

REPO = "Lamont-Labs/Mystic-Run"
ROOT = Path(__file__).resolve().parents[1]
INSTALLED_BASELINE_VERSION_CODE = 2009


def gh(*args):
    return subprocess.check_output(["gh", *map(str, args)], text=True)


def api(path):
    return json.loads(gh("api", f"repos/{REPO}/{path}"))


def approved_source(branch, runs, sha):
    if not branch.get("protected") or branch["commit"]["sha"] != sha:
        raise ValueError("Only the current protected main commit can be released")
    if not any(
        run.get("head_sha") == sha
        and run.get("head_branch") == "main"
        and run.get("event") == "push"
        and run.get("conclusion") == "success"
        and run.get("path") == ".github/workflows/core-checks.yml"
        and run.get("head_repository", {}).get("full_name") == REPO
        for run in runs
    ):
        raise ValueError("No successful canonical main-push gameplay verification")


def next_version(run_number, published_codes, records):
    known = list(published_codes) + [
        record["signed_manifest"]["version_code"] for record in records
    ]
    value = max(2000 + int(run_number), INSTALLED_BASELINE_VERSION_CODE + 1, max(known, default=0) + 1)
    if not 0 < value <= 2100000000:
        raise ValueError("Android version-code limit exceeded")
    return value


def verify_baseline_update(manifest):
    """Check update eligibility against the owner-confirmed installed baseline."""
    if manifest.get("package_id") != PACKAGE:
        raise ValueError("Package differs from the installed Build 2009 baseline")
    if manifest.get("certificate_sha256") != PERMANENT_CERTIFICATE:
        raise ValueError("Certificate differs from the installed Build 2009 baseline")
    code = manifest.get("version_code")
    if type(code) is not int or not INSTALLED_BASELINE_VERSION_CODE < code <= 2100000000:
        raise ValueError("Version must increase beyond the installed Build 2009 baseline")


def releases():
    return json.loads(gh("api", "--paginate", "--slurp", f"repos/{REPO}/releases?per_page=100"))


def published_codes(pages):
    codes = []
    for page in pages:
        for release in page:
            match = re.search(r"-build(\d+)$", release["tag_name"])
            if match:
                codes.append(int(match[1]))
    return codes


def preflight():
    if os.environ.get("GITHUB_REPOSITORY") != REPO or os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise ValueError("Release workflow must execute on canonical main")
    sha = os.environ["GITHUB_SHA"]
    branch = api("branches/main")
    runs = api("actions/workflows/core-checks.yml/runs?branch=main&event=push&per_page=100")
    approved_source(branch, runs["workflow_runs"], sha)
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    if os.environ["GITHUB_EVENT_NAME"] == "workflow_run":
        source = event["workflow_run"]
        if source["head_sha"] != sha or source["conclusion"] != "success" or source["event"] != "push":
            raise ValueError("Untrusted or stale workflow completion event")
    elif os.environ["GITHUB_EVENT_NAME"] != "workflow_dispatch":
        raise ValueError("Unsupported release trigger")
    records = [json.loads(p.read_text()) for p in (ROOT / ".github/android-releases").glob("*.json")]
    code = next_version(os.environ["GITHUB_RUN_NUMBER"], published_codes(releases()), records)
    with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
        stream.write(f"version_code={code}\n")
    print(f"Verified protected main {sha}; allocated Android version code {code}")


def publish(directory, sdk):
    spec = importlib.util.spec_from_file_location("release_checks", ROOT / ".github/scripts/publish_android_release.py")
    checks = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(checks)
    manifests = list(directory.glob("*.manifest.json"))
    if len(manifests) != 1:
        raise ValueError("Expected exactly one signed APK manifest")
    manifest = json.loads(manifests[0].read_text())
    verify_baseline_update(manifest)
    sha = os.environ["GITHUB_SHA"]
    if manifest["git_commit"] != sha or str(manifest["builder"]["run_id"]) != os.environ["GITHUB_RUN_ID"]:
        raise ValueError("Signed APK provenance differs from this release run")
    if manifest.get("certificate_sha256") != checks.PERMANENT_CERTIFICATE:
        raise ValueError("Permanent signing certificate changed")
    if not all(manifest.get(flag) is True for flag in (
        "signature_verified", "signature_v2_verified", "signature_v3_verified",
        "zip_integrity_verified", "alignment_16k_verified", "native_16k_alignment_verified",
        "resource_integrity_verified", "permanent_signing_identity",
        "packaged_game_files_unchanged_by_signing",
    )):
        raise ValueError("Missing mandatory signing or integrity evidence")
    if manifest.get("requires_owner_signing") is not False or manifest.get("updates_legacy_owner_installation") is not False:
        raise ValueError("Invalid signing or legacy compatibility claim")
    apk = directory / manifest["apk"]
    if apk.name != manifest["apk"] or not apk.name.endswith(".apk"):
        raise ValueError("Invalid APK filename")
    if apk.stat().st_size != manifest["bytes"] or hashlib.sha256(apk.read_bytes()).hexdigest() != manifest["sha256"]:
        raise ValueError("APK bytes differ from signing evidence")
    checks.write_verification(apk, sdk, manifest)
    code = manifest["version_code"]
    if code <= max(published_codes(releases()), default=INSTALLED_BASELINE_VERSION_CODE):
        raise ValueError("Release version code must increase beyond every published build")
    tag = f"v{manifest['version_name']}-build{code}"
    notes = directory / "RELEASE-NOTES.txt"
    notes.write_text(
        "Verified MysticRun Android development build (arm64).\n\n"
        f"Source: {sha}\nBuild: https://github.com/{REPO}/actions/runs/{os.environ['GITHUB_RUN_ID']}\n\n"
        + checks.signing_note(manifest)
        + "\n\nPackage, signing certificate, and version were checked for update eligibility "
          "from the owner-confirmed Build 2009 baseline. No uninstall or data reset is required. "
          "Later installed builds must also have a lower version code than this release."
        + "\n\nConcept-derived character artwork: noncommercial game use only.\n"
        "No phone installation or physical-device performance test was performed.\n"
    )
    gh("release", "create", tag, "--repo", REPO, "--target", sha, "--prerelease",
       "--title", f"Mystic Run {manifest['version_name']} - Android build {code}",
       "--notes-file", notes, apk, manifests[0], directory / "APK-SIGNATURE.txt", directory / "SHA256SUMS")
    downloaded = directory / "published"
    downloaded.mkdir()
    gh("release", "download", tag, "--repo", REPO, "--pattern", apk.name, "--dir", downloaded)
    if hashlib.sha256((downloaded / apk.name).read_bytes()).hexdigest() != manifest["sha256"]:
        raise ValueError("Published APK differs from the verified signed APK")
    print(f"Verified download: https://github.com/{REPO}/releases/download/{tag}/{apk.name}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("preflight", "publish"))
    parser.add_argument("--directory", type=Path)
    parser.add_argument("--sdk", type=Path)
    args = parser.parse_args()
    if args.operation == "preflight":
        preflight()
    else:
        if not args.directory or not args.sdk:
            parser.error("publish requires --directory and --sdk")
        publish(args.directory, args.sdk)
