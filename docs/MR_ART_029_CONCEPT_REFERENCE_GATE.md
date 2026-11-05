# MR-ART-029 — Concept-fidelity evidence gate

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Decision: **REFERENCE BLOCKED / VISUAL HOLD**

## Verified evidence
- `references/01-character-concept.png` was requested from GitHub on the active branch using `fetch_file` with base64 encoding.
- GitHub returned 404 NOT_FOUND. The referenced file is therefore not retrievable at that path on the active branch.
- A repository code search for `character-concept` returned no matching results on the default branch. This is not proof that no reference exists elsewhere.
- Existing actual Godot screenshot evidence is retained in the MR-ART-026 and MR-ART-028 reviews.
- Prior rebuilt Knight has 23,810 triangles, 65 bones and six morphs; the latest review marked TECHNICAL PASS / VISUAL HOLD.

## Design acceptance gate
The user requires a detailed, playful, hand-drawn cartoon fantasy Knight, not a simplified blocky/toy-like model or heavily anime-influenced design. No exact geometry/color fidelity can be certified without the intended concept image.

## Required next action
1. Locate the actual approved concept-sheet image in project attachments or a different repository path, or add the approved image to a tracked reference path.
2. Capture the original concept and actual Godot front, side and gameplay renders at matched sizes.
3. Record silhouette, helmet, face, pauldron, torso, boot, cape and material differences.
4. Choose the highest-impact single visual subsystem for redesign; maintain rig, morphs, gameplay and Android performance gates.
5. Rebuild and compare before/after. Do not mark visual pass or publish APK until independently reviewed.

## Change scope
This task records an evidence blocker; it does not change gameplay, model geometry or release artifacts. Prior geometry tweaks are preserved.
