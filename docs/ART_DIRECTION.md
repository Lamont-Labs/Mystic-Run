# Mystic Run: comic art and animation revision

The user reference is Temple Run's readable forward runner with the illustration
finish and strong visual identity of Marvel Snap. This is a quality target, not a
claim that the current development build has achieved that production level.
Original characters, setting, assets and interface are used throughout.

## Implemented in 0.2.0

- Original transparent Knight, Gargoyle and Witch illustrations in character
  selection and the gameplay HUD; subtle selection-screen motion and clearer CTA.
- Proper weighted humanoid meshes, authored sprint/jump/slide motion, retargeted
  target proportions, and upper-body combat layered over continuing leg motion.
- Bone-attached custom armor, weapons, cape, horns, wings, hair and staff.
- Restrained comic shading, silhouette outlines, character color accents, impact
  captions and small camera impulses; opponent sentinels use the same rig system.
- A painted distant city behind the 3D course, curved causeway presentation,
  pointed cathedral vaults, different district props and clearer gameplay HUD.
- Thin armor/road bevel correction and immediate skeleton updates during handoff.

The road bend is a visual course deformation. It is not yet a Temple Run-style
90-degree timed-turn mechanic. The run still needs authored encounter variety,
more detailed production character meshes and effects, stronger environment
transitions, and performance/touch validation on physical Android phones.

## Asset provenance and reproducibility

`assets/ART_PROVENANCE.json` records the original generated illustrations and city
matte. These art assets are not screenshots or proof of in-game model fidelity.
The actual Godot rendering is used for visual QA.

Humanoid mesh topology, weights and the source motion are from Quaternius, under
CC0 1.0. Only the FREE Standard editions were used. The source archives and per-file
hashes are recorded in `assets/models/quaternius/PROVENANCE.json`.

Publisher pages:

- https://quaternius.itch.io/universal-base-characters
- https://quaternius.itch.io/universal-animation-library
- https://quaternius.itch.io/universal-animation-library-2

To reproduce the selected geometry, obtain those three free Standard ZIPs and run
`python3 tools/prepare_cc0_assets.py --pack-dir /path/to/downloads`. This verifies
archive hashes, keeps geometry/weights and removes unused texture/material
bindings. Import with the pinned Godot editor, then run
`Godot --headless --path . --script tools/bake_motion.gd`. Remove the two source
GLBs after baking; only `runner-motion.res` and `source-rests.json` are required at
runtime. Eight used clips occupy about 116 KB compressed. Runtime mesh, hair,
clips and rest-pose data together occupy about 2 MB before engine packaging.

Bangers, Cinzel and Manrope are under SIL OFL 1.1. All included notices are shipped
inside the APK and referenced in credits.

## Verification scope

`tests/rig_motion.gd` checks real authored leg motion, continued leg motion during
combat, preserved target bone lengths, finite transforms, slide clearance and
upright jumping for all three characters. Existing deterministic core and scene
interaction checks remain in place. Three automated starting-character runs cover
all directed teammate handoffs. Desktop software-rendered captures are inspected
for character visibility, materials, course continuity and handoff frames.
These checks do not establish physical-phone performance or premium visual quality.
