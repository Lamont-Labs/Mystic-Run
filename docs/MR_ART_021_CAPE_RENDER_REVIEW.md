# MR-ART-021 — Knight cape rendered acceptance review

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed source commit: `22a58e80da2a5d39bdc9c81d1a26dfc3f06a2b21`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Verification
- Godot cape visual workflow: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42099255009 — success
- Gameplay core workflow: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42099254664 — success
- Actual Godot capture artifact: `knight-cape-visual-review`, artifact ID `13449631481`, 1,715,374 bytes
- Artifact contains thirteen 540×960 PNGs, a SHA256 manifest, and render logs
- Reviewed captures: `knight-front.png`, `knight-rear.png`, `knight-side.png`, `knight-run.png`, `knight-jump.png`, `knight-slide.png`, `knight-attack.png`, `knight-celebrate.png`

## Visual assessment
- Static rear view: red cape, yellow five-point star and gold edge remain legible.
- Static side view: cape trails from shoulders, forming a more curved silhouette than the prior flat triangular plane.
- Running: cloth deforms into angular, repeated peaks; resembles an accordion/fan rather than smooth weighted fabric.
- Jumping: cape extends outward and gold edging remains visible, but the silhouette has sharp cloth corners.
- Sliding: cloth rises in repeated triangular spikes, creating an obvious unnatural fold artifact.
- No obvious detached cape or missing star in the static rear view. Still images cannot prove freedom from clipping over the full animation timeline.
- Knight remains stylized with simplified facial features, helmet, shoulders and boots; full concept-sheet fidelity is not achieved.

## Gate
Keep the revised cape source on the development branch. **Do not claim owner visual approval, promote the art branch, or publish an APK.** This is desktop software-render evidence, not a physical Android test.

## Next scoped task
MR-ART-022: diagnose and smooth the high-frequency cape deformation responsible for the accordion silhouette in running and sliding; capture repeatable Godot poses and compare before/after. Preserve five-point star, gold edge, Knight rig attachment, and reduced-motion behavior.
