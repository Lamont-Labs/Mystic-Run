# MysticRun gameplay architecture validation

## Decision

**Retain Godot, but do not approve the present character-animation architecture
or a full production rebuild yet.** Prototype one properly segmented 2D character
rig and measure it on the target phone. No Unity migration is justified by the
evidence collected here.

This is a bounded validation, not an assertion that the game is now premium.
Normal main startup, artwork, saves, package and permanent signing identity are
preserved. Neither draft branch is authorized for merge or automatic release.

## What actually renders

All three player heroes follow the same presentation path:

| System | Shipped behavior |
|---|---|
| `hero.gd` | Instantiates the GLB and rig, but sets the model invisible; also builds concept presentation. |
| `cutout_motion.gd` | The visible subdivided billboard uses the approved concept/action atlas. Weighted image deformation and whole-image pose blends supply movement. |
| `rig_motion.gd` | Samples existing CC0 Quaternius clips onto each authored skeleton, including while its model is hidden. Knight has 65 bones; Gargoyle/Witch retain their additional controls. |
| `main.gd` | Owns input, movement, collision tests, character state and camera updates. Previously restarted a fixed-duration ease for lane changes. |
| `world.gd` | Recycles mesh track chunks alongside panorama imagery, painted scenery, particles and distance-based biome state. |

The visible players are **not** the retargeted skeletal runners. Improving
hidden skeletal clips cannot fix the visible cutout's pose quality. Also,
switching the existing models on is not an acceptable fidelity solution: the
legacy mesh appearance differs substantially from the approved concept.

The experiment exposes both paths, normalizes skeletal rest-display height,
and opts out of evaluating the hidden representation. Default hero flags retain
normal game behavior. No mesh, bone, morph, character artwork or source animation
was overwritten.

## Reproduced control faults

The original implementation failed 9 of the first 11 new actual-scene assertions:
opposing jump/slide intents, neutral pad drift, analog ownership after release,
and ambiguous diagonal gestures. Corrections are isolated in the control-fix
draft, separate from the renderer/camera/track experiment.

The expanded standalone suite passes 238 assertions. Existing navigation (148),
adventure/progression (125), controls (38), tilt/elevation (35), concept sprites
(156) and biome/articulation (331) passed during this work.

These numbers are not quality approval. The matched full sequence revealed a
short slide-to-fall-to-slide contact-state flicker that the standalone fixture
did not catch. That limitation is preserved in the reports rather than hidden.

## Matched experiment

Baseline: exact published Build 2011 source
`4a168264d15d06ab751571794a08e006858e6552`, extracted read-only from Git.
Only the measurement harness is added to that snapshot.

Knight: four cells, baseline/prototype × cutout/skeletal, using the same timed
native touch/key events for steering, reversal, jump, fast-fall/slide, conflicting
vertical commands and attack. Matching obstacles are added through the real
game encounter API. All measured runs retained full health.

Additional matched Gargoyle framing runs and a Witch render verify that the
common path is active for all three heroes.

The candidate camera follows less laterally, damps aim separately, holds FOV
constant and moves farther back. Gargoyle remains at its current 1.59 height,
already reduced from the earlier 2.48. Conservative maximum quad screen height
falls from 26.5% to 18.5%; Knight falls from 34.2% to about 25.0%. These are
transparent-quad bounds, not pixel-accurate occlusion measurements.

The 96 m Castle-only candidate adds paved terraces, carved copings, painted
towers and approved gateway meshes. It reuses existing reviewed assets, changes
no collider or encounter dimensions, and performs no new biome development.
Its artistic quality still requires owner evaluation.

## Measurements and limits

See `tests/evidence/architecture-validation.json` for raw reports and runtime
source hashes. The downloadable self-contained review contains the measured
table, two synchronized comparison videos and actual game screenshots.

Testing used rendered Linux Mesa llvmpipe/Xvfb at 360×640. Uncapped benchmarks
are separate from fixed-clock capture. One short run per cell is descriptive,
not statistical performance certification. Initial 0.8 s is excluded.

The detailed candidate runs slower than the baseline in the software renderer.
Skipping hidden rig work reduces isolated animation CPU median from about
85 µs to 10 µs for the cutout, but that saving is under 0.1 ms and must not be
misrepresented as an overall performance fix. Added scenery and camera framing
also change in the prototype, so end-to-end differences are not attributable
to a single component.

Injected steering/jump input reaches simulation in one tick (~16.7 ms).
Baseline pad release fails to reach its intended lane within 500 ms; the
prototype settles in about 200 ms. Air-to-slide takes longer because landing
must occur. Buffered attacks likewise intentionally wait for a reachable target.
None of this measures physical touch-to-visible-frame latency.

**No S23 FPS, thermal stability, sensor behavior, input latency or installation
test was performed. No APK was built or published for this validation.**

## Why not simply install more plugins?

The official Godot components and examples provide an appropriate foundation;
the project already has reusable CC0 skeletal clips. Phantom Camera (MIT) is a
credible follow/framing candidate, and Godot State Charts (MIT) is a candidate
for explicit action ownership. Neither supplies missing artwork or resolves a
concept/mesh mismatch. No plugin was installed merely to add another abstraction
over incorrect input behavior. The bounded camera trial uses native Godot nodes.

## Next decision gate

1. Owner compares the videos and playable scene, including the visible defects.
2. One properly layered 2D Knight demonstrates coherent independent limb motion,
   planted contacts, clean landing/slide recovery and faithful proportions.
3. The real S23 establishes an acceptable frame budget and perceived touch
   response using the locked Android update identity.
4. Only then expand to the other heroes and environment production.

Unity investigation becomes reasonable only for a demonstrated engine/toolchain
limitation on the target device, not as a substitute for those missing proofs.
The lab instructions and reproducible baseline commands are in
`experiments/architecture_validation/README.md`.
