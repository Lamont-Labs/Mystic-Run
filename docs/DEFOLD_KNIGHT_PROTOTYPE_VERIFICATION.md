# Defold Knight trial: verified scope and remaining gates

## Delivered

A separate, playable Defold WebAssembly export with a joint-animated rear-view
Knight, three lanes, buffered jumping, landing, slide, strike, seeded obstacles,
relic pickup, damage recovery, pause, defeat and restart. Touch buttons, swipe
input and keyboard controls exercise the same Lua simulation.

The Knight uses the existing 14 painted cutouts. No new hand-painted animation
frames or AI character redesign were created. The backdrop and road reuse
existing artwork; obstacles are prototype fixtures, not a premium world rebuild.

## Evidence

- Tested implementation: `49bda431da8ba95f2d0931741dcbd293046aa5f3`.
- [Passing engine/build run](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/43780442521).
- [Separate draft review](https://github.com/Lamont-Labs/Mystic-Run/pull/26).
- Native Linux engine: **44 simulation assertions passed**, including lane bounds,
  reversal/convergence, pause, jump/land, buffering, slide recovery, frame-rate
  independence, seeded encounter equality, obstacle actions, damage and restart.
- ARM64 Android **resource compilation** passed in 8.702 seconds; web export
  passed in 3.343 seconds; Linux build/bundle passed in 4.350 seconds.
- Actual compiled browser game passed the touch-button, touch-swipe, keyboard,
  jump, slide, strike, relic collection, pause/resume, three-hit defeat and
  touch-restart checks at a 402×874 mobile viewport.
- Browser interaction logs reported no Lua script or JavaScript page errors.
- Actual gameplay screenshots, recording and browser results were retained under
  ignored `generated-artifacts/defold-knight/review/` and presented in chat.
- The browser test observed **20.78 Defold updates/second over 13.955 wall-clock
  seconds** in software-rendered headless Chromium. This is not a Samsung/Android
  measurement, not a 60 FPS claim, and not proof of premium smoothness.

## Preserved and not attempted

No main merge, Android APK, signing operation, new signing key, release or phone
installation change. Existing Godot/Unity source, approved assets, original
package identity and permanent signing configuration were preserved.

The installed game has **not** been replaced by this browser experiment.
Android APK packaging, native device execution, update eligibility and save
migration remain unverified. No broad engine migration, other-hero port or
three-biome rebuild is authorized by this prototype.

## Recommendation

Evaluate the actual playable motion and visual presentation first. Defold has
passed the editor-free build and bounded gameplay-functionality gates, not the
owner's visual-quality or Android-performance gates. Do not commit to a full
port based solely on these checks.
