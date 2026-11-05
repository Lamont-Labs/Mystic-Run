# MR-ART-005 — Verified original vs actual Godot Knight

Date: 2026-11-05
Status: VISUAL COMPARISON COMPLETED / FIRST GEOMETRY REFINEMENT NOT YET IMPLEMENTED
Branch: `art/asset-upgrade-batch-01`

## Evidence reviewed

- Exact approved handoff reference `references/01-character-concept.png`, SHA-256 `17fcdda5ef60f3997ca11293238eae47d528bc3edb675c584f866e4ef27242ec`. Extracted from owner-supplied ZIP and visually inspected.
- Actual Godot 4.7.2 captures read from this branch:
  - `docs/previews/knight-first-pass/front.png` Git blob `d69e1c0efed1b35e9b0a31e3b8c6ad83288f62ac`
  - `docs/previews/knight-first-pass/rear.png` Git blob `f308f11ea365e0a52e5c75ff994fad56d110d5c7`
  - `docs/previews/knight-first-pass/gameplay.png` Git blob `d7ad6f149ed15352b3a3f40ba66227c33d096c4`
- Rendering finish: owner-selected Style B, textured hand-drawn comic fantasy. The original concept remains the design authority.

## Direct visual discrepancy matrix

| Component | Original approved sheet | Actual Godot captures | Priority |
| --- | --- | --- | --- |
| Face | Young, warm and expressive, proportionate eyes and subtle smile | Very large protruding blue eyes, pronounced grin, simplified facial anatomy | High for menus, medium during chase |
| Helmet | Sculpted open-face steel-blue helmet, dark apertures/vents, defined forehead rim | Rounded nearly spherical blue helmet, smooth uninterrupted dome | **Critical** |
| Plume | Long flowing coral-red crest swept back and outward | Short chunky upward curl | **Critical** |
| Torso | Shaped steel-blue chest plate, gold layered trim, cyan star inset | Broad smooth blue chest with gold lines and star; less segmented volume | High |
| Shoulders | Layered overlapping angular pauldrons | Large rounded blue ball-like shoulder plates | **Critical** |
| Shield | Tall tapering blue shield, gold raised border and large gold star | Small squat polygonal blue shield, simplified gold star | High |
| Sword | Broad subtly curved silver blade and shaped gold hilt | Long simple tapered straight blade | Medium |
| Cape | Short, flowing red cape with ornate hem and gold star | Long broad flat triangular cape with flat yellow star and border | **Critical** |
| Legs | Shaped articulated armor with differentiated joint areas | Cylindrical blue greaves, prominent spherical knee discs | High |
| Materials | Painterly layered metal, fabric and leather, nuanced specular response | Mostly smooth flat-color/vertex-gradient surfaces | High |
| Rear/chase silhouette | Swept plume, shoulder breaks, compact star cape and shield/sword readability | Dome helmet, chunky plume, cape covering much of back; very small runner in portrait chase view | **Critical** |

## Scope and limitation

This is a comparison of *previously committed Godot screenshots*, not a new Godot execution or phone benchmark. The screenshots confirm visual differences but do not prove source-code causes, rig constraints or final material performance. No geometry, shader, character APIs, saves, Android identity, signing, or APK changed.

## First scoped implementation task — MR-ART-006

**Helmet and plume silhouette refinement only**, because these are prominent in both front and rear and are distinguishable at chase-camera scale.

1. Inspect `tools/build_knight_asset.py` to locate existing helmet and plume generation, bone weights and `PlumeSway` morph behavior.
2. Modify only the helmet silhouette/face opening and swept-back plume, retaining the same bone/morph contract and source asset rollback.
3. Preserve the open-faced youthful Knight identity, blue/steel helmet and coral-red plume.
4. Rebuild with pinned Blender 4.3.2 and import using pinned Godot 4.7.2; verify finite geometry, skin weights, morph targets, and rig/core checks.
5. Capture actual new front, rear and chase-camera images at the same framing and compare with baseline; accept only if visually closer without animation or performance regressions.
6. Commit verified implementation on the art branch. Do not merge into main or publish an APK until release gate.

Do not change the Gargoyle, Witch, other Knight equipment, progression, UI or gameplay during MR-ART-006.
