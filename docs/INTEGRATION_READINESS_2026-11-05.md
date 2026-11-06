# MysticRun — whole-project integration readiness

Scope: PR #8, `art/runtime-asset-integration` → `main`. This is a **release gate**, not proof of completed integration.

## Verified committed source changes
- Camera, cape shader and motion response, Gargoyle wing control, multi-character benchmark, replacement scenery loader, and import utilities are in the development branch.
- Gameplay core and visual checks succeeded on prior development commits.
- The Gargoyle rebuild workflow committed generated `gargoyle.glb`, `PROVENANCE.json` and `assets/asset_registry.json` to the development branch at `689cc0ece`.

## Not yet integrated into release
- **Branch merge:** `main` remains behind the development branch; PR #8 is draft.
- **Replacement scenery:** `game/asset_districts.gd` has optional loaders for `assets/replacement_batch01/original/skybridge_gateway.glb` and `relic_waystone.glb`. The 57 verified GLBs in the local handoff archive are not in the repository. A passing fallback-scenery test does not prove their installation.
- **Knight and Witch generated assets:** Existing GLBs are committed. A fresh generator-to-committed-binary comparison and gameplay fidelity review remain outstanding; do not claim new geometry is integrated without a matching diff.
- **Android:** No release APK has been built from the integrated branch, and no replacement signing/install test has been completed.

## Release acceptance gates
1. Inventory every handoff asset with source, license and SHA-256; import required scenery into tracked runtime paths without overwriting characters.
2. Validate each generated character asset, provenance and registry against its authoring script.
3. Confirm `main` receives the approved source and required binary assets only after branch CI passes.
4. Build Android from merged `main` using the existing permanent signing identity; verify application ID, version code, signing certificate and install compatibility.
5. Publish a verified GitHub Release APK. Do not uninstall or modify the currently installed phone game.

This file intentionally distinguishes **implemented source**, **generated review artifact**, **committed runtime asset**, **merged release source**, and **published APK**.
