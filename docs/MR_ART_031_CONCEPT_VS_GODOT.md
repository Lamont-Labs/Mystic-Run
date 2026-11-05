# MR-ART-031 — Knight concept-to-Godot comparison

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Decision: **VISUAL HOLD / REDESIGN REQUIRED**

## Compared sources
- User-approved `1000048042.png`, 1536 × 1024, showing the Knight front three-quarter and rear.
- Actual Godot screenshots from MR-ART-028 `review.jpg`, including `knight-front` and `knight-rear`.
- A four-panel comparison image was generated in the conversation at `/mnt/data/mr-art-031/concept-vs-godot.jpg`. **This comparison JPG and source concept PNG are not yet GitHub-tracked.**

## Observed differences
| Region | Approved concept | Current Godot render | Severity |
| --- | --- | --- | --- |
| Helmet | Angular, layered steel with pronounced front openings and warm metallic edge work | Rounded, shallow helmet with simplified visor and thin trim | High |
| Plume | Large flowing red tuft with multiple swept strands | Thin single curved tube silhouette | High |
| Face | Expressive brow, layered hair, lively smile and stylized anatomy | Small facial details, more generic face shape | High |
| Chest | Sculpted overlapping breastplate and dimensional turquoise star | Rounded blue chest volume and simple star | High |
| Shoulders | Distinct overlapping gold-rimmed armor pieces | Smooth rounded blue shoulder shells | High |
| Gauntlets/boots | Layered articulated forms with raised trim | Smooth cylindrical limb pieces and plain boot geometry | High |
| Sword/shield | Curved, sculpted blade and dimensional decorated shield | Simplified blade and shield with approximate motifs | Medium-high |
| Cape rear | Naturally draped red cloth with broad gold trim and star | Flat planar cloth silhouette with star; lower detail | High |

## Prioritized production direction
**Do not continue micro-adjustments.** First redesign the Knight's **upper-body visual language**: helmet with swept multi-strand plume, layered breastplate, and articulated pauldrons. These dominate front/three-quarter gameplay readability. Follow with lower armor and cape in separate tasks.

The approved concept is an illustration and cannot be made 'exact' by polygon changes alone. Geometry, painted textures/materials, lighting and animation presentation must be judged together.

## Gates
- Preserve existing rig, six morph targets and gameplay behavior.
- Keep mobile triangle and draw-call budgets verified, not assumed.
- Capture matched front/rear/three-quarter and chase-camera frames after each meaningful redesign.
- Do not mark visual pass, merge or release APK without visual acceptance and technical evidence.

## Scope
MR-ART-031 delivered visual comparison and implementation priorities. No model source, game behavior or release artifact changed.
