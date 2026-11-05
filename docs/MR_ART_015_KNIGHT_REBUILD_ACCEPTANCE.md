# MR-ART-015 — Rebuilt Knight visual and technical acceptance

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Source commit: `35fae9fafc6e30b134d91e7145cb09ab43045b2c`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Verified automation
- Knight rebuild workflow: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42091288204 — success
- Gameplay core workflow: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42091288262 — success
- Review artifact: `knight-rebuild-review`, ID `13445117375`
- Generated GLB SHA-256: `de0b92ced029b5a6350bd6078dd0a9a41014f405391b4aa0f2a071d1bccd9f93`
- Generated GLB size: 1,685,524 bytes
- Structural validation: GLB_STRUCTURAL_PASS; 1 mesh, 1 skin, six morph targets
- Geometry: **24,642 triangles**, below the 25,000-triangle ceiling by 358
- Skeleton: existing 65-bone contract preserved; Blink, PlumeSway, Smile, Focus, Surprised, Hurt retained
- Godot import, rig/motion and expression tests, turnaround capture and seeded chase capture completed successfully
- Chase evidence: seed 73129; 100 frames; 62.224 m; zero damage; zero character handoffs. Desktop automated controls only; not phone FPS or human playability.

## Direct visual inspection of actual Godot PNGs
Inspected `knight-front.png`, `knight-side.png`, `knight-rear.png`, and `knight-face-neutral.png` from the successful artifact.

- Front: revised brow and steel-blue crown detailing visibly appear; open-face identity and shield star remain.
- Side: red plume has a long rearward sweep. Crown is still visually rounded, not a sufficiently distinctive forged/faceted helmet.
- Rear: gold-star red cape reads clearly, but remains a flat geometric taper.
- Face: youthful clean-shaven face, brown hair, blue eyes retained. Large rounded shoulder armor and simplified face proportions still diverge from the illustrated concept.
- Remaining gap: character reads as a polished low-poly toy figure, rather than a textured hand-drawn fantasy hero; the helmet change alone does not resolve that overall fidelity gap.

## Gate
Keep the source revision as a verified checkpoint. **Do not commit the generated GLB into the shipping asset path, merge to main, or publish an APK based on this review.** The owner has not approved visual fidelity. No Android physical-device test was performed.

## Next scoped work
MR-ART-016: address the Knight's exaggerated spherical pauldrons and upper-torso silhouette as a single source-geometry task, retaining the 65-bone and six-morph contracts, the under-25,000-triangle budget, and the current render comparison pipeline. Rebuild and inspect actual captures before any other art component change.
