# MysticRun character fidelity and rendering direction

Owner correction and handoff · November 5 2026

This document records the owner's latest direction and supersedes any earlier suggestion that generic downloaded fantasy outfits could define the final Knight, Gargoyle or Witch. The current character models remain below the owner's visual target.

## Confirmed character design target

The owner explicitly wants the characters to look exactly like the supplied MysticRun character concept sheet. Use its faces, proportions, silhouettes, costume construction, equipment and front and rear details as the design reference. A similar role or color palette is insufficient.

| Character | Required design features |
| --- | --- |
| Knight | Expressive youthful face and dark hair; swept red plume; open-faced metal helmet; curved blue armor with substantial gold trim; layered gauntlets and boots; brown belt and pouches; red embroidered cape; tall blue and gold star shield; broad silver sword with the concept's ornamentation. |
| Gargoyle | Short, broad, powerful proportions; mischievous stone face; curved horns; sculpted stone anatomy and pale carved markings; large hands and claws; substantial purple wing membranes and shaped green supports; tail; gold cuffs; purple sash and hanging star motif. |
| Witch | Confident expressive face; oversized crooked purple hat with its belt and star ornament; thick silver braid; fitted layered purple costume and flared coat tails; gold trim and embroidery; pointed boots; belt accessories, pouch and cyan potion; crescent staff with cyan crystal and star details. |

The rear views matter because the game uses a chase camera. Armor layering, cape shape and embroidery, wing structure, braid volume and coat construction must remain recognizable from behind.

## Rendering style is undecided

The owner is considering changing the rendering style toward the other two supplied references. They have not selected or approved a final new rendering style, altered character proportions, or a redesign of the cast.

| Reference | Role in the discussion | Visible qualities |
| --- | --- | --- |
| Original MysticRun concept sheet | Authoritative character designs | Detailed sculpted forms, expressive faces, layered costumes, painted material variation, deliberate front and rear silhouettes. |
| Dense comic illustration | Candidate rendering direction | Ink strokes, print texture, colored shadows, irregular painted surfaces, saturated lighting and dynamic movement. |
| Illustrated city screenshot | Candidate rendering direction | Broad color areas, crisp shadow shapes, cleaner detail and a drawn appearance across 3D architecture and the character. |

The assistant recommended exploring the concept-sheet cast in an illustrated fantasy world, combining readable shapes with richer comic texture and lighting. That is a recommendation, not an owner-approved production style.

The third reference's caption mentions Three.js. No engine migration was requested or authorized by that image. The current project remains Godot. The visual references are guidance for look development and are not admitted runtime assets.

## Next proposed work

Before further character construction, make a controlled comparison of the same Knight design, pose, camera and composition in three treatments:

1. The polished finish of the original concept sheet.
2. A textured comic treatment based on the second reference.
3. A cleaner illustrated treatment based on the third reference.

Keep character identity fixed so the comparison isolates the finish. Label any generated look-development images as concepts. They are not evidence that a finished, rigged, animated 3D character exists.

After the owner chooses the rendering direction, reconstruct one faithful Knight benchmark. Compare its actual engine renders with the concept sheet in front, rear, face close-up, running, sliding, jumping and chase-camera views. Apply the approved approach to the Witch and Gargoyle only after that benchmark visibly succeeds.

An illustrated finish still needs accurate geometry. Facial structure, overlapping armor, tailoring, wing and horn shapes, and hair volume must support the rendering. Asset counts and code checks are not visual acceptance.

## Status of the downloaded asset batch

The 57 GLBs are construction resources and review candidates: five original props, 28 environment models, four rigged outfit assemblies and 20 modular clothing parts. The four assemblies reuse the modular parts; they do not represent four finished new game characters. Their separate heads are absent.

The Ranger and Peasant costumes have not been accepted as replacement designs. Their topology, rigging or individual components may be useful only where the resulting work conforms to the owner's concept. Their colors, proportions and silhouettes must not pull the cast away from that reference.

The asset acquisition and review pipeline is saved. The current installed game, published APK and playable cast were not replaced by that pipeline. The owner has not approved the current cast's production visual quality.

## Reference identity and access

The handoff bundle contains the exact attached image bytes at these paths. The native file identifiers are also retained for future retrieval.

| Bundle path | Original attachment | Native file identifier | SHA-256 |
| --- | --- | --- | --- |
| `references/01-character-concept.png` | `1000048042.png` | `libfile_561fbab98ae081918a399fce28b9b98a` | `17fcdda5ef60f3997ca11293238eae47d528bc3edb675c584f866e4ef27242ec` |
| `references/02-comic-rendering.jpg` | `1000048207.jpg` | `libfile_ec9c7d384bd48191b90d82b6fa0bb933` | `0690c9d44595fd7052c8a475bf1cfb07d46aa26765db8747ff730e947b972c65` |
| `references/03-illustrated-city.jpg` | `1000048208.jpg` | `libfile_a99398680e948191aa92248009d3272d` | `491f74ace5261a3e30c36e4894456518d39a18433f3bb836245d1a10a173f7bd` |

Read and inspect the actual images before proposing or building new character art. This document's feature list supplements the images; it does not replace them.


## Owner decision — MR-ART-001 (November 5, 2026)

**Rendering treatment selected: B — textured hand-drawn comic fantasy.**

This decision resolves the previously undecided rendering finish only. The original MysticRun character concept sheet remains the authoritative design specification for the Knight, Gargoyle and Witch. The generated comparison posters from MR-ART-001 and the initial MR-ART-002 exploration visibly drifted from that sheet and are **not** accepted character-design references or runtime assets. In particular, do not replace the Knight with a bearded, bareheaded lion-crest warrior.

### Locked production rules

- Knight: youthful expressive face, dark hair, open-faced helmet with swept red plume, curved blue-and-gold armor, layered gauntlets and boots, brown belt/pouches, embroidered red cape, tall blue-and-gold star shield, and broad ornamented silver sword.
- Finish: deliberate ink accents, painted color variation, tactile comic textures, shaped shadow regions and saturated but readable lighting; avoid anime proportions, generic armor, primitive blocky meshes and flat untextured surfaces.
- Chase-camera priority: distinctive helmet plume, shoulders, cape embroidery, sword and shield must remain recognizable at gameplay distance.
- The exact source image must be inspected before a claim of visual fidelity or final model approval. Text alone is not sufficient to reconstruct it exactly.
- Preserve the existing Godot 4.7.2 gameplay, character APIs, rigs, progression, saves, package identity and original Android signing certificate.
- No production-model replacement or APK release is approved merely by the Style B selection.

### MR-ART-002 — implementation gate

1. Obtain and inspect the exact approved character sheet and its front/rear details from the saved handoff references.
2. Compare the existing authored Knight's actual Godot front/rear/face/chase-camera captures to the approved reference, logging specific geometry/material discrepancies.
3. Prepare a deterministic Blender 4.3.2 change plan for the existing Knight generator and rig, with an explicit material/outline strategy for Godot GL Compatibility.
4. Implement only one scoped, verifiable Knight refinement after the comparison, preserving the current asset as rollback.
5. Run the existing rig/asset/gameplay checks, capture actual Godot output, and review against the reference. Do not equate a concept image with an imported animated 3D asset.
6. Save the source checkpoint on the art branch; no automatic merge or APK publication.

**Decision recorded:** Style B approved. **Not yet approved:** a new Knight geometry, final concept fidelity, phone performance or the full cast.
