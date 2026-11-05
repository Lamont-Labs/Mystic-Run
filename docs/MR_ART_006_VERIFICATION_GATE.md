# MR-ART-006 — Verification boundary and build requirement

Date: 2026-11-05
Source commit: `fbf0ae7462b6b59c36a15608c8f7b4283eab73e1`
Status: SOURCE PATCH SAVED; REGENERATED ASSET NOT VERIFIED

## What changed

`tools/build_knight_asset.py` changed the lower open-face helmet contour and the Knight's plume spline/radii. The source still tags plume vertices with `plume` and assigns them to `Head`; the `PlumeSway` shape-key code remains present.

## Verification gap found

`.github/workflows/core-checks.yml` does **not** invoke Blender or `tools/build_knight_asset.py`. It checks in-repository GLB imports and game behavior. A green gameplay-core run on this source commit therefore does not demonstrate that the new Python geometry was exported into `assets/characters/knight/knight.glb`.

The branch's last known actual Godot captures predate this patch. No new Blender export, glTF structural audit, in-engine front/rear/chase-camera capture, or Android performance measurement has been established by this task.

## Acceptance gate for MR-ART-006

1. Rebuild in a controlled checkout using Blender 4.3.2:
   `blender --background --python-exit-code 1 --python tools/build_knight_asset.py`
2. Check the newly exported `assets/characters/knight/knight.glb` and provenance, including SHA-256, bounds, finite vertices, skin weights, six shape-key names, material surfaces, and preserved bone bindings.
3. Import the new GLB in Godot 4.7.2 Compatibility; run the Knight rig/expression and complete core suites.
4. Capture actual matching front/rear/chase-camera views. Compare with exact approved original and previous Godot screenshots; inspect face opening, swept plume, helmet collision/clipping, and plume morph deformation.
5. If verification passes, commit the generated asset and reproducible evidence to the art branch. If it fails, fix or revert the prototype without changing the published APK.
6. Separately evaluate phone performance before any release.

## Current disposition

Source prototype is **unverified**, not production-approved. No main-branch merge, Android signing change or APK publication authorized.
