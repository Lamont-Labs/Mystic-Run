# Mystic Run — Android runner

**Current revision: 0.5.0.** A direct opening-to-run flow, the playable 3D runner in the menu, an Endless default for new profiles, integrated first-run lessons, earlier combat preparation, a smaller HUD and five authored architecture variants.

[Android releases](https://github.com/Lamont-Labs/Mystic-Run/releases) · [Gameplay contract](docs/GAMEPLAY_AND_NAVIGATION.md) · [Build status](docs/BUILD_STATUS.md)

Choose Knight, Gargoyle or Witch before starting. Tilt to steer continuously, swipe up to jump, down to slide, tap to strike, and use the selected runner’s power. One character stays with you through climbs, bridges and descents. Existing runner choices, mode choices, settings and records are loaded; a new profile begins with Endless.

The opening is the main menu. Press Run directly, change a runner without choosing a course again, or select an optional finite expedition through Modes. The first Endless run teaches controls in a protected stretch and continues into the same run. Lessons survive retries and saves. Skip is remembered separately from completed practice. Guided practice remains under Settings → How to Play.

The game works offline. Its Android package and preserved owner signing certificate support installation over the existing development build.

This is a development alpha. The premium production-art target remains open, and desktop verification does not establish physical Android sensor behavior or sustained phone performance.

## Develop and verify

Pinned engine: Godot 4.7.2. Open `project.godot` and run `scenes/main.tscn`.

```bash
python3 tools/bootstrap_godot.py --cache ../engine
python3 tools/verify_core.py --godot ../engine/Godot_v4.7.2-stable_linux.x86_64
```

GitHub checks cover the core, gestures, native navigation, tilt/elevation, animation and three-character scene runs. Android compilation and owner signing are separate. Check the APK’s manifest for its exact compilation source and signature evidence.

## Art and motion

Character illustrations and distant city art were generated for Mystic Run. Humanoid source meshes and authored motion are Quaternius CC0. Custom equipment, cloth, architecture, interface, game systems and synthesized audio are in this repository. Version 0.5.0 corrects clockwise surface winding for custom geometry, which previously let the black outline pass cover armor and scenery.

See `assets/ART_PROVENANCE.json`, `assets/models/quaternius/PROVENANCE.json`, `docs/ART_DIRECTION.md` and the bundled licenses.
