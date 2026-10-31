# Mystic Run 0.3.0: play flow and runner mechanics

The owner rejected the previous game feel and its thin navigation. This revision
addresses the playable flow and specific control defects. It is not a claim that
the game now meets the owner's premium production target.

## Playable screens

Launch opens Home. Persistent tabs open Home, Team, Routes and Records. Team
supports all three starting runners with descriptions of their actual powers.
Routes offers Citadel Breakout (650 m), The Skyward Relay (900 m), Fracture Protocol
(1100 m) and Endless Relay. All three expeditions have finish states and recorded
clears. Route choice and character choice persist. No store, currencies for sale,
locked paid content or simulated online features are included.

Settings, controls and credits have a navigation history and Back behavior.
Pause can resume, open settings/controls and return, or end the run into results.
Results can replay, choose another route or return home. The journal stores actual
runs, best distance, route clears and relics; older best/settings saves remain valid.
A ready countdown prevents accidental input and immediate hazards at launch.

Guided practice observes six real actions: left, right, jump, slide, a successful
hit on a practice sentinel, and the selected character's signature power. Practice
is nonlethal and does not inflate expedition records.

## Control corrections

- Touch and mouse share gesture recognition. Swipes act before release, once per
  gesture; releasing a swipe does not also attack. Short taps in the play area
  strike. Sensitivity changes the normalized swipe deadzone.
- Lane transitions settle over 0.18 seconds instead of an unbounded spring pull.
  Steering remains available in the air and in recovery. Camera follow is damped
  separately from lateral movement; it does not snap to the runner each frame.
- Jump requests have a 120 ms input buffer and short ground/edge grace. Down in
  the air falls into a slide. Crouched authored locomotion replaces the flat-on-back
  slide pose, and characters are scaled closer to the physical capsule.
- A short strike request can wait for a nearby enemy to enter reach. The hit window
  and target cue correspond to that approach; sword/claw attacks remain close-range.
  The Witch has a visible ranged trail. A Gargoyle basic attack no longer forces an
  airborne slam.
- Witch blink chooses a clear neighbouring lane and never offsets the motor forward
  or pulls it backward. Knight charge gives a brief real speed increase.
- Speed ramps into each route and has a route cap. Handoff deadlines follow actual
  approach speed. The fixed-tick core preserves fractional distance without drift.
- Seeded authored encounter phrases replace isolated random props. Relay gates and
  finish lines have clear zones. Fractures cut through the rendered road surface
  rather than being black plates; falling has a brief visible descent and results
  explain the failed obstacle.

## Checks and limits

The existing 427 core assertions remain. New rules check gesture ownership,
speed/distance, route timing, completion, pacing and encounter bounds. Native GUI
checks inject pointer/touch events through Godot hit testing, exercise all screens,
Back paths, actual movement/combat, a finish and practice. Motion checks cover the
three rigs. Rendered captures are inspected for control placement, readable screens,
poses, gameplay and fractures. Seeded longer runs exercise all three starting heroes.

These are desktop/headless and software-rendered checks. Human touch comfort,
physical Android frame pacing and the owner's assessment of game feel remain to be
verified on the phone. Detailed production 3D art, richer environment progression,
more set pieces and timed 90-degree turns remain further work.
