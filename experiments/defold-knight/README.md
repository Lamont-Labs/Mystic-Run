# MysticRun: one playable Defold Knight trial

Separate engine-evaluation project, **not a replacement for the installed game**.
The existing Godot game, Unity experiment, approved source art and Android
release/signing configuration remain intact. No APK, new signing key or release.

## What is playable

- Real Defold engine compiled to WebAssembly, not a JavaScript canvas substitute.
- Three lanes with critically damped movement and rapid direction reversal.
- Buffered jumping, landing recovery, blended slides and a sword strike.
- A 14-part rear-view Knight using the existing approved painted cutouts, with
  continuously sampled foot cycles, joint motion, cape follow-through and
  separate jump/slide/strike/damage poses. **Not new hand-painted animation frames.**
- Seeded obstacle encounters, relic collection, three-hit defeat, pause/resume
  and restart. First encounters teach jump, slide and strike; changing lanes is
  always another way past these fixtures.
- Actual touch buttons, directional swipes and keyboard controls. Arrow keys or
  WASD to move/jump/slide, J to strike, P to pause, R to restart.
- Existing Castle Heights backdrop and stone texture. Procedural obstacle
  graphics are evaluation fixtures, **not a completed premium environment**.

## Build and preview

1. `python tools/build_defold_knight.py --prepare-only` validates the Knight
   source hash and prepares an isolated project under `generated-artifacts/`.
2. The dedicated GitHub workflow supplies Java 25 and pinned Pillow, verifies
   Bob 1.14.1's SHA-256, compiles ARM64 Android **resources only**, exports the web
   game and executes native Linux headless simulation checks.
3. Download the workflow's `defold-knight-playable-web` artifact into
   `generated-artifacts/defold-knight/web/`. The prototype workflow serves only
   that compiled directory on port 5000; it never serves repository credentials.
4. `python tests/defold_knight_browser.py --url <preview-url>` uses the compiled
   engine in Chromium to exercise actual touch, swipe and keyboard input, jump,
   slide, strike, collectibles, pause, defeat and restart; it records screenshots,
   video and measurements under the ignored review directory.

The web artifact includes engine/font license notices. Concept-derived artwork
is restricted to **noncommercial game use**. Source provenance is generated
alongside build evidence. A clean clone needs a compiled web artifact before
the preview server can start; absence is reported explicitly.

## Evaluation boundaries

Compilation and automated input checks do not establish artistic acceptance.
Review the actual gameplay before any wider port. The animation still uses
masked painted parts, not a freshly illustrated multi-directional character.
Browser software-renderer measurements are not Samsung/Android performance.
No Android APK packaging, installation, certificate/signature verification or
save migration has been attempted. A future port must explicitly preserve both
the permanent Android identity and existing save data; neither is established
by an Android resource archive.
