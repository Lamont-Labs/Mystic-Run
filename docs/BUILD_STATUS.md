# Mystic Run 0.6.1 — cartoon presentation revision

November 3, 2026 · Lamont Labs

This revision changes visual presentation and cosmetic animation. It retains the 0.6.0 controls, three fixed-per-run characters, combat specials, mastery, nine secret routes, treasures, achievements and save behavior.

## Presentation

- A floating castle-city backdrop with rounded cream and lavender towers, coral roofs, mint gardens, balloons and drifting birds.
- Larger character heads, a broad pointed Witch hat, friendly Gargoyle eyes, bright armor and star-emblem capes.
- Cosmetic running bounce, lateral lean, settling landing squash and stronger cloth movement. Reduced Motion suppresses the added body bounce and cape flutter.
- Purple and gold menus and controls, with the actual playable character retained in the opening screen.
- Brighter lighting tuned against actual gameplay frames; subdivided decorative road supports prevent the underlying mesh from showing through the paving on hills.

## Verification

Local suites passed 797 Godot assertions: 427 core, 38 gesture/course, 125 adventure/progression, 148 navigation, 35 tilt/elevation and 24 animation. The navigation suite also passed all 148 checks with actual rendered desktop GUI hit testing. All three characters completed scripted 3,600-tick basic-only runs of approximately 1.31 km with zero damage, deaths, handoffs or off-screen runner-centre ticks. Four Android policy tests and six signed-archive reconstruction tests passed.

All 16 tracked files under core, content and scenes are byte-for-byte unchanged from the published 0.6.0 source at `0fdacd3fba841ecb22af9ca5fb506bd1d71a2d65`. In `game/main.gd`, only the environment setup function changed. HUD and thumb-pad changes are confined to drawing and styling.

Actual desktop renders of the opening screen, Knight and Witch gameplay, and a Gargoyle secret chamber were reviewed. These are software-rendered development checks, not measurements of Android performance or final owner art approval.

## Android

GitHub compiled version **0.6.1 / build 1015** from source `e7c8c7256844e9deedb1d10eda6a79abf0321080`. The signed APK is **40,049,784 bytes**, SHA-256 `dee2f7b90d76e272ffbbb52757aa2fb245546eb52b730f8036d2ba0f78098a6c`. All 102 runtime source hashes in the compilation manifest match the reviewed source. The APK preserves the owner signing identity and passes signature, ZIP integrity, unchanged signing payload, bundled-notice, 16 KB archive-alignment and 16 KB native-library checks. It targets API 36, supports API 24 and later, and declares vibration as its only permission.

[Android compilation](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41706092815) and [gameplay checks for that source](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41706092800) both completed successfully. [Release 0.6.1 / build 1015](https://github.com/Lamont-Labs/Mystic-Run/releases/tag/v0.6.1-build1015) is published. The release workflow downloaded its uploaded APK and verified its exact SHA-256; the GitHub asset digest and byte count also match the signed local artifact. Google Play production preparation and physical-device validation remain open.
