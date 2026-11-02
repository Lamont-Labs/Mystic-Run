# Mystic Run 0.5.0 — Current gameplay contract

November 2, 2026 · Lamont Labs

This contract supersedes earlier relay navigation and 0.4.0’s separate Enter the City screen. The game remains an offline, portrait Android runner with Knight, Gargoyle and Witch selected before play.

## Opening and setup

The opening is an immediately usable main menu: title, the actual playable 3D runner, current mode and Run. Selecting a runner returns to this context and preserves the mode. A new profile starts with Endless; existing saved choices are respected. Modes also offers the finite Citadel, Spires and Rift expeditions. Journal and Settings stay outside active play.

The menu camera fits the runner into the reserved character area at the current aspect ratio. Menu and gameplay use the same model, equipment, materials and animation system. Illustration assets remain bundled as references and for existing supporting presentation.

## Controls and session

- Continuous calibrated tilt is the default; swipe steering remains available as a sensor fallback or explicit setting.
- Swipe up jumps; swipe down slides. Jump and slide buffers remain active.
- Tap the open play area or Strike to attack. Power uses the selected runner’s signature skill.
- One chosen character remains locked for the entire run. No teammate gates or mid-run replacements are spawned.
- The shared elevation profile drives road deformation, physical runner height, props and the chase camera.
- The 1.5-second ready cue holds progression still while calibrating. Tilt resume uses a 1.2-second ready cue.
- Pause and nested settings preserve the active run and suspend gameplay timers. Recenter uses an explicit protected ready period.

## First Endless run

An unfinished first-run introduction teaches left, centre, jump, slide, a successful strike and the selected power. During this stretch the encounter director is held and damage is suppressed. The combat lesson introduces one approaching sentinel; a miss repositions the lesson target ahead for another attempt.

Completed lesson indices are saved and restored. Retry resumes the next unfinished lesson. Completing the power lesson clears tutorial targets, resumes encounters ahead of the runner and continues the same Endless session. It creates no separate completed-run record.

Skip dismisses the introduction and is saved separately from `practice_complete`. Standalone practice remains replayable through Settings → How to Play and retains its own practice-completion result. Finite expeditions begin directly, without consuming their short course distance on integrated lessons.

## Combat readability

Aligned, unobstructed enemies become warning candidates within 1.6 seconds of nominal approach at the current pace. Sentinels prepare their weapon as they approach. A gold target bracket is preparatory; the active mint bracket and Tap to Strike cue correspond to an accepted immediate or buffered attack.

For melee, the cue distance is `min(11, 5.1 + max(speed, 18.5) × 0.24)` metres. An input in the outer cue range waits until 5.1 metres, then resolves through the existing animation, height, range, line-of-sight and attack-token checks. Witch’s ranged cue remains 13 metres. Warning logic is not a guarantee of a full visible 1.6 seconds across every crest, occlusion or phone latency condition.

## HUD and results

The persistent HUD prioritizes distance, compact health and relics, Pause, Strike and Power. District names appear briefly. Finite courses show exit progress. Routine speed, steering and ability-name diagnostics are hidden. Power communicates recharge around its action button. Pause, action and skip controls have larger canvas targets; physical dp and thumb comfort remain device checks.

Results show distance, score/relics once, defeated sentinels and the personal best. Run Again preserves the selected setup. Change Runner, Change Route and Return Home remain available.

## Playable presentation

Five prebuilt 24-metre silhouettes—Cathedral Arcade, Open Crown Bridge, Ribbed Vault, Reliquary Court and Broken Works—share the same deck width, connections and elevation contract. A fixed twelve-piece phrase assigns these variants to eleven recycled visible instances. There are fifteen prebuilt theme/variant meshes. Runtime recycling swaps their mesh references; it does not construct new architecture per frame.

Custom geometry uses clockwise front faces with outward normals. This fixes the reversed surfaces that previously presented the outline pass as black armor or scenery. The corrected material faces, shared 3D menu model, cloth and current chase-camera frames are the visual evidence for this revision.

This is an incremental playable revision. Detailed production character art, higher quality authored environments, expanded animation and sustained Android performance remain open.
