# MR-ART-017 — Knight pauldron verification

Date: 2026-11-05
Branch: `art/asset-upgrade-batch-01`
Source commit: `b51aafa06d27996072357a56843abd7d23366ab9`
Decision: **TECHNICAL PASS / VISUAL HOLD**

## Reproducible build evidence
- Knight rebuild: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42092460196 — completed successfully
- Gameplay core: https://github.com/Lamont-Labs/Mystic-Run/actions/runs/42092459924 — completed successfully
- Rebuild artifact `knight-rebuild-review`: ID `13446785284`
- Generated GLB SHA256: `0ca7e0b625b8b75316ae4b6c1be3b70596c3805eed336d373a38d77d8606a07b`
- GLB bytes: 1,639,684
- GLB structural validation: pass; one mesh, one skin; six morph targets
- Triangles: **23,810** / 25,000 maximum; 1,190 under limit
- 65-bone source rig retained; six authored morphs retained
- Desktop seeded chase benchmark: 100 frames, 62.224 meters, 0 damage, 0 handoffs, selected Knight retained. Not Android device performance evidence.

## Actual render review
Directly inspected four generated Godot images: `knight-front.png`, `knight-side.png`, `knight-rear.png`, and `knight-face-neutral.png`.

- Front: shoulders now form more compact tapered plate shapes with a visible metallic rim. They are less exaggerated than the earlier round pauldrons.
- Side: shoulder volume is reduced, but the silhouette remains simplified and round at normal viewing scale.
- Rear: star cape is legible but remains a flat tapered plane with straight borders.
- Face: youthful clean-shaven face and star chest plate remain; eyes and helmet still appear toy-like relative to the original reference.
- Whole-character conclusion: pauldron change improves geometry, but overall art style still falls short of `references/01-character-concept.png`. There is no evidence of final owner visual approval.

## Release gate
Keep the source change as a verified art-branch checkpoint. **Do not promote the generated GLB to the runtime, merge the art branch, or release an APK** on this basis. No physical Android test has occurred.

## Next scoped task
MR-ART-018: replace the rigid, flat triangular Knight cape with a layered, curved, flowing silhouette that preserves the gold star and the existing skin/motion contracts. Rebuild and compare actual Godot captures; remain under the 25,000-triangle budget.
