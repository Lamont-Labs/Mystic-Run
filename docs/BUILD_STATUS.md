# Playable Build Status — 0.1.2

October 31, 2026 · Lamont Labs · Working title: Mystic Run

## Current implementation

The previous headless-only foundation is now a playable 3D scene. Three original articulated characters, three environment treatments, running combat, route handoffs, touch gestures, menus, settings, profile saves, original audio and Android export are implemented.

Signed 0.1.0 and 0.1.1 APKs exported successfully. Version 0.1.2 adopts the Mystic Run name and retains the existing package and signing identity so it can update the previous development build. The accompanying APK manifest is authoritative for the delivered artifact's bytes, signature, package and source identity.

## Actual checks

| Check | Result | Boundary |
| --- | --- | --- |
| Gameplay-core assertions | 427 passed | State rules |
| Scene/menu/physics/gesture assertions | 37 passed | Desktop/headless interaction |
| Knight-start scene run | 840 m, 3 handoffs, zero damage/deaths | Automated input driver |
| Gargoyle-start rendered run | 840 m, 3 handoffs, zero damage/deaths | Software-rendered desktop |
| Witch-start scene run | 840 m, 3 handoffs, zero damage/deaths | Automated input driver |
| Handoff coverage | All six directed teammate changes | Same-character continuation also checked |
| Jump trajectories | Approximately 1.7–2.0 m peaks | Recorded run observations |
| Character-centre framing | Zero off-screen ticks in those runs | Full wings and every phone aspect require further review |
| Android export | Delivered artifact is signature-, certificate- and 16 KB-alignment-checked | Phone installation remains open |

Reports live in `tests/evidence/`. The automated driver is disclosed and does not establish human playability or Android hardware performance.

## Corrections made during the loop

1. Freed temporary, unparented track mesh instances.
2. Preserved upward impulses that grounding code had cancelled; tested real jumps for all three characters.
3. Revised portrait camera tracking to keep the runner in frame during lane changes.
4. Preserved the settings screen's parent when returning through credits.
5. Stopped active audio and allowed a drain interval before controlled shutdown.
6. Gave powers a separate bounded attack identity so charge is independent of basic attack recovery.
7. Required a clear Witch blink destination and displayed its anchor.
8. Separated gameplay randomness from cosmetic/audio randomness.
9. Reworked checkerboard-like flooring, materials, armor and menu framing.
10. Added original launcher art, control glyphs and bundled engine/font notices.
11. Corrected font variation tags that silently left interface text at extra-light weight; strengthened menu labels and character-selection contrast.

## Quality boundary

This is a functional early alpha with original procedural art. Final premium visual quality has not been approved. Character proportions, enemy animation, environmental variety, set pieces, lighting and effects remain iteration work.

The current game uses a straight path with three lane anchors, fixed 14 m/s progression and a bounded, seeded encounter stream. Environmental themes change through handoffs. Richer branching geometry, authored multi-district progression and mastery remain future work.

Combat checks lane alignment, forward range, height, blockers, attack windows and session tokens. Obstacles use explicit geometric contact envelopes. The physical motor handles ground/jump capsule movement. This is not represented as a general-purpose melee simulation.

## Open gates

- Install on the owner's phone and record launch behavior.
- Check touch comfort, safe areas, frame pacing, GPU compatibility and sustained thermal behavior.
- Confirm updates retain settings and records under the preserved signing identity.
- Publish and verify the complete project and remote checks in `Lamont-Labs/Mystic-Run`.
- Configure the preserved development key as GitHub secrets if remote APK builds are desired.
- Continue visual review against the owner's target using actual phone gameplay.

Private signing material is preserved separately and excluded from source. No phone test, remote push or final visual approval is claimed without its evidence.

## GitHub destination

The canonical destination is the owner's private `https://github.com/Lamont-Labs/Mystic-Run` repository. Installation queries identify organization `Lamont-Labs` and list this repository with push access. The personal-account repository `LamontLabs/MysticRun` was the earlier attempted destination and is not used for this project connection. Remote publication and CI results require their own evidence; the local Android checks above do not establish either.
