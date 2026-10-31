# Mystic Run 0.2.0 development status

October 30, 2026 · Lamont Labs

This revision implements the first comic-art and authored-animation pass following
the owner's Temple Run / Marvel Snap reference. The premium visual target remains
open. See ART_DIRECTION.md for implemented changes, provenance and concrete gaps.

## Verified locally

| Check | Result | Boundary |
| --- | --- | --- |
| Deterministic gameplay core | 427 assertions passed | State rules |
| Scene/menu/physics/gesture controls | 37 assertions passed | Desktop/headless |
| Rig retargeting and motion | 18 assertions passed | Authored run, combat blending, proportions, slide and jump |
| Three starting-character runs | 840 m and three handoffs each; zero damage/deaths | Automated desktop input |
| Directed handoff coverage | All six teammate pairs | No physical-phone test |
| Character-centre framing | Zero off-screen ticks | Full wings and all phone aspects need further review |
| Rendered review | Actual Godot menu, course, all three heroes and handoffs inspected | Software Mesa desktop rendering |
| Release reconstruction | Six contracts passed | Existing GitHub APK publication mechanism |

The new APK retains package `com.lamontlabs.knightgargoylewitch.dev` and must use
the preserved owner signing identity and a version code greater than 1003.
GitHub compiles the unsigned APK; owner signing and byte/certificate verification
follow before publication. The signed APK manifest is authoritative for exact
source commit, build run, package, version, hash and signing certificate.

## Corrections during this revision

Weighted humanoid topology and authored motion replace the primitive limb rig.
Upper-body attacks retain running leg motion. Bone lengths are preserved when
retargeting the different bodies. Immediate skeleton updates eliminate an invalid
first handoff pose. Thin bevel geometry no longer folds through the road surface.
The distant city is painted artwork; road, nearby architecture, props, characters
and effects are 3D. Curvature is a visual course deformation, with stable collision
space near the runner. The current game does not yet have timed 90-degree turns.

## Remaining quality work

Detailed production character meshes that better match the illustrations; more
organic wings, clothing and secondary motion; authored encounter sequences,
stronger environment transitions, terrain/set-piece variety, richer combat and
audio feedback, and physical Android performance/touch testing remain necessary.
Automated checks and attractive menu art do not establish the owner's visual bar.
The owner's earlier quality rejection remains a valid constraint.

The prior signed 0.1.2 build remains available under GitHub Releases. This revision
is checked on `quality/comic-runner` before updating the default branch and signed
release. Credentials and signing keys are never committed.
