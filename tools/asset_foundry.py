#!/usr/bin/env python3
"""Import pinned free assets and verify the runtime 3D asset inventory offline.

Usage: asset_foundry.py import-kaykit [--source-dir /path/to/publisher/repo]
       asset_foundry.py verify [--report /path/to/report.json]

The checked-in lock selects only the publisher's free CC0 edition. Verification
does not infer legal rights: the reviewed license evidence is kept with each
entry, and byte/path/dependency checks detect omissions and accidental changes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import struct
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
LOCK = "assets/sources/kaykit-medieval.lock.json"
REGISTRY = "assets/asset_registry.json"
DESTINATION = "assets/environment/kaykit"
ALLOWED_LICENSES = {"CC0-1.0", "LicenseRef-LamontLabs-Original"}
RUNTIME_EXTENSIONS = {".gltf", ".glb", ".bin", ".res", ".png", ".jpg", ".webp"}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def local_path(root: Path, name: str) -> Path:
    """No traversal, URLs, absolute paths, Windows paths or escaping symlinks."""
    if not isinstance(name, str) or not name or "\\" in name or ":" in name or "%" in name:
        raise ValueError(f"Invalid local asset path: {name!r}")
    relative = PurePosixPath(name)
    if relative.is_absolute() or any(p in {"..", "."} for p in name.split("/")):
        raise ValueError(f"Unsafe local asset path: {name!r}")
    path = root / relative
    if not path.resolve().is_relative_to(root.resolve()):
        raise ValueError(f"Asset escapes its root: {name!r}")
    return path


def file_record(path: Path, root: Path = ROOT) -> dict:
    data = path.read_bytes()
    return {"path": path.relative_to(root).as_posix(), "sha256": digest(data), "bytes": len(data)}


def gltf_document(path: Path) -> dict:
    data = path.read_bytes()
    if path.suffix == ".glb":
        if len(data) < 20 or data[:4] != b"glTF":
            raise ValueError(f"Invalid GLB header: {path.name}")
        version, total, size, kind = struct.unpack_from("<4I", data, 4)
        if version != 2 or total != len(data) or kind != 0x4E4F534A or 20 + size > total:
            raise ValueError(f"Invalid GLB structure: {path.name}")
        return json.loads(data[20:20 + size])
    return json.loads(data)


def verify(root: Path = ROOT) -> dict:
    registry = json.loads((root / REGISTRY).read_text())
    if registry.get("schema") != 1 or not registry.get("assets"):
        raise ValueError("Unsupported or empty asset registry")
    covered: set[str] = set()
    identifiers: set[str] = set()
    checks = 0
    total_bytes = 0
    entries = registry["assets"]
    for entry in entries:
        identifier = entry["id"]
        if identifier in identifiers:
            raise ValueError(f"Duplicate asset id: {identifier}")
        identifiers.add(identifier)
        if entry["license"] not in ALLOWED_LICENSES or entry["cost_usd"] != 0:
            raise ValueError(f"Unapproved license or price: {identifier}")
        if entry["license"] == "LicenseRef-LamontLabs-Original" and entry.get("publisher") != "Lamont Labs":
            raise ValueError("Original-art license cannot be assigned to an external publisher")
        for right in ("commercial_use", "modification", "game_distribution"):
            if entry.get(right) is not True:
                raise ValueError(f"Missing reviewed {right} permission: {identifier}")
        if not entry.get("publisher") or not entry.get("sources") or not entry.get("modifications"):
            raise ValueError(f"Incomplete provenance: {identifier}")
        if not entry.get("files"):
            raise ValueError(f"No runtime files: {identifier}")
        for record in [entry["license_evidence"], *entry["files"]]:
            path = local_path(root, record["path"])
            if not path.is_file() or not re.fullmatch(r"[0-9a-f]{64}", record["sha256"]):
                raise ValueError(f"Missing file or invalid digest: {record['path']}")
            data = path.read_bytes()
            if digest(data) != record["sha256"] or len(data) != record["bytes"]:
                raise ValueError(f"Asset bytes changed: {record['path']}")
            checks += 1
        for record in entry["files"]:
            if record["path"] in covered:
                raise ValueError(f"Runtime file assigned twice: {record['path']}")
            covered.add(record["path"])
            total_bytes += record["bytes"]
    for entry in entries:
        for dependency in entry.get("derived_from", []):
            if dependency not in identifiers or dependency == entry["id"]:
                raise ValueError(f"Unknown or self-referential source: {dependency}")
    # A graph walk rejects dependency cycles, including indirect ones.
    by_id = {entry["id"]: entry for entry in entries}
    def visit(identifier: str, stack: set[str]) -> None:
        if identifier in stack:
            raise ValueError(f"Cyclic provenance: {identifier}")
        for parent in by_id[identifier].get("derived_from", []):
            visit(parent, stack | {identifier})
    for identifier in identifiers:
        visit(identifier, set())
    for directory in registry["coverage_roots"]:
        folder = local_path(root, directory)
        for path in sorted(folder.rglob("*")):
            if path.suffix.lower() in RUNTIME_EXTENSIONS and path.is_file():
                name = path.relative_to(root).as_posix()
                if name not in covered:
                    raise ValueError(f"Unregistered runtime asset: {name}")
                if path.suffix in {".gltf", ".glb"}:
                    document = gltf_document(path)
                    for block in document.get("buffers", []) + document.get("images", []):
                        if "uri" in block:
                            dependency = local_path(path.parent, block["uri"])
                            dependency_name = dependency.relative_to(root).as_posix()
                            if not dependency.is_file() or dependency_name not in covered:
                                raise ValueError(f"Unregistered glTF dependency: {dependency_name}")
                            if "byteLength" in block and dependency.stat().st_size != block["byteLength"]:
                                raise ValueError(f"Invalid glTF buffer length: {dependency_name}")
                            checks += 1
    return {"status": "PASS", "schema": 1, "assets": len(entries), "runtime_files": len(covered),
            "checks": checks, "source_bytes": total_bytes,
            "scope": "Reviewed rights metadata, local license evidence, exact hashes, complete 3D inventory and glTF dependencies; no store or device certification"}


def import_kaykit(source_dir: Path | None, root: Path = ROOT) -> dict:
    lock = json.loads((root / LOCK).read_text())
    if lock["license"] != "CC0-1.0" or lock["edition"] != "Free Standard":
        raise ValueError("Only the reviewed free CC0 edition is admitted")
    if not re.fullmatch(r"[0-9a-f]{40}", lock["commit"]):
        raise ValueError("A full immutable source commit is required")
    source: dict[str, bytes] = {}
    # Download and verify the complete selection before writing any runtime file.
    for record in lock["source_files"]:
        relative = record["path"]
        local_path(Path("/source-root"), relative)
        if source_dir:
            data = local_path(source_dir, relative).read_bytes()
        else:
            url = f"https://raw.githubusercontent.com/{lock['repository']}/{lock['commit']}/{relative}"
            with urllib.request.urlopen(url, timeout=30) as response:
                data = response.read(8 * 1024 * 1024 + 1)
        if digest(data) != record["sha256"] or len(data) != record["bytes"]:
            raise ValueError(f"Publisher source differs from lock: {relative}")
        source[relative] = data
    pending: dict[str, bytes] = {}
    for model in lock["models"]:
        document = json.loads(source[model["source"]])
        parent = PurePosixPath(model["source"]).parent
        for buffer in document["buffers"]:
            original = str(parent / buffer["uri"])
            buffer["uri"] = model["name"] + ".bin"
            pending[f"{DESTINATION}/{buffer['uri']}"] = source[original]
        for image in document.get("images", []):
            image["uri"] = "hexagons_medieval.png"
        for material in document.get("materials", []):
            material.setdefault("pbrMetallicRoughness", {}).update({"metallicFactor": 0, "roughnessFactor": .86})
        document.setdefault("asset", {})["extras"] = {"publisher": lock["publisher"], "license": lock["license"], "source_commit": lock["commit"], "modifications": "Flat resource paths; matte material response; scene assembly and motion supplied separately by MysticRun."}
        pending[f"{DESTINATION}/{model['name']}.gltf"] = (json.dumps(document, separators=(",", ":")) + "\n").encode()
    pending[f"{DESTINATION}/hexagons_medieval.png"] = source[lock["texture"]]
    pending["assets/licenses/kaykit-medieval-CC0.txt"] = source[lock["license_file"]]
    for name, data in pending.items():
        path = local_path(root, name)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    registry = json.loads((root / REGISTRY).read_text())
    entry = next(e for e in registry["assets"] if e["id"] == "kaykit-medieval-districts")
    entry["files"] = [file_record(root / n, root) for n in sorted(pending) if n.startswith(DESTINATION + "/")]
    entry["license_evidence"] = file_record(root / "assets/licenses/kaykit-medieval-CC0.txt", root)
    (root / REGISTRY).write_text(json.dumps(registry, indent=2) + "\n")
    return verify(root)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("import-kaykit").add_argument("--source-dir", type=Path)
    commands.add_parser("verify").add_argument("--report", type=Path)
    args = parser.parse_args()
    result = import_kaykit(args.source_dir) if args.command == "import-kaykit" else verify()
    if getattr(args, "report", None):
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
