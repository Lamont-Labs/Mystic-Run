#!/usr/bin/env python3
"""Isolated Android resource compilation + Linux engine smoke, never Android bundling.

Does not accept arbitrary Bob commands, read signing configuration, or use secrets.
Requires Java 25 on PATH (provided by the read-only GitHub Actions job).
"""
import hashlib
import json
import pathlib
import shutil
import subprocess
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "experiments/defold-build-proof"
OUT = ROOT / "generated-artifacts/defold-build-proof"
BOB_VERSION = "1.14.1"
BOB_SHA256 = "f47e0d21fee84c3c1f56adfe5feb1c328f83df9e4fe26f2616a5392b9b710b45"
BOB_URL = f"https://github.com/defold/defold/releases/download/{BOB_VERSION}/bob.jar"
MARKER = "DEFOLD_BUILD_PROOF_RUNTIME_OK"
PACKAGE = "com.lamontlabs.knightgargoylewitch.dev"


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def reject_signing_files(directory):
    """Check only the isolated scratch/output directory; never inspect real keys."""
    for path in directory.rglob("*"):
        if path.is_file() and (
            path.suffix.lower() in {".jks", ".keystore", ".p12", ".apk", ".aab"}
            or path.name.endswith(".pass.txt")
        ):
            raise RuntimeError(f"Forbidden signing/package output: {path.name}")


def run(args, log_name, cwd=None, timeout=300):
    started = time.monotonic()
    result = subprocess.run(
        args, cwd=cwd, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, timeout=timeout, check=False,
    )
    (OUT / log_name).write_text(result.stdout)
    print(result.stdout, flush=True)
    if result.returncode:
        raise RuntimeError(f"{log_name} failed with exit code {result.returncode}")
    return result.stdout, round(time.monotonic() - started, 3)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    evidence = {
        "status": "failed",
        "bob_version": BOB_VERSION,
        "bob_sha256": BOB_SHA256,
        "scope": "Android-targeted resource compilation and Linux headless runtime only",
        "android_apk_built": False,
        "android_runtime_tested": False,
        "android_update_compatibility_tested": False,
        "signing_used": False,
        "gameplay_or_visual_quality_tested": False,
    }
    try:
        reject_signing_files(OUT)
        java, _ = run(["java", "-version"], "java.log", timeout=30)
        evidence["java"] = java.strip()
        if 'version "25' not in java:
            raise RuntimeError("Pinned Bob requires Java 25; no runtime was installed automatically.")
        bob = OUT / "bob.jar"
        if not bob.exists() or digest(bob) != BOB_SHA256:
            urllib.request.urlretrieve(BOB_URL, bob)
        if digest(bob) != BOB_SHA256:
            raise RuntimeError("Bob SHA-256 mismatch")
        scratch = OUT / "project"
        scratch.mkdir(exist_ok=True)
        evidence["source_sha256"] = {}
        for relative in (
            "game.project", "input/game.input_binding", "main/main.collection",
            "main/probe.go", "main/probe.script", "main/status.label",
        ):
            source = SOURCE / relative
            destination = scratch / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
            evidence["source_sha256"][relative] = digest(source)
        if f"package = {PACKAGE}" not in (scratch / "game.project").read_text():
            raise RuntimeError("Package identity changed")
        base = ["java", "-jar", str(bob), "--root", str(scratch), "--max-cpu-threads", "2"]
        # Intentionally NO 'bundle' command for Android: Bob's Android bundler
        # creates a debug key if no keystore is supplied. Never invoke it here.
        _, evidence["android_compile_seconds"] = run(base + [
            "--platform", "armv7-android", "--architectures", "arm64-android",
            "--output", "build/android", "--archive", "build",
        ], "android-build.log")
        android = scratch / "build/android"
        required = (
            "game.projectc", "game.arcd", "game.arci", "game.dmanifest",
            "main/main.collectionc", "main/probe.scriptc", "main/status.labelc",
        )
        evidence["android_outputs"] = {}
        for relative in required:
            path = android / relative
            if not path.is_file() or not path.stat().st_size:
                raise RuntimeError(f"Missing Android compile output: {relative}")
            evidence["android_outputs"][relative] = {
                "bytes": path.stat().st_size, "sha256": digest(path),
            }
        _, evidence["linux_compile_seconds"] = run(base + [
            "--platform", "x86_64-linux", "--output", "build/linux",
            "--variant", "headless", "--archive",
            "--bundle-output", str(OUT / "linux-bundle"), "build", "bundle",
        ], "linux-build.log")
        executables = list((OUT / "linux-bundle").rglob("*.x86_64"))
        if len(executables) != 1:
            raise RuntimeError("Expected exactly one Linux headless executable")
        output, evidence["linux_smoke_seconds"] = run(
            [str(executables[0])], "linux-runtime.log",
            cwd=executables[0].parent, timeout=30,
        )
        if MARKER not in output:
            raise RuntimeError("Engine did not execute Lua smoke assertions")
        reject_signing_files(OUT)
        evidence["status"] = "passed"
    except Exception as error:
        evidence["error"] = str(error)
        raise
    finally:
        (OUT / "evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
        print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
