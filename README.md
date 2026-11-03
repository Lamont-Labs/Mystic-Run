# Mystic Run — Android runner

**Current revision: 0.6.0.** Choose the Knight, Gargoyle or Witch and race through a colorful magical city. Dodge, strike, collect stars and return with treasures for your journal.

[Earlier Android releases](https://github.com/Lamont-Labs/Mystic-Run/releases) · [Gameplay guide](docs/GAMEPLAY_AND_NAVIGATION.md) · [Build and verification](docs/BUILD_STATUS.md) · [Google Play preparation](docs/GOOGLE_PLAY_READINESS.md)

Tilt to steer, or use the separate thumb pad. Swipe up to jump, down to slide, and left or right to strike. Each runner has one special-attack button. Choose a runner for a whole run and try Endless or the Citadel, Spires and Rift expeditions.

Earn character mastery XP from ordinary runs to unlock each runner's traversal ability. Look for that character's portal, align with it and swipe up to find a secret route. Each expedition has a different chamber and treasure for each character: nine treasures in all. The journal tracks discoveries and fourteen achievements.

The game works offline and saves progress on the device. This is a development build. The separately signed APK is for direct installation; a production Google Play bundle, store listing and device validation remain to be completed.

## Develop and verify

Pinned engine: Godot 4.7.2. Open `project.godot` and run `scenes/main.tscn`.

```bash
python3 tools/bootstrap_godot.py --cache ../engine
python3 tools/verify_core.py --godot ../engine/Godot_v4.7.2-stable_linux.x86_64
```

GitHub checks cover progression, gestures, navigation, tilt/elevation, animation and basic-only scene runs for all three characters. Android compilation is followed by separate owner signing. The Android Play Bundle export preset is a starting configuration and has not yet been validated as a production bundle.

## Art and motion

The actual playable 3D runner appears in the menu. Humanoid source meshes and motion are Quaternius CC0; custom equipment, architecture, interface, game systems and synthesized audio are in this repository. Distant city art and character illustrations were generated for Mystic Run. See `assets/ART_PROVENANCE.json`, `assets/models/quaternius/PROVENANCE.json` and bundled notices.
