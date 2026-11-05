# MR-ART-035 — Optimized plume rebuild verification

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed commit: `d2817ecc47b6fad5aad249607f3e6e75fcf1a2d0`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Workflow evidence
- Knight rebuild https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42112787682 — success
- Gameplay core https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42112787900 — success
- Artifact `knight-rebuild-review`, ID `13455163885`, ZIP size 2,715,516 bytes.

## Actual artifact metrics
- Structural status: `GLB_STRUCTURAL_PASS`
- GLB SHA256: `a5b6380ad0f9376509c8170ef8be429b170659226a11cf2252557af76310468c`
- GLB bytes: 1,669,268
- Triangles: **24,142** versus previous **24,754**, a saving of **612** triangles (2.47%).
- Remaining 25k budget: **858 triangles**, versus previous 246.
- One mesh, one skin, six morphs: Blink, PlumeSway, Smile, Focus, Surprised, Hurt.

## Render and gameplay review
Reviewed actual Godot front, side, rear, run, neutral and surprised captures. The layered plume is present in sampled views; no obvious severe breakage or detachment. The silhouette remains stiff and the overall character is still less detailed than the user-approved concept. This is not a full-animation or Android performance test.

The benchmark records 100 frames at 30 fps, 62.224 m, zero damage and zero handoffs, with Knight selection preserved.

## Decision and next task
Optimization is technically accepted; visual hold remains. The 858-triangle headroom is still insufficient for unrestricted additional geometry. Next, MR-ART-036 should prioritize replacement of existing rounded armor surfaces and richer painted/material definition rather than adding large volumes of geometry. Preserve skeleton, morphs, mobile budget and gameplay behavior. Do not release APK on this evidence.
