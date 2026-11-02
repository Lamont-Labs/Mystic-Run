# Mystic Run — Android runner

**Current revision: 0.4.0.** Tilt steering, faster pacing, climbs and descents,
one chosen runner for the whole run, a cinematic opening and revised UI.

[Android releases](https://github.com/Lamont-Labs/Mystic-Run/releases) ·
[Current gameplay contract](docs/GAMEPLAY_AND_NAVIGATION.md) ·
[Development status and limits](docs/BUILD_STATUS.md)

Choose Knight, Gargoyle or Witch before starting. Tilt to move, swipe up to jump,
down to slide, tap to strike, and use the runner's signature power. Settings offers
swipe steering, calibration, sensitivity, inversion and reduced camera motion.
The game runs offline; no login or trading functions are involved.

The existing Android package and owner signing certificate are preserved so signed
updates retain local settings and records. Install the signed APK from Releases;
unsigned compilation artifacts require the preserved owner signing key.

This is a development alpha. The owner’s premium gameplay-art target and physical
phone performance are still open review gates.

## Source and verification

Pinned engine: Godot 4.7.2. Open `project.godot` and run `scenes/main.tscn`.

```bash
python3 tools/bootstrap_godot.py --cache ../engine
python3 tools/verify_core.py --godot ../engine/Godot_v4.7.2-stable_linux.x86_64
```

GitHub checks run the core, controls, native navigation, tilt/elevation, rig and
three-character scene suites. Android compilation is separate from signing and
release publication. CI artifacts preserve verification evidence.

## Original art and motion

Character illustrations and distant city art were generated for Mystic Run.
Humanoid source meshes and authored motion are Quaternius CC0; original equipment,
cloth, environment geometry, interface and game systems are in this repository.
See `assets/ART_PROVENANCE.json`, `assets/models/quaternius/PROVENANCE.json`,
`docs/ART_DIRECTION.md` and the bundled licenses.
