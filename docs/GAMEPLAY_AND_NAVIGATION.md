# Mystic Run 0.4.0 — movement and interface overhaul

November 2, 2026 · Lamont Labs

The owner's current direction supersedes the original relay design: tilt to steer,
a faster run, climbs and descents, one chosen character for the entire run, a
proper opening screen, and an overhaul of gameplay presentation and navigation.

## Controls and run identity

- Portrait gravity input controls a continuous lateral target across the path.
- A three-second ready countdown samples the comfortable holding angle.
- The filter uses a 1.8-degree deadzone, exponential smoothing and bounded travel.
  Low, Normal and High sensitivity require progressively less phone roll.
- Pause offers Recenter Tilt; continuing recalibrates through a short countdown.
- Invert Tilt, swipe steering and reduced camera motion are available in Settings.
- Missing or invalid gravity readings fall back to accelerometer readings. If
  neither sensor provides usable readings, steering falls back to swipes with
  an explicit message; stale motion input decays toward neutral.
- Swipe up to jump, down to slide, tap to strike, and use the signature power.
- Knight, Gargoyle or Witch is chosen before starting. The live session locks
  that character, rejects relay offers, and never spawns character handoff gates.
  Legacy handoff core tests remain regression coverage for historical interfaces.

## Pacing and elevation

| Course | Initial pace | Ceiling | Length |
| --- | --- | --- | --- |
| Citadel Breakout | 18 m/s | 22 m/s | 650 m |
| Skyward Escape | 19 m/s | 24 m/s | 900 m |
| Fracture Protocol | 20 m/s | 24 m/s | 1,100 m |
| Endless Run | 18.5 m/s | 24 m/s | Endless |
| Guided Practice | 6 m/s | 6 m/s | Control-driven |

The former 7 m/s opening ramp is removed. Normal courses gain speed with distance;
uphill and downhill grades adjust pace inside a 17–24 m/s global envelope.
Practice retains a gentle pace while teaching the inputs.

A continuous 640 m elevation profile includes an 11 m crown bridge, a descent
into a -6 m valley, a second 7 m crest and another descent. The runner's world
height, support surface, camera, props and rendered road use the same distance
origin. Grade-aware camera aiming and character pitch make rises and drops visible.
The gameplay motor remains at a fixed local forward origin while scenery scrolls;
the support plane follows the local course height. Gaps and obstacles retain the
explicit contact-envelope model; this is not a general terrain-physics sandbox.

## Screens and presentation

Opening → Play hub → choose runner/course → ready countdown → run → results.
Persistent Play, Runners, Courses and Journal navigation provides the main menu.
Home starts the selected course directly. Pause preserves nested settings/controls
history and offers Continue, Recenter and End Run.

The opening uses the existing original city artwork, large fantasy typography,
a clear Enter the City action and animated motes. Home foregrounds the chosen
runner. Gameplay uses a smaller HUD with health, distance, section, progress,
pace, steering status and two combat controls. Course labels describe ascent,
bridge, descent and valley sections instead of teammate changes.

The rendered world adds patterned weathered paving, structural bridge supports,
lanterns and layered 3D architecture in front of the distant painted city. Character
surfaces use lighting and specular response; embroidered cloth has restrained wind
motion. Character lights follow the course elevation, and the camera frames the
runner more closely. These are rendered scene changes, not a replacement title
image presented as gameplay.

## Evidence and limits

The automated suites check session rules, gestures, navigation, animation,
synthetic motion samples, sensor loss, recentering, frame-rate independence,
course continuity, surface alignment and single-character enforcement. Rendered
frames use the actual Godot scene with a disclosed automated driver.

Physical Android tilt orientation, control comfort, performance, thermal behavior
and final visual approval remain device checks. The current characters and
procedural environment still need further authored art work to meet the owner's
premium production target. This revision does not claim Marvel Snap-level art.
