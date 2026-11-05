# MR-ART-028 — Knight shoulder rebuild review

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed source commit: `b06bf7ba825fe3590c490f54d715f40b5ad98a6e`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Verified source evidence
- Knight asset rebuild: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42105992947 — completed successfully
- Gameplay core: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42105993056 — completed successfully
- Rebuild artifact: `knight-rebuild-review`, ID `13452790689`, ZIP size 2,673,691 bytes
- `knight-structural-report.json`: `GLB_STRUCTURAL_PASS`, 23,810 triangles, 1 mesh, 1 skin, six morph targets, 1,639,852 bytes, SHA-256 `e73a39ad02ea59026330b71a6b12c45500a8436c2ed3ca90695eef108b32f89c`.
- Preserved morphs: Blink, PlumeSway, Smile, Focus, Surprised, Hurt.
- Desktop benchmark: 100 frames, 30 fps, 62.224 m, zero damage, zero handoffs, selected character preserved.

## Actual Godot capture review
Reviewed front, side, rear, run, slide and neutral/pleased/surprised expressions from the generated artifact.
- The shoulder armor is somewhat slimmer than in the previous rebuild, but the visible difference is modest.
- Armor still reads as rounded and toy-like; chest, helmet and boots remain simplified.
- Cape, gold star, shield and red plume remain visible in the sampled captures.
- Neutral, pleased and surprised expressions remain visibly distinguishable.
- Screenshots are sampled desktop frames, not evidence of Android performance or full-motion clipping clearance.
- Exact reference-image pixel comparison was not conducted in this task.

## Acceptance
The model meets the structural and sampled desktop gameplay gates. It does not meet the intended detailed hand-drawn fantasy art direction. Retain visual HOLD and do not merge or publish an APK on this evidence alone.

## Next scoped task — MR-ART-029
Move from small dimension tweaks to a deliberate source-grounded art-direction intervention: retrieve and inspect `references/01-character-concept.png` alongside Godot gameplay renders, establish silhouette and material targets, then implement a single larger, testable visual subsystem change. Preserve the rig, six morphs, gameplay controls and mobile triangle budget.
