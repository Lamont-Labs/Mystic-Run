# MR-ART-004 — Original reference recovery and evidence gate

Date: 2026-11-05
Status: PARTIAL — candidate concept sheet recovered; exact handoff image and in-engine screenshot bytes still unverified
Change scope: documentation only

## New retrieval result

A persistent Library image named `MysticRun fantasy heroes concept sheet.png` was recovered and visually inspected. Its SHA-256 is `07e7541d8d5a91d1733186930d5d4ed759400021c8af3391f068ade217f01e71`. This image depicts the three heroes in front and rear views, including a youthful blue-armored Knight with swept red plume, star shield, red star cape, curved sword and exposed face.

**It is NOT byte-identical to the exact original handoff reference** `references/01-character-concept.png`, whose recorded SHA-256 is `17fcdda5ef60f3997ca11293238eae47d528bc3edb675c584f866e4ef27242ec`. Therefore treat the recovered image as a *visually relevant candidate*, not the authoritative exact attachment. Additional later Library concept sheets were also found, but were not assumed to supersede the original owner-selected sheet.

## Verified existing Knight implementation (source documentation)

`docs/AUTHORED_KNIGHT_FIRST_PASS.md` confirms:
- The existing Knight has an open rounded helmet, sculpted face, opaque eyes/irises, eyelids, brows, hair and coral plume.
- Curved layered chest armor, pauldrons, tassets, bracers, gloves, greaves and toe plates.
- Sword, shaped shield and cape star.
- One main material surface with vertex-painted skin, hair, enamel, metal, cloth, leather and eyes.
- 24,348 main-mesh triangles; 14,538 source vertices; 65 bones; Blink and PlumeSway morphs.
- Existing CC0 rig and locomotion; authored Knight-specific animations and bitmap painted texture atlas remain unfinished.
- Reproducible authoring entrypoint: `tools/build_knight_asset.py`, Blender 4.3.2.
- Actual Godot preview paths: `docs/previews/knight-first-pass/front.png`, `rear.png`, `gameplay.png`, `home.png`, `slide.png`.

These statements are sourced from saved development documentation, not fresh mesh measurements or a new Godot execution.

## Provisional discrepancy matrix — NOT a completed image-to-image audit

| Feature | Design requirement | Current source-supported status | Evidence needed |
| --- | --- | --- | --- |
| Face | Youthful expressive face, visible dark hair | Face, hair, brows, eyelids present; refinement documented as open | Original reference and actual Godot face crop |
| Helmet/plume | Blue open helmet, swept red plume | Open rounded helmet and coral plume present; transitions unfinished | Side/front/rear render comparison |
| Armor | Curved blue enamel, prominent gold edges, articulated limbs | Layered armor and enamel/metal paint regions present | Color/shape close-ups and silhouette |
| Shield | Tall blue-and-gold star heraldry | Shaped shield present; exact ornament fidelity unverified | Front/three-quarter detail |
| Sword | Broad silver ornamented curved blade | Closed-volume sword present; exact profile unverified | Equipment comparison |
| Cape | Red embroidered star cape, distinctive rear view | Cape star corrected; no final painted atlas | Rear view and animated cape |
| Rendering | Style B textured hand-drawn comic | Vertex gradients; painted atlas and comic treatment unfinished | Godot Compatibility material prototype |
| Motion | Expressive Knight run/jump/slide | Retargeted rig works; bespoke Knight motion unfinished | Actual motion captures and Android profiling |

## Next action — exact evidence recovery, then one refinement

1. Recover the exact handoff ZIP containing `references/01-character-concept.png` and verify its recorded SHA-256.
2. Obtain viewable bytes for the existing `docs/previews/knight-first-pass/` captures and inspect them beside the exact reference.
3. Complete the visual discrepancy matrix with observed differences, not source assumptions.
4. Select and implement one smallest demonstrable correction through the deterministic Knight generator, with unchanged gameplay and rollback.
5. Validate with Blender export, Godot import and gameplay checks before saving the art branch.

No 3D mesh, shader, runtime, signing key, Android package or release was modified by this checkpoint.


## Update — exact original handoff ZIP supplied and verified

The owner supplied `MysticRun_Next_Chat_Handoff_2026-11-05.zip`. Its exact `references/01-character-concept.png` was extracted and SHA-256 verified against the recorded authoritative digest:

- `01-character-concept.png`: `17fcdda5ef60f3997ca11293238eae47d528bc3edb675c584f866e4ef27242ec` — **MATCH**.
- `02-comic-rendering.jpg`: `0690c9d44595fd7052c8a475bf1cfb07d46aa26765db8747ff730e947b972c65` — **MATCH**.
- `03-illustrated-city.jpg`: `491f74ace5261a3e30c36e4894456518d39a18433f3bb836245d1a10a173f7bd` — **MATCH**.

The exact character reference was visually inspected. It shows:
- Knight: youthful clean-shaven brown-haired face, open silver/blue helmet with swept coral-red plume, bright blue enamel and gold armor, cyan four-point chest star, blue shield with prominent gold star, curved silver sword with gold guard, short coral-red cape with a large gold star on back, brown belt and pouches.
- Gargoyle: broad grey-green stone body with carved stone facets, curled horns, large pointed ears, violet membrane wings, gold cuff, purple waist sash with star, digitigrade clawed feet.
- Witch: expressive silver-haired woman with long rear braid, oversized pointed purple hat, layered purple/gold coat, belt and potion, crescent-and-crystal staff, dark leggings and boots.

The separate comic reference is an energetic ink-heavy stylized action illustration; use its *rendering techniques only*, not its characters or modern setting. The illustrated-city reference is a screenshot of a different urban 3D website; use it only as an optional readability/rendering example, not MysticRun lore.

**Reference recovery gate is now satisfied.** The remaining blocker for a defensible model-change decision is inspection of actual Godot Knight captures (`docs/previews/knight-first-pass/front.png`, `rear.png`, `gameplay.png`) side-by-side with the verified original. No visual comparison against those runtime images has been performed in this update. No 3D model, shader or APK changed.
