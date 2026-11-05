# MR-ART-037 — Knight chest rebuild verification

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed source commit: `c0c09e96f185347ec129f93333c726cc967d61bd`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Verified runs
- Knight asset rebuild: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42113712001 — success
- Gameplay regression: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42113711985 — success
- Rebuild artifact `knight-rebuild-review` ID `13454793991`, ZIP size 2,754,296 bytes.

## Rebuilt asset evidence
- Structural verifier: `GLB_STRUCTURAL_PASS`
- SHA-256: `1a4f073ecced4fbbf33c74792c9579ac4dca207e2c994354b36b8096486c51f4`
- GLB bytes: 1,682,912
- Triangles: **24,350** / 25,000 (650 headroom; +208 versus previous 24,142).
- One mesh, one skin, six morphs: Blink, PlumeSway, Smile, Focus, Surprised, Hurt.
- Actual Godot captures inspected: front, side, rear, run, neutral expression and surprised expression.
- No catastrophic chest panel clipping apparent in these sampled stills. Chest and pauldrons still appear rounded and simplified relative to approved concept.

## Desktop gameplay evidence
- Benchmark: 100 frames at 30 fps; 62.224 m; zero damage; zero handoffs; selected Knight preserved.
- This is not a physical Android test, sustained-performance proof or full animation clearance test.

## Visual acceptance
Chest layering improved in source and renders, but the model still falls substantially short of the approved hand-drawn fantasy character sheet. Preserve **VISUAL HOLD**. Avoid further incremental tube/plate additions near the 25k cap; prioritize reauthoring existing large forms and materials, plus realistic gameplay camera review.

## Next task
MR-ART-038: plan and implement a replacement-first armor material and silhouette pass, using concept-to-render comparison and preserving existing rig, six morphs and mobile constraints. No release or APK promotion on this evidence.
