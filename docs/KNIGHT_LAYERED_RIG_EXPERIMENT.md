# One concept-faithful, articulated 2D Knight

This is the owner-approved **single rear-view Knight experiment**, not authority
to rebuild every character, expand biomes, merge into main or publish a release.
Normal startup, game scripts, artwork and Android identity remain unchanged.

## What actually runs

Open `experiments/knight_rig/playable.tscn` in Godot 4.7.2 and press **F6**.
It instantiates the actual game, controller, physics, camera and Castle prototype
using an isolated test profile. Arrows steer/jump/slide, Space attacks and E uses
the existing power. R cycles layered Knight → legacy skeletal → old cutout.

Fourteen painted parts are attached to a native `Skeleton2D`/`Bone2D` hierarchy.
One transparent 384×448 SubViewport renders the joints to the existing 3D world
through a billboard. This is a rigid layered-painting rig, not a new 3D model or
a claim of fully deformable production skinning.

The palette, armor, helmet/plume, cape/star, shield and sword come directly from
`assets/characters/concept-sprites/knight_rear.png`. Original source is unchanged.
The atlas uses 1024×512 pixels and includes provenance, rest pivots, overlapping
cut masks, draw ordering and parent joints in `art/rig.json`.

The numerical gait has a 62% planted-foot interval, rear-view knee projection
and longitudinal limb foreshortening, with independent head/cape/arm/weapon
rotation. Rear flexion occurs mostly in depth: unrestrained planar knee bending
was rejected because it splayed the legs sideways. Action changes blend joint
angles rather than fading between full character paintings. Lower-body running
continues under grounded attacks. Slide lowers the pelvis and folds the torso;
feet retain level orientation. The presentation suppresses a brief contact-state
flicker without changing physics, hitboxes or controller rules.

## Reproduce

```sh
python3 tools/build_knight_layers.py
python3 tools/test_knight_layers.py
engine-tools/godot/Godot_v4.7.2-stable_linux.x86_64 \
  --headless --path . --script res://tests/knight_layered_rig.gd
python3 tools/run_architecture_review.py \
  --godot engine-tools/godot/Godot_v4.7.2-stable_linux.x86_64 \
  --variant prototype --renderer layered --mode capture \
  --output generated-artifacts/knight-rig/review-capture
```

Repeat with `--renderer cutout` for the same camera, Castle and native input
sequence; use `--mode benchmark` separately for actual uncapped frame intervals.
The baseline here is the **previous Castle prototype's cutout**, not a claim
that these results directly compare against the published phone APK.

`experiments/knight_rig/preview.gd` captures real transparent native-rig renders.
The sixteen run images are samples of a continuous joint cycle, **not sixteen
independently drawn animation frames**. Idle/jump/fall/land/slide/attack/damage/
power/victory/defeat images are isolated pose previews. Only running, jumping,
falling, landing, sliding and attack were exercised in the matched gameplay
sequence; isolated targets are not end-to-end action verification.

## Evidence and results

`tests/evidence/knight-layered-rig.json` contains raw reports and runtime/art
source hashes. The downloadable review contains matched game footage,
sixteen actual joint renders and isolated action targets.

| Software-rendered case | Mean FPS | p95 frame interval |
| --- | ---: | ---: |
| Existing Castle prototype cutout | 6.57 | 156.4 ms |
| New layered Knight | 7.13 | 163.4 ms |

360×640, Linux Mesa llvmpipe/Xvfb, one descriptive seven-second simulation per
case, excluding initial 0.8 s. Both finished with health 3 and zero overlapping
airborne/slide ticks. These noisy samples **do not establish an overall
performance improvement**: the layered case has a worse p95 despite higher mean
FPS. They neither measure nor predict phone FPS or physical touch latency.
The new offscreen render target needs profiling on the target Android GPU.

Verification:

- 468 native-joint/pose/foot invariants passed.
- Maximum measured numerical ankle-target error was below 0.001 source pixels.
  This is not pixel-perfect contact proof against the curved road.
- All sixteen native run renders have distinct image hashes.
- 63,466 visible atlas samples retain the original source RGB; source hash,
  hierarchy, atlas dimensions and alpha provenance passed.
- Movement controls 238, concept assets 156, existing rig 29 and runner controls
  38 checks passed. GitHub also runs the new native-joint suite.
- Matched gameplay video: 141 frames, 7.05 seconds, 720×712 side by side.
- Render logs contain no script or runtime errors.

## What remains unapproved

Rear view only. No new front/side paintings or concealed joint surfaces were
invented. Part seams, overlapping edges, cape articulation and all action timing
still require visual review; native math assertions are not artistic approval.
No physical Android test, sustained frame-time/battery measurement, weighted
deformation or full production integration is claimed.

No other character or biome was rebuilt. No APK was built, no release published,
no signing credential accessed, no save modified and no phone installation
altered. Preserve the existing permanent Android identity for any later build.
