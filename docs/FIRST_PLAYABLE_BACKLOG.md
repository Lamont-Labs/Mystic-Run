# First Playable — Ordered Implementation Backlog

Lamont Labs · October 30, 2026

This backlog starts from the delivered, tested session core. It describes work still required to produce an Android playable. Task completion requires the listed evidence, not only a source commit. No task below is represented as already completed unless it explicitly refers to the delivered foundation.

## Execution rules

- Preserve the owner-confirmed identity: forward-moving 3D endless runner; dark fantasy plus futuristic world; Knight, Gargoyle and Witch; running combat; separate teammates with route-driven handoffs.
- Use the confirmed trio immediately in the content plan. Build and verify one movement/asset pipeline before replicating it across the three rigs.
- Keep `RunCore` as the owner of shared run state. Scene components submit intents or validated outcomes.
- Distinguish source-only verification, real scene verification, APK verification and phone verification in every report.
- Keep the Godot 4.7.2 editor and matching export templates pinned. Reassess an upgrade as its own bounded change.
- Run the relevant existing checks after a behavior change. Add a regression case when it proves a real failure boundary.
- Keep secrets and paid asset bytes out of public commits. Do not buy assets or publish a store listing as part of a code task.

## Work package 1 — Establish an executable Android path

### DEV-001 — Repository and build identity

**Depends on:** A dedicated repository URL and working access.

**Work:** Import this source directory, preserve its documents and check workflow, select the initial development branch, and record the source revision. Verify the connector can write workflow files. Choose a stable development package identity before repeated phone installations.

**Accept:** A remote commit exists; the core workflow actually runs; its artifact contains a zero-failure report tied to the same source. If workflow-file writes fail, report that exact permission boundary rather than claiming CI is installed.

### DEV-002 — Canonical runner motor

**Depends on:** DEV-001 or the same local source state while remote access is being resolved.

**Work:** Add a real `CharacterBody3D` motor, path-relative travel, three alignment anchors, jump/slide behavior, collision clearance and chunk-local position tracking. Drive logical state at the fixed simulation tick. Use one authoritative gameplay collision and presentation rigs with inactive background collision.

**Accept:** Movement remains consistent across repeated starts, pause/resume, varying render rates and the intended speed range. Record jump envelope, slide clearance and lateral-change timing. No scene script independently modifies team health or score.

### DEV-003 — Touch router and camera comparison

**Depends on:** DEV-002.

**Work:** Add pointer-owned gesture recognition, Attack/Power intents, held-state cancellation and a camera following the route frame. Make a contained portrait/landscape comparison using identical gameplay conditions.

**Accept:** Simultaneous thumbs do not convert button taps into route changes. One swipe produces one intended action. Backgrounding clears touches. The next obstacle remains visible during jumps, slides and a test handoff. Owner feedback selects a production orientation.

### DEV-004 — Android export and persistent signing

**Depends on:** DEV-002, DEV-003, matching export templates and an owner-controlled development signing identity.

**Work:** Configure the actual gameplay main scene, Android export preset, package identity, versioning, arm64 target after ABI confirmation and consistently signed development output. Keep private key material outside source. Export from a documented local or CI toolchain.

**Accept:** An APK exists, its signature verifies, package/architecture/version metadata is inspected, and it installs and launches on the owner's phone. Rebuild with a higher version code and demonstrate an update over the installed development app. Preserve the certificate fingerprint and APK SHA-256.

**Scope boundary:** This is installation and movement proof. Its visual acceptance status must remain separate.

## Work package 2 — Establish the visual and combat baseline

### DEV-005 — Asset source and import contract

**Depends on:** A chosen production art direction and an asset source with appropriate rights.

**Work:** Import a real Knight model with its skeleton, material set, sockets and required locomotion animations. Retain source information and license evidence. Establish scale, forward axis, texture limits and LOD conventions.

**Accept:** The model deforms correctly through running, dodging, jumping, sliding and attack. Weapon attachment is stable; the physical capsule is unchanged by art import. The character is readable at gameplay distance on the phone.

### DEV-006 — Cathedral environment slice

**Depends on:** DEV-005 for scale reference.

**Work:** Build an authored approach from a coherent architectural kit with deliberate collision, lighting and route sight lines. Integrate one memorable machine/supernatural event inside a safe portion of the course.

**Accept:** A recorded moving phone build establishes the intended art quality. Decorative geometry does not snag movement. The same build has a performance capture identifying settings and frame times. No editor-only image is used as proof of device presentation.

### DEV-007 — Spatial combat resolver

**Depends on:** DEV-002, DEV-005.

**Work:** Connect attack intent to animation active windows and spatial proof. Add lane/corridor selection, range, line-of-sight checks and vulnerability states. Register enemies with `RunCore`, resolve a reward once and retire pooled registrations correctly.

**Accept:** Out-of-range attacks do not reward, blocked targets cannot be hit through a wall, duplicate callbacks cannot reward twice, and stale outgoing tokens cannot hit after a handoff. A valid hit produces visible/audio feedback on the expected frame.

### DEV-008 — First enemy and damage loop

**Depends on:** DEV-007.

**Work:** Add the ground guard's wind-up, threat, recovery, hit reaction and defeat behavior. Connect validated damage to team health. Add failure, results and a cached restart path.

**Accept:** Each normal encounter has a legal attack or movement solution. A single overlap cannot consume repeated health within the grace window. The player can fail and restart repeatedly without retained enemy state or leaked registrations.

### DEV-009 — Alternate threat and power behavior

**Depends on:** DEV-008.

**Work:** Add one alternative threat, plus the Knight's bounded charge behavior and breakable-obstacle contract. Charge visuals and gameplay protection share the same accepted start/end state.

**Accept:** Powers stop at the defined endpoint, retain cooldown across later swaps, and do not make gaps or unbreakable structures silently harmless. Enemy/projectile pools reset cleanly.

## Work package 3 — Prove the three-character relay

### DEV-010 — Gargoyle presentation and movement

**Depends on:** The asset import contract and common motor.

**Work:** Import the Gargoyle rig, implement claw attack and bounded wing-burst/glide behavior, and stage takeoff, landing and wing folding. Preserve shared button positions and baseline movement.

**Accept:** The character fits advertised route clearances; the glide stays inside its authored envelope; a legal basic path exists while the power recharges. Landing restores the correct collision and animation state.

### DEV-011 — Witch presentation and spatial power

**Depends on:** The asset import contract and spatial combat resolver.

**Work:** Import the Witch, implement directed spell attacks and authored-anchor blink. Validate endpoint clearance before accepting an anchor. Preserve a playable physical continuation when blink is unavailable.

**Accept:** Spells respect the intended corridor and line of sight. Blink cannot end inside solid geometry or outside the supported route. Failed endpoint validation leaves the player in a predictable valid state and does not consume a power without an explicit policy.

### DEV-012 — Route marker integration

**Depends on:** DEV-003, DEV-010, DEV-011.

**Work:** Connect actual spatial markers to offer/commit/boundary events. Use recognizable emblems and terrain previews. Compute warning and safe-corridor requirements using the validated maximum speed.

**Accept:** Each route destination is visible before commitment. Ignoring a branch preserves the active character. Choosing the current character's route does not create a handoff or protection refresh. Missing next-section content is handled before commitment.

### DEV-013 — Handoff ownership integration

**Depends on:** DEV-012.

**Work:** Stage incoming/outgoing teammate rigs, transfer active presentation at the session's ownership boundary, and retire combat callbacks. Preserve shared health, score, distance, camera frame and separate cooldowns.

**Accept:** There is one gameplay collision and input owner throughout. No duplicate body can receive damage or collect rewards. Held attack inputs are cleared. An interrupted handoff resumes once and completes once.

### DEV-014 — Six directed handoffs

**Depends on:** DEV-013.

**Work:** Author Knight→Gargoyle, Knight→Witch, Gargoyle→Knight, Gargoyle→Witch, Witch→Knight and Witch→Gargoyle staging. Reuse compatible clips while preserving each character's identity.

**Accept:** Capture each case in the actual device build, including a cooling-down incoming power. Recovery framing and the first encounter remain readable. All same-character continuations are also tested.

### DEV-015 — Complete short district loop

**Depends on:** DEV-014.

**Work:** Join starting selection, authored approach, a route choice, a handoff, a character-specific encounter, rejoin, failure/results and restart into a complete repeatable loop.

**Accept:** The owner can start as each teammate and complete each branch. The loop has no debug-only menu dependency, missing required asset, unavoidable unavailable-power action or unexplained dead end.

## Work package 4 — Make the loop endless and dependable

### DEV-016 — Chunk connectors and reachability

**Depends on:** DEV-015.

**Work:** Define entry/exit frames, lane connectivity, supported character states, movement requirements, recovery windows and speed limits. Validate individual chunks and adjacent transitions.

**Accept:** Invalid combinations are rejected before play. Representative paths pass actual collision tests. Include edge cases such as a jump near a seam and an immediate following low obstacle.

### DEV-017 — Seeded director and pools

**Depends on:** DEV-016.

**Work:** Add reproducible sequence selection within the pinned engine/content version, bounded look-ahead, enemy/effect/chunk pools and local-origin management. Record seed and content revision with the run.

**Accept:** Repeating a seed produces the same selected sequence under the defined version. Long sessions preserve memory budgets. Rebase and pool reuse do not alter active collision, camera framing or reward identity.

### DEV-018 — Profile persistence and interruption handling

**Depends on:** A stable loop and application identity.

**Work:** Implement versioned settings, personal bests, character mastery records, atomic writes, backup recovery and an explicit foreground-resume flow. Keep arbitrary live-run restore outside scope until a complete safe-checkpoint design is implemented.

**Accept:** Corrupted or interrupted profile writes recover predictably. Backgrounding and lock/unlock freeze play and clear touch capture. Updating the installed signed app retains settings and records.

### DEV-019 — Quality profiles and sustained phone review

**Depends on:** DEV-017, DEV-018.

**Work:** Implement measured graphics profiles, reduced effects and motion, audio settings and control adjustments. Capture a sustained stress run on the reference phone.

**Accept:** Report frame-time distribution, memory behavior, thermal observations and visible quality for the same build. Essential enemy and route cues survive every supported quality setting. Any remaining failures are listed with reproduction steps.

### DEV-020 — Owner alpha package

**Depends on:** The applicable earlier acceptance gates.

**Work:** Produce the consistently signed APK, source revision, checksums, certificate fingerprint, content identity, test report, known issue list and short gameplay walkthrough. Preserve the source and editable-art references needed for another developer to continue.

**Accept:** The owner installs or updates the APK, completes the agreed flow and can reproduce a reported issue using the same build identity. The report distinguishes implemented behavior, measured results and remaining targets.

## Next bounded implementation task

The immediate task is DEV-002 alongside establishing DEV-001: connect the already-tested session rules to a real runner motor and camera, then reach DEV-004 early enough to test on the phone before large-scale content production. Production hero/environment assets enter through DEV-005 and DEV-006; the art quality gate remains explicit rather than being implied by a successful export.
