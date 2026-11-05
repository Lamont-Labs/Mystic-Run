# MR-ART-010 — Actual regenerated Knight visual acceptance

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Result: **TECHNICAL PASS / VISUAL HOLD**

## Reproducible source
- GitHub Actions run: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42088242210
- Source commit: `c8803a0f529fdf405dc0482f2220578266c8c7d1`
- Uploaded review artifact: `knight-rebuild-review` (artifact ID `13443682344`)
- Rebuilt runtime candidate: `assets/characters/knight/knight.glb` in artifact, not committed or released
- Rendered with the actual Godot game/stage scripts; 13 stage PNGs and one chase-camera PNG
- Original identity reference: `references/01-character-concept.png`, SHA-256 `17fcdda5ef60f3997ca11293238eae47d528bc3edb675c584f866e4ef27242ec`
- Prior baseline: `docs/previews/knight-first-pass/`

## Review of actual images
The reviewer inspected the generated front, rear, side, face-neutral, and gameplay frames extracted from the successful workflow artifact.

| Gate | Result | Observation |
| --- | --- | --- |
| Blender export, provenance and Godot rig/expression tests | PASS | Rebuild workflow completed successfully |
| Swept-back plume silhouette | PARTIAL | Side view clearly has an extended rear-swept crest, but front view still reads as a short hooked curl |
| Open-faced helmet | PARTIAL | Face remains exposed, but helmet dome is still spherical and simplified |
| Concept-sheet character fidelity | FAIL | Large blue eyes, broad spherical shoulders, flat armor surfaces and simplified shield remain conspicuous |
| Cape/chase-camera readability | FAIL | Broad triangular cape dominates the rear; player remains visually small in the actual portrait gameplay frame |
| Plume visual clipping | NOT PROVEN | Still captures do not establish all-frame clearance |
| Mobile performance | NOT TESTED | Desktop software rendering is not an Android benchmark |

## Decision
**Do not promote this candidate GLB into the runtime asset or publish an APK.** Technical checks pass, but the Knight remains substantially below the approved original concept. The plume is more swept in profile, yet its front silhouette remains hooked. The new shape alone does not close the gap.

## Next narrowly scoped art task — MR-ART-011
Refine **helmet dome/opening and crest shape only** in `tools/build_knight_asset.py`, retaining existing 65-bone rig, six morph targets, material/skin contracts and all other equipment. Prefer a lower, sculpted steel-blue helmet with a more clearly rear-swept red crest readable in front, rear and chase views. Rebuild, re-render, compare, and accept only with actual screenshots. Keep this art branch isolated from release.

This report records a visual HOLD, not owner approval.
