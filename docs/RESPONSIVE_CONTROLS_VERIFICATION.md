# Verified control corrections (not a visual-quality approval)

The new actual-scene regression initially failed **9 of 11 assertions** against
the published implementation. These were reproduced defects, not subjective
claims about animation polish:

- Opposing up/down intents survived together, producing airborne slide states.
- Small thumb offsets caused drift, and releasing analog input stranded the
  runner between lanes.
- Exact diagonal gestures could vanish instead of resolving on release.

Corrections give the latest vertical intent ownership, add a rescaled 14%
neutral pad deadzone, relinquish analog ownership and settle into the intended
nearest lane on release. A small exact critically damped response replaces
restarting the lateral ease from rest on every lane retarget.

Completed pointer releases are cleaned up even if GUI handling consumes them.
Generation tokens prevent deferred cleanup from deleting a newer touch that
reuses an ID. Gesture recognition still runs through unhandled input, so normal
GUI interactions do not fire gameplay actions.

The authoritative floor state now selects airborne animation. Grounded strikes,
casts and nonfatal hits retain lower-body locomotion instead of stopping the
legs while the road continues moving.

The expanded actual-scene suite passed **237 assertions**, including 30/60/120
Hz response partitioning, release ownership and pose continuity. Existing
navigation (148), gesture/core controls (38) and biome/motion (331) tests passed.
GitHub CI now runs the new suite.

No mapping change: the pad/tilt steer; horizontal playfield swipes attack; up/down
jump/slide. Artwork, save schema, Android package and permanent key are unchanged.
No third-party plugin was added to conceal these input-routing defects. The
architecture experiment separately evaluates rendering and camera alternatives.

These checks establish specific behavior, not premium artistic quality, physical
touch latency or Samsung frame pacing. No APK or automatic main-branch release
is requested by this validation checkpoint.
