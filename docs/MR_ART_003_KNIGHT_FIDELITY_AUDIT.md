# MR-ART-003 — Knight fidelity audit and implementation gate

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Status: SOURCE REVIEW COMPLETE / IMAGE COMPARISON BLOCKED / GEOMETRY UNCHANGED

## Authority and baseline

The owner selected Style B (textured hand-drawn comic fantasy). This selects the rendering finish only. The original MysticRun character concept sheet is the authoritative design target. The generated comparison and subsequent concept poster are not approved Knight redesigns.

Read:
- `docs/CHARACTER_FIDELITY_AND_STYLE.md`
- `docs/AUTHORED_KNIGHT_FIRST_PASS.md`
- `docs/HANDOFF_NEXT_CHAT.md`
- `docs/ANDROID_UPDATE_IDENTITY.md`

Existing Knight: `tools/build_knight_asset.py` authors a weighted GLB; `game/hero.gd` loads it; `game/rig_motion.gd` preserves locomotion/retargeting. The documented first pass has 24,348 main-mesh triangles, 65 bones, two morph targets, one main material surface. Source geometry and export are already reproducible with Blender 4.3.2.

## Source-grounded gaps (not newly measured)

1. Face and hairline: existing checkpoint explicitly calls for refinement. Target: expressive youthful face, dark hair, open-face helmet.
2. Helmet and plume: improve transition geometry and swept red plume; maintain strong chase-camera silhouette.
3. Armor: preserve curved blue armor, substantial gold trim, layered gauntlets/boots, belt and pouches; improve geometry/material separation where comparison requires it.
4. Equipment: preserve embroidered red cape, tall blue/gold star shield and broad ornamented silver sword. Do not substitute lion heraldry or generic armor.
5. Materials: current first-pass uses vertex gradients; a painted texture atlas and final comic ink/shadow treatment remain incomplete.
6. Animation: existing imported locomotion works but is not a Knight-specific final animation set. Do not disturb gameplay APIs, hitboxes or save data.
7. Mobile: no physical Android frame pacing, thermal, memory, upgrade or visual acceptance evidence.

## Evidence boundary

The source handoff identifies the authoritative images:
- `references/01-character-concept.png` SHA-256 `17fcdda5ef60f3997ca11293238eae47d528bc3edb675c584f866e4ef27242ec`
- `references/02-comic-rendering.jpg` SHA-256 `0690c9d44595fd7052c8a475bf1cfb07d46aa26765db8747ff730e947b972c65`
- `references/03-illustrated-city.jpg` SHA-256 `491f74ace5261a3e30c36e4894456518d39a18433f3bb836245d1a10a173f7bd`

The exact reference images were **not** accessible in the current runtime when this document was authored. Accordingly, no actual front/rear/pixel comparison was completed. No new Godot render, Blender model, performance benchmark or APK was produced. Source documentation cannot substitute for inspecting the original images.

## Next single implementation task — MR-ART-004

1. Retrieve and hash-verify `references/01-character-concept.png` from the saved handoff; visually inspect it.
2. Retrieve the current Knight's actual Godot front, rear, face and gameplay captures from `docs/previews/`, and inspect them side by side.
3. Write a feature-by-feature discrepancy matrix with direct visual evidence for head/helmet/plume, armor, shield/sword, cape and rear silhouette.
4. Select the **smallest single geometry or material refinement** justified by that matrix; implement through the existing deterministic Blender generator, retaining source and rollback.
5. Run existing character/rig/gameplay checks, import in pinned Godot 4.7.2, capture actual engine renders and compare again. Stop on failures.
6. Commit only verified source changes to the art branch. Do not merge, sign or publish an APK without a separate release gate.

## Preservation

Preserve existing Knight/Gargoyle/Witch runtime, core rules, tilt/elevation, animation API, progression and saves, Android package `com.lamontlabs.knightgargoylewitch.dev`, and owner signing certificate. Free tools and properly licensed assets only.
