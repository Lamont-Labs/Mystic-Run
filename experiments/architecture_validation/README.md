# Bounded MysticRun architecture validation

This is a **playable experiment**, not an approved production rebuild. Normal
startup, menus, assets, saves, package ID and signing credentials are unchanged.
The lab always uses an isolated test profile and never saves owner progress.

## Play the prototype

Use the pinned Godot 4.7.2 editor. Open this project, select
`experiments/architecture_validation/playable.tscn` and press **F6**.

- Arrows: lane changes, jump, slide.
- Space: attack. E: existing character special.
- Existing touch pad, swipe combat and up/down touch gestures remain usable.
- R: switch the *visible* representation between cutout and skeletal.
- Esc: the existing pause flow. Close the window to leave the lab.

For another hero, run the same scene from the command line:

```sh
godot --path . res://experiments/architecture_validation/playable.tscn -- \
  --lab-hero=gargoyle --lab-mode=interactive
```

`--lab-hero=witch` and `--lab-renderer=skeletal` are also supported.

## Reproduce matched evidence

```sh
python3 tools/run_architecture_review.py \
  --godot engine-tools/godot/Godot_v4.7.2-stable_linux.x86_64 \
  --variant prototype --renderer cutout --mode capture \
  --output generated-artifacts/architecture-validation/my-capture
```

Repeat with `--renderer skeletal`, then `--variant baseline`. The baseline is
pinned to the actual published Build 2011 source:
`4a168264d15d06ab751571794a08e006858e6552`.

The tool makes a **read-only Git archive** of that source into the ignored output
directory, copying only the measurement harness into it. It does not substitute
an approximation of the old controller. Existing imported-resource caches are
shared locally to avoid duplicating large assets. Git branches and the source
index are not changed by running a comparison.

Captures use a fixed 30 Hz render clock and identical physics-timed input events.
They are **not FPS benchmarks**. Use `--mode benchmark` separately for uncapped
rendered frame intervals with V-Sync disabled. Benchmarks run sequentially to
avoid local CPU contention. Resolution defaults to 360×640 and can be specified
with `--resolution`. The initial 0.8 seconds are excluded from frame statistics.

Reports contain frame interval mean/p50/p95/p99/worst, injected input-to-simulation
responses, state transitions, airborne/slide conflicts, conservative projected
cutout bounds, damage outcome and a separate 90-call animation CPU microbenchmark.
Neither synthetic CPU measurements nor software-rendered Linux FPS establish
Samsung S23 frame pacing or physical touch latency.

## What is intentionally experimental

- `camera_rig.gd`: a native Godot camera with independently damped position and
  aim, restrained lateral following, constant FOV and more forward visibility.
- `castle_segment.gd`: one repeating 96 m Castle Heights presentation, with
  carved paving, ornamented copings and ground-anchored approved gateway assets.
  No new artwork, collision shapes, encounter rules or full biome development.
- `hero.gd` opt-in switches: evaluate only the representation currently shown.
  Their defaults preserve normal game behavior. Skeletal display height is
  normalized to the cutout before comparison; the underlying GLBs are unchanged.

The comparator changes several prototype systems together. Its end-to-end
timings must not be attributed to a single camera or scenery edit. The isolated
animation microbenchmark specifically investigates hidden-rig sampling overhead.

No engine migration, signed APK build, release publication or merge to main is
part of this validation checkpoint. Evaluate the recordings and playable scene
before authorizing the next production implementation.
