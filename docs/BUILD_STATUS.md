# Current development — authored three-character cast

November 4, 2026 · Lamont Labs · `quality/free-asset-foundry` · [Draft PR #5](https://github.com/Lamont-Labs/Mystic-Run/pull/5)

Knight, Gargoyle and Witch now have original visible meshes on the admitted CC0 rigs. The branch also includes seven free KayKit scenery models, a hashed asset registry and reproducible character generators. [Knight refinement](KNIGHT_EXPRESSION_REFINEMENT.md), [Gargoyle checkpoint](AUTHORED_GARGOYLE_CHECKPOINT.md) and [Witch checkpoint](AUTHORED_WITCH_CHECKPOINT.md) contain actual engine frames and evidence.

The Gargoyle milestone is saved as `2e4606d6ae24941d8d825408eb3a815d59621863`; both GitHub gameplay runs and [Android compilation](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41961021389) passed. Witch is saved as `dbbbb65100742c238e9b2055d88b6f6cb978c9d1`, with both gameplay runs and Android compilation green. A separate [Gargoyle surface correction](GARGOYLE_SURFACE_REFINEMENT.md) follows it. Current local validation passed 863 Godot assertions, 20 Python tests, 49 asset checks and three 3,600-tick runs without damage, deaths or involuntary handoffs. These results do not establish sustained Android performance.

The installable published version remains build 1016, linked below. This development branch has not been merged or published as a signed release. Remaining work includes surface/material and LOD refinement, owner art review, physical-phone controls/performance checks and a build using the existing owner signing identity.

The following sections preserve the published builds' historical verification records.

---

# Authored Knight preview — Android build 1016

November 3, 2026 · Lamont Labs

The first authored Knight model is implemented and verified in source `1b954cb90b7dbdfa13f9a115ac84b3be178f7cfa`. It is a playable art iteration; the full cast overhaul and final visual approval remain open. See [implementation and actual engine frames](AUTHORED_KNIGHT_FIRST_PASS.md).

[Release 0.6.1 / build 1016](https://github.com/Lamont-Labs/Mystic-Run/releases/tag/v0.6.1-build1016) is published. [Download the signed Knight preview APK](https://github.com/Lamont-Labs/Mystic-Run/releases/download/v0.6.1-build1016/Mystic_Run_0.6.1_Knight_Preview_Build1016.apk). Publication workflow [41724194108](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41724194108) downloaded its uploaded APK and verified the exact signed SHA-256. The GitHub asset digest and byte count also match the local signed artifact. Source workflow [41723400877](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41723400877) passed.

Local verification passed 802 assertions and all three 3,600-tick scripted runs. Actual rendered navigation passed 148 checks. A sixty-second actual desktop benchmark covered 1,312.707 meters with zero damage or handoffs. Physical-phone performance has not been measured.

GitHub compilation [41723400899](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41723400899) produced version 0.6.1/build 1016. All 108 runtime source hashes match the reviewed local files. The signed APK is 40,922,631 bytes, SHA-256 `4b63855499f856e4ce11d33379934d86a369c448a85c315213e7eae20ce4f93a`. Its preserved owner certificate, ZIP integrity, package/version, archive alignment and native 16 KB alignment were verified. The public archive/signature record reconstructs the same signed bytes without including private signing material.

---

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
