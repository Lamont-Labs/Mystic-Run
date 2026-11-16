---
name: Architecture evaluation gate
description: Owner-required evaluation before any further broad gameplay or environment rebuild.
---

Do not proceed with a full three-biome rebuild or other large-scale development
until the owner has evaluated the bounded gameplay architecture prototype.
Keep verified control repairs separate from experimental presentation work.
No engine migration is authorized.

**Why:** The owner reported that the released game remained clunky, buggy and
generic despite passing automated checks, and explicitly required playable
before/after evidence before authorizing more broad development.

**How to apply:** Present actual matched gameplay, measured results and remaining
defects. A successful build or test count is not artistic or gameplay acceptance.
Keep main and the installed Android identity intact while experiments are
evaluated. Recommendations in an agent report do not constitute owner approval.

The owner authorized one concept-faithful, rigged 2D Knight as the next bounded
experiment. This does not authorize applying the rig to every character or
resuming the full environment rebuild.

**Why:** The owner explicitly selected the single-Knight experiment after the
architecture comparison.

**How to apply:** Keep this work experimental and present actual gameplay for
review before expanding its scope or integrating it into a phone release.

The owner subsequently said: "Find a better game engine. This isnt working."
Do not treat the earlier single-Knight approval as authorization for further
Godot rig iterations. Preserve the experiment while evaluating replacements.
No full replacement-engine migration has been approved.

**Why:** The owner rejected continuing the current direction and requested an
engine alternative.

**How to apply:** Separate engine research from migration authorization. Verify
licensing and unattended Android build feasibility before committing to a port;
retain the permanent Android identity and explicitly handle save compatibility.

The owner approved preparing a **separate Unity prototype**, with licensing and
no-paid-services build feasibility checked first. This is not approval to
replace the Godot project, purchase Unity services, publish an experimental APK,
or discard the existing artwork and saves.

**Why:** The owner selected "Prepare a Unity prototype" after receiving the
licensing and activation caveats.

**How to apply:** Keep the Unity evaluation isolated. If no activated editor is
available, preserve prepared source and report that blocker; do not represent
portable C# tests as Unity compilation, rendered gameplay or an Android build.

The owner approved an isolated Defold Android build-feasibility test, not a game
port, replacement of the existing projects, or a signed experimental APK.

**Why:** The owner selected "Verify Defold builds first" after receiving the
editor-free build proposal and its no-signing/no-publishing scope.

**How to apply:** Keep compilation feasibility separate from rendered gameplay,
Android execution and update compatibility. Defold's Android `bundle` command
automatically generates a debug keystore when none is supplied; do not invoke it
in unsigned probes. Android resource compilation and non-Android headless builds
avoid that path. Any later APK must use the existing trusted signing pipeline.

After the compilation proof, the owner approved **one playable Defold Knight
prototype**. This supersedes the earlier compilation-only scope, but not the
requirement to evaluate a bounded prototype before a full engine migration.

**Why:** The owner selected "Build one Knight prototype."

**How to apply:** Deliver actual rendered movement and controls for review.
Do not expand to every hero, rebuild all biomes, merge a full port into main or
publish a signed Android experiment under this approval.

Defold 1.14 uses typed configuration getters such as `sys.get_config_int`;
the historical `sys.get_config` API is absent at runtime. A successful Bob
resource compile does not catch this kind of Lua API error.

**Why:** A compiled prototype failed initialization until tested in the engine.

**How to apply:** Check the pinned engine's current API and execute a bounded
runtime smoke test; retain timeout output so initialization failures are visible.

Measure prototype frame throughput using frame-count differences divided by
wall-clock time, not only the engine-reported `dt` averages.

**Why:** Defold reported a capped frame delta even when observed browser update
throughput was lower. Engine-time statistics overstated real playback speed.

**How to apply:** Label software-rendered browser results explicitly; do not
equate passing controls or apparently stable `dt` with Android frame stability.
