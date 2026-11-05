# MR-ART-012 — Actual Godot A/B comparison

Date: 2026-11-05
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Compared artifacts
- Previous: GitHub Actions run https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42088242210 (artifact `13443682344`)
- Revised: GitHub Actions run https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42089018995 (artifact `13443129573`)
- Revised source: `369047c58a4c56a0e9fdd0413f8d03f215cc7327`
- Captures: actual Godot stage `knight-front.png`, `knight-rear.png`, `knight-side.png`, `knight-face-neutral.png` and seeded chase frame `knight-benchmark-0040.png`
- Original identity authority: `references/01-character-concept.png`; no substituted generated reference

## Evidence
- Revised GLB SHA-256: `a4ae7f71a0e689d0fcd23173ff56061dac43d5c882c218639001bbc173cec2e5`
- Revised GLB: 1,670,392 bytes, 24,448 triangles, one skin, six morph targets
- Workflow outcome: success, including Blender rebuild, structural validation, Godot import, rig/expression tests, and stage/chase capture
- Seeded 100-frame chase: Knight preserved, zero handoffs, zero damage, 62.224 m. Desktop scripted test only; not an Android performance measurement.

## Visual findings
- Front: open face preserved; crown slightly lower; plume still reads as a compact hook rather than an extended flowing crest.
- Rear: red crest remains visible above the dome; cape still dominates the rear silhouette.
- Side: plume is flatter and more horizontal, extending farther backward; this is the clearest localized improvement.
- Face: blue helmet is still rounded; youthful face, large bright eyes and simplified forehead opening remain largely unchanged.
- Whole figure: spherical pauldrons, tubular lower armor, simple shield and flat triangular cape remain well below the original hand-drawn concept fidelity.
- Still frames do not establish dynamic clipping clearance, physical Android performance, or owner art approval.

## Gate decision
**Do not promote the revised GLB to the runtime branch, merge, or release an APK.** MR-ART-011 is a technically validated but visually insufficient refinement. The geometry change is retained in source on the art branch for auditability.

## Next task
MR-ART-013 should change the strategy from minor numeric adjustments to a deliberate sculptural silhouette pass. Start with **helmet shell/face aperture** as one bounded component: reshape the dome into a visibly structured steel-blue helmet with an intentional forehead brow and side contours, while preserving the 65-bone rig and six morph contracts. Then rebuild and compare actual Godot renders before changing shoulders, cape, face, or shield. Do not combine unrelated art changes into one unreviewable commit.
