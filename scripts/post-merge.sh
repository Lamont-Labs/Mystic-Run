#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Keep this project's dependencies isolated from Replit's managed .pythonlibs.
uv sync --locked --no-install-project

# Fail the merge setup if the reviewed runtime asset inventory is inconsistent.
uv run --locked python tools/asset_foundry.py verify
