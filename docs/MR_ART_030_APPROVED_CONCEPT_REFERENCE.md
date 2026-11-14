# MR-ART-030 — Uploaded character concept reference analysis

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Source: user-uploaded `1000048042.png` (1536 × 1024), supplied in conversation. **Image binary not yet committed to repository.**
Decision: **APPROVED SOURCE / 2D GAMEPLAY VIEWS INTEGRATED / ACTION-POSE LIMITATION**

## Reference identity
The supplied sheet is titled **MysticRun Character Concept** and shows front three-quarter and rear views of the Knight, Gargoyle and Witch. It is the current visual source of truth for all three characters. This is a concept illustration, not a ready-to-import 3D model or production texture atlas.

## Knight — mandatory design cues
- Friendly, confident youthful face with prominent brows, visible eyes, nose and swept brown hair, framed by a steel-blue open-face helmet.
- Strong red plume projecting backward from helmet crown, with a curled, layered feather/hair-like silhouette.
- Steel-blue plate armor with gold edge bindings, layered breastplate, segmented upper arms, shaped pauldrons, articulated gauntlets, knee plates and substantial but shaped boots.
- Turquoise four-point/star-like chest emblem; star motif on the gold-edged blue shield.
- Curved steel sword with gold crossguard; sword and shield must be legible in running poses.
- Deep red cape with flowing asymmetric shape, gold hem decoration and large gold star on rear.
- Proportions: stylized heroic human, relatively large expressive head, compact but articulated torso, defined waist, full arms and legs; avoid spherical toy shoulder forms and blocky boot forms.
- Surface treatment: soft painterly highlights, sculpted curvature, warm gold metallic edges, clear layer separation; not anime cel shading.

## Gargoyle — later character gate
- Broad, muscular pale stone-green creature with prominent horns, pointed ears, mischievous toothy grin and amber eyes.
- Large purple-membrane bat wings with green/stone framework, rocklike chest and arm plates, claws, thick legs and feet.
- Purple waist wrap with gold-trimmed hanging star tab; gold wrist cuff.
- Rear view shows wing roots, back plates and waist wrap.

## Witch — later character gate
- Expressive face, large asymmetrical purple pointed hat with gold band/star and curling tip.
- Long silver braid, deep-purple tailored coat/dress with gold embroidered edging and layered pale under-skirt.
- High boots, belts, small potion bottle and satchel; crescent-topped staff holding luminous cyan crystal.
- Rear view emphasizes braid, hat, flowing embroidered hem and silhouette.

## Comparison against MR-ART-028
- **High gap:** Knight armor layering and material sculpting: procedural loft/ellipsoid surfaces appear simpler and more rounded than illustrated.
- **High gap:** Helmet/plume/face: the model's small facial details and tube-shaped plume lack the expressive, layered illustration silhouette.
- **High gap:** Sword, shield and boots: source illustration uses richer layered shapes and ornament.
- **Medium gap:** Cape has red/gold/star identity but still lacks the natural illustrated cloth folds.
- **Production constraint:** existing 65-bone rig, six morphs, mobile triangle budget and gameplay controls must remain operational.

## Priority and acceptance
1. Produce a reference-versus-Godot comparison image at matched front/rear/three-quarter scales.
2. Target a single large visual subsystem, preferably helmet/plume and upper torso layering, with measurable before/after.
3. Validate 3D rig, morphs, triangle count, gameplay and mobile performance; don't certify exact match solely from one screenshot.
4. Hold visual approval until a new build demonstrates meaningful improvement.

## Provenance and persistence
This Markdown report is a durable GitHub record of the uploaded reference and its design constraints.

## Owner confirmation and tracked source

On November 14, 2026, the owner supplied the original 1536 × 1024 concept-sheet
PNG and confirmed: **“This is exactly what the characters are supposed to
look like. They do not have to be 3D.”**

The exact, unmodified binary is tracked at
[`references/01-character-concept.png`](../references/01-character-concept.png).
SHA-256:
`07e7541d8d5a91d1733186930d5d4ed759400021c8af3391f068ade217f01e71`.
It replaces the previously missing source-image blocker. The illustration is
the approved visual authority for all three characters. A 3D implementation
is not a requirement; do not sacrifice the illustrated identity to preserve a
particular rendering technique. This approval confirms the reference, not
automatic visual acceptance of existing game models.

On November 14, 2026, the owner selected concept fidelity over 3D gameplay
rendering. The current gameplay characters use transparent front/rear cutouts
from this sheet. Existing 3D models and rigs remain preserved but hidden.
Only the supplied stance views are available, so these sprites do not provide
independent run, jump, slide, or attack poses.
