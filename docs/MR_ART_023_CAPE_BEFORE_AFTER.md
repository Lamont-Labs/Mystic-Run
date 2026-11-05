# MR-ART-023 — Knight cape before/after visual review

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Reviewed commit: `bdc7f9170f4a2f4a19e56ee6c4088029da399d82`
Decision: **CAPE REFINEMENT ACCEPTED / FULL CHARACTER VISUAL HOLD**

## Verified runs
- Cape render workflow: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42100489289 — success
- Gameplay core workflow: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42100489377 — success
- After artifact: `knight-cape-visual-review`, ID `13450365415`, 1,693,272 bytes
- Before artifact: `knight-cape-visual-review`, ID `13449631481`, 1,715,374 bytes
- Both artifacts contain actual Godot rendered character poses, not concept images.

## Side-by-side observations
- Rear: red cape, gold border and five-point star remain visible; the revised lower edge is less irregular.
- Side: cape retains a trailing drape with reduced sharp zigzag edges.
- Running: the previous repeated angular peaks are replaced by a broader, more coherent trailing silhouette.
- Jump: cape remains behind the torso; no obvious new detachment in this still.
- Slide: the prominent accordion/fan peaks are reduced; cape appears flatter and less chaotic.
- Attack: no obvious regression in cape placement from the sampled still.
- Limits: static snapshots cannot prove full animation collision clearance or physical Android performance; the cape can appear stiff and flat.

## Scope decision
Accept MR-ART-022 as a measurable visual improvement over MR-ART-021. This does not authorize merge to release or APK publication. The Knight's face, helmet, armor and overall stylization still fall short of the concept-sheet fidelity target.

## Next scoped task
MR-ART-024: inspect the Knight helmet/face against `references/01-character-concept.png` and produce a source-grounded geometry improvement plan before modifying the model. Preserve rig, morphs, triangle cap and mobile performance.
