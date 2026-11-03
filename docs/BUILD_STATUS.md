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

The preserved development signing identity has been verified locally. GitHub compilation and publication of the 0.6.1 APK are pending at this source checkpoint. The existing 0.6.0 release remains available until the new APK is verified and published. Google Play production preparation and physical-device validation remain open.
