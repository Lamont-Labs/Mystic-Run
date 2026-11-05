# MR-ART-033 — Layered Knight plume rebuild verification

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed source commit: `651498921d39173ae0d262e2bc06d45a7a663014`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Build and gameplay evidence
- Knight asset rebuild: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42109857162 — completed successfully
- Gameplay checks: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42109857107 — completed successfully
- Rebuild artifact: `knight-rebuild-review` ID `13452724885`, ZIP 2,731,205 bytes
- Structural verifier: `GLB_STRUCTURAL_PASS`
- GLB SHA-256: `4c544d01475ed69239310be1b318c8e7f2e4db8deb0db8febc8749e87250f2e7`
- GLB size: 1,712,676 bytes
- Triangles: **24,754 / 25,000** (246 remaining; +944 vs prior 23,810)
- Meshes: 1; skins: 1; six morph targets: Blink, PlumeSway, Smile, Focus, Surprised, Hurt.
- Desktop gameplay benchmark: 100 frames at 30 fps, 62.224 m, zero damage, zero handoffs; selected Knight preserved.

## Actual Godot visual review
Inspected front, side, rear, running and close-up facial captures from the rebuilt artifact.
- The new crest has multiple clearly visible red strands, especially in side view and close-up.
- The plume's silhouette is fuller than the previous single swept tube.
- The new strands still have rigid, pointed shapes; the reference concept shows a softer and more organic sweeping tuft.
- Helmet and armor remain simplified relative to the user-approved concept; the full character is not visually accepted.
- No physical Android profiling, full-motion collision inspection or direct pixel-exact concept match has been demonstrated.

## Engineering risk
The plume consumes 944 additional triangles, leaving **only 246 triangles** under the established 25k cap. Further high-detail geometry additions would likely exceed the budget. Future redesigns should replace/simplify existing geometry, use better silhouette allocation and painted materials rather than accumulating more tubes.

## Next task — MR-ART-034
Optimize the new plume topology and redistribute polygon budget before further character sculpting. Keep Head weighting, PlumeSway morph and six-target facial system intact. Then rerun structural, animation and render verification.

## Release gate
TECHNICAL PASS / VISUAL HOLD. Do not merge to release or publish APK solely on this task.
