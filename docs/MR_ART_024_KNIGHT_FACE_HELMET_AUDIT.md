# MR-ART-024 — Knight helmet and face source audit

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Status: **AUDIT COMPLETE / MODEL CHANGE NOT AUTHORIZED BY THIS REPORT**
Reference asset: `references/01-character-concept.png`
Primary generator: `tools/build_knight_asset.py`
Previous gate: `docs/MR_ART_023_CAPE_BEFORE_AFTER.md`

## Evidence boundary
This audit inspected the checked-in procedural mesh generator and the previously reviewed actual Godot render captures. The concept-sheet image's pixels were **not** independently retrieved in this task; therefore this report does not assert exact color, shape, or ornament matches to that image. The owner's established direction is detailed, playful, hand-drawn fantasy rather than blocky primitives or heavily anime styling. Before changing the mesh, inspect the actual concept image side by side with front/side/rear Godot captures.

## Actual implementation
- The face is a skinned loft with chin, jaw, cheek, temple and forehead rings, using Head weighting. Its face outline spans approximately y=1.525 to 1.874 game units.
- Separate ellipsoids create eyes, iris, pupils, nose and ear forms. Mouth and eyelid details are made from narrow tubes/ellipsoids.
- Helmet shell uses an 8-ring, 28-segment procedural surface with a cosine-faceted 12-part cross-section. Front opening is controlled by `helmet_bottom(a)`; crown taper and radii are defined by `helmet_shell(a,y)`.
- Additional geometry includes gold lower rim, silver visor plate, gold visor tube, blue cheek guards, gold edge piping, gemmed temple accents, silver crown rails and a red swept plume.
- A single skinned mesh preserves the imported Quaternius armature; six morph targets are Blink, PlumeSway, Smile, Focus, Surprised and Hurt.
- Generator intentionally keeps the mesh below the existing 25,000-triangle mobile QA ceiling; the previously reviewed rebuild reported 23,810 triangles and 65 bones. These are previous evidence values, not a fresh rebuild measurement.

## Priority visual defects (based on actual reviewed Godot frames and code)
1. **Facial readability at chase distance** — fine tube eyelids, lips and brows have widths of only a few thousandths of a game unit; expression detail risks vanishing in gameplay. Increase shape-language clarity rather than simply adding polygons.
2. **Helmet silhouette** — the faceted dome and thin rim read as a small, simplified cap, despite substantial ornamental microgeometry. Prefer a strong, recognizable silhouette with purposeful brow and cheek-guard mass.
3. **Face-to-helmet integration** — eye and cheek geometry is built independently of the visor and guard aperture. Validate eye visibility and occlusion in front, three-quarter and chase poses.
4. **Plume and crown proportions** — swept red plume is generated as a curved tube; inspect its outline and junction against the concept before resizing.
5. **Material readability** — current surfaces rely on vertex-color tint and narrow tubes; the hand-drawn aesthetic may need broader painted value regions and controlled highlights, not indiscriminate triangle increases.

## Next implementation order
1. Acquire/inspect exact concept-sheet pixels and record front/three-quarter silhouette targets.
2. Change only helmet opening, brow, cheek guards and face proportions in `tools/build_knight_asset.py`; preserve current skeleton, six morphs and cape.
3. Rebuild with pinned Blender; run `tools/verify_knight_glb.py` and Godot rig/expression checks. Do not exceed the established mobile triangle budget.
4. Capture actual Godot front/side/rear and gameplay frames; compare before/after, including expression visibility and visor clipping.
5. Mark TECHNICAL PASS / VISUAL HOLD until the owner accepts concept fidelity. Do not merge or release APK on an audit alone.

## Decision
This is a source-grounded geometry audit and implementation sequence, **not** a completed model redesign. No character model, gameplay behavior, or release artifact changed in MR-ART-024.
