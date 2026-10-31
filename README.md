# Mystic Run — Android Development Build

**Lamont Labs · Working game title · Version 0.1.2**

A playable 3D endless runner combining dark fantasy and futuristic architecture. Knight, Gargoyle and Witch are separate teammates who hand the continuous run to one another through route choices. This is an early playable alpha; the owner's premium visual target remains an active development goal.

## Playable features

- Three original articulated characters with separate silhouettes and powers.
- Starting selection and route-driven handoffs between separate teammates.
- Endless cathedral, rooftop and rift visual treatments.
- Directional movement, jumping, sliding, melee/spell attacks and signature powers.
- Knight charge, Gargoyle wing burst/glide, and Witch blink toward a visible safe anchor.
- Enemies, barriers, low beams, gaps, collectible shards and shared health/score.
- Pause/resume, results, restart, settings, personal best and profile backup recovery.
- Original synthesized audio, optional vibration, graphics settings and license credits.
- Portrait touch controls plus desktop keyboard support.

## Controls

| Input | Action |
| --- | --- |
| Swipe left/right | Change path |
| Swipe up/down | Jump/slide |
| Strike / Power | Basic attack / signature ability |
| A/D or arrows | Desktop movement |
| Space / E | Desktop attack / power |
| Escape | Pause/resume |

At a gate, marked paths lead to Gargoyle, Knight and Witch. The choice commits near the entrance. Handoffs preserve distance, health, score and separate cooldowns.

## Run and check

Open `project.godot` in **Godot 4.7.2 standard**, import assets, then run. The game uses GDScript and Compatibility rendering, with no required backend or account.

```bash
godot --path .
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/scene_interactions.gd
godot --headless --path . -- --qa --qa-ticks=3600
```

The last command drives a real 60-second automated scene run. Add `--character=gargoyle` or `--character=witch` to exercise another start. These desktop/headless checks are not phone latency, GPU or thermal tests.

## Android

The export preset defines the arm64 development package `com.lamontlabs.knightgargoylewitch.dev`. Use matching Godot 4.7.2 export templates, JDK 17, Android platform/build tools 35 and the existing owner development keystore.

`tools/build_android.py` requires `--godot`, `--sdk` and `--keystore`. It imports, exports, verifies the signature and 16 KB alignment, inspects package metadata and writes a source-bound manifest. Signing material is stored separately and never committed.

The manual GitHub Android workflow expects `RELAY_DEVELOPMENT_KEYSTORE_BASE64` and `RELAY_DEVELOPMENT_KEY_PASSWORD`. The core workflow needs no secrets. The canonical source destination is https://github.com/Lamont-Labs/Mystic-Run, the owner's private organization repository covered by the connected GitHub app. Remote workflow outcomes are verified separately from local checks.

`Compile Android APK` runs on game/build changes to `main` and creates an explicitly unsigned APK with GitHub run, source, package and byte-hash evidence. This job requires no signing secret. Its artifact requires owner signing before phone installation. `tools/sign_android.py` signs the downloaded compilation with the preserved key and verifies its source/run identity, unchanged packaged game files, certificate, package/version, ZIP integrity, 16 KB alignment and bundled notices. The final signed manifest preserves the original GitHub compilation metadata.

## Verified scope

- 427 core assertions and 37 scene/physics/menu/gesture assertions passed.
- Three automated 840 m runs completed with three handoffs each and zero damage/deaths, covering all six directed teammate pairs together.
- Rendered frames were reviewed through several revisions. Jump cancellation, camera clipping, navigation and audio shutdown were corrected.
- An initial signed APK exported successfully. The delivered APK manifest records the final artifact's exact verification.
- Physical installation, touch comfort, graphics compatibility and sustained phone performance remain open.

See `docs/BUILD_STATUS.md` for current status, `docs/MASTER_DEVELOPMENT_BLUEPRINT.md` for the design baseline and `tests/evidence/` for actual records. Core check counts include repeated assertions.

## Source map

| Path | Responsibility |
| --- | --- |
| `game/main.gd` | Playable scene, movement, encounters, combat, handoffs |
| `game/hero.gd` | Character geometry and joint animation |
| `game/world.gd` | Environment kit, track, horizon, encounter props |
| `game/geometry.gd` | Geometry batching, armor, procedural materials |
| `game/hud.gd` | Menus, settings, credits, HUD, controls |
| `core/run_core.gd` | Fixed-tick state, ownership, rewards, cooldowns |
| `core/route_contract.gd` | Static route safety checks |
| `tools/create_audio.py` | Original sound generation |
| `tools/render_preview.py` | Actual rendered capture |
| `tools/build_android.py` | Android export and verification |

## Ownership

Original game source, procedural art and audio: Copyright 2026 Lamont Labs. All rights reserved. Godot is separately MIT licensed. Cinzel and Manrope use the SIL Open Font License. Notices are bundled with the source and application. Private keys and owner credentials never belong in source commits.
