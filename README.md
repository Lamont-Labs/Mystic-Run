> Development: `quality/free-asset-foundry` includes the [free-asset integration](docs/FREE_ASSET_FIRST_PLAYABLE.md) and [Knight geometry/expression refinement](docs/KNIGHT_EXPRESSION_REFINEMENT.md), with verification and actual engine frames. The published Android release below remains build 1016.

# Mystic Run — Android runner

**Current revision: 0.6.1 / Knight preview build 1016.** Choose the Knight, Gargoyle or Witch and race through a colorful magical city. Dodge, strike, collect stars and return with treasures for your journal.

[Download Knight preview / build 1016 APK](https://github.com/Lamont-Labs/Mystic-Run/releases/download/v0.6.1-build1016/Mystic_Run_0.6.1_Knight_Preview_Build1016.apk) · [Android releases](https://github.com/Lamont-Labs/Mystic-Run/releases) · [Gameplay guide](docs/GAMEPLAY_AND_NAVIGATION.md) · [Build and verification](docs/BUILD_STATUS.md) · [Google Play preparation](docs/GOOGLE_PLAY_READINESS.md)

Tilt to steer, or use the separate thumb pad. Swipe up to jump, down to slide, and left or right to strike. Each runner has one special-attack button. Choose a runner for a whole run and try Endless or the Citadel, Spires and Rift expeditions.

Earn character mastery XP from ordinary runs to unlock each runner's traversal ability. Look for that character's portal, align with it and swipe up to find a secret route. Each expedition has a different chamber and treasure for each character: nine treasures in all. The journal tracks discoveries and fourteen achievements.

The game works offline and saves progress on the device. This is a development build. The separately signed APK is for direct installation; a production Google Play bundle, store listing and device validation remain to be completed.

## Develop and verify

Pinned engine: Godot 4.7.2. Open `project.godot` and run `scenes/main.tscn`.

```bash
python3 tools/bootstrap_godot.py --cache ../engine
python3 tools/verify_core.py --godot ../engine/Godot_v4.7.2-stable_linux.x86_64
```

GitHub checks cover progression, gestures, navigation, tilt/elevation, animation and basic-only scene runs for all three characters. Android compilation is followed by separate owner signing. An unsigned engineering Play bundle has passed bundletool validation; production identity, signing and device checks remain.

## Art and motion

Build 1016 introduces the first exported, weighted Knight replacement, with a visible face, open rounded helmet, curved armor, gloves, boots, sword, shield, blinking eyes and a moving coral plume. It is a first art pass below the concept-sheet finish; Gargoyle and Witch retain their preceding treatment. [Actual engine frames and implementation](docs/AUTHORED_KNIGHT_FIRST_PASS.md).

The 0.6.1 visual revision adds a floating storybook castle city, rounded towers, colorful balloons, larger character heads, a pointed Witch hat, friendly Gargoyle features, star capes, springy landings and a consistent purple-and-gold interface. Controls, progression, encounter timing and saved-game rules are unchanged.

The actual playable 3D runner appears in the menu. The Knight uses a newly authored mesh on a Quaternius CC0 skeleton; Gargoyle/Witch base meshes and the source motion library are Quaternius CC0. Custom equipment, architecture, interface, game systems and synthesized audio are in this repository. Distant city art and character illustrations were generated for Mystic Run. See `assets/ART_PROVENANCE.json`, `assets/models/quaternius/PROVENANCE.json`, `assets/characters/knight/PROVENANCE.json` and bundled notices.
