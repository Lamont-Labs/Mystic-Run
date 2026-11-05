# MR-ART-026 — Knight rebuilt helmet verification

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed source commit: `0f3cbe76f104109a99fd49e36353295b00cff55a`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Workflow evidence
- Blender asset rebuild and Godot render: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42103403223 — success
- Gameplay core: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42103402971 — success
- Rebuild artifact: `knight-rebuild-review`, artifact ID `13451790061`, ZIP size 2,671,959 bytes
- Render artifact includes front, rear, side, run, attack, jump, slide, celebrate and five facial-expression captures.

## Rebuilt GLB structure
- Structural verifier status: `GLB_STRUCTURAL_PASS`
- SHA-256: `48cdb4d13c9739313c57cf018061eb0b13a10a2fc2687cb98334f82bee41c7a1`
- Bytes: 1,639,596
- Triangles: 23,810 (below existing 25,000 budget)
- Meshes: 1; skins: 1; bones: 65; vertices: 14,255
- Six morph targets: Blink, PlumeSway, Smile, Focus, Surprised, Hurt
- Blender version: 4.3.2

## Render review
- Front: helmet brow and cheek guards are visible; no obvious catastrophic face occlusion in the sampled neutral frame.
- Side: helmet/plume silhouette renders and remains attached to the head.
- Rear: cape with gold trim and star remains visible.
- Neutral, pleased and surprised face captures are visibly distinguishable.
- Remaining quality defects: helmet still appears plain and rounded, face simplified, shoulder armor bulky, and illustrated concept-sheet fidelity unproven.
- No exact pixel-to-pixel concept-sheet comparison was conducted. No physical Android test was conducted.

## Gameplay benchmark
The attached deterministic desktop benchmark records 100 frames at 30 fps, 62.224 m, zero damage, zero handoffs, and selected character preserved. This is a sampled automation result, not an end-to-end phone acceptance test.

## Gate and next task
MR-ART-025 is **structurally and render-technically verified**. Retain overall visual HOLD. Do not promote to release or publish an APK.

MR-ART-027: inspect original reference image and actual gameplay camera framing, then prioritize broader silhouette and armor material improvements over further tiny helmet embellishments. Keep changes one subsystem at a time and verify against desktop and Android constraints.
