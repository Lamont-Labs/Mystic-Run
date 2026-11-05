# MysticRun development queue

Lamont Labs · November 4, 2026

Work proceeds one item at a time. Save and verify each checkpoint before beginning the next item.

## Completed checkpoints

| Work | Saved source or evidence |
| --- | --- |
| Free KayKit scenery, local import registry and bounded district pool | `19105d494285ca760b753a3e675198eb63921249` |
| Knight shape and action expressions | `90fcdc37eb4e6df392a296b32221ab59a4b54c6f` |
| Distinct Gargoyle with weighted wings and crouch | `2e4606d6ae24941d8d825408eb3a815d59621863` |
| Distinct Witch with facial morphs, braid and casting staff | `dbbbb65100742c238e9b2055d88b6f6cb978c9d1` |
| Gargoyle curved exterior surfaces and geometric regression check | `GARGOYLE_SURFACE_REFINEMENT.md` and its checkpoint commit |

The code, generators, rights records, model hashes and actual engine review frames are in draft PR #5 on `quality/free-asset-foundry`. The published installable release remains build 1016. Development validation is not final art approval or Google Play readiness.

## Next code work

1. **Material and character-detail refinement.** Compare the three imported actors against the established detailed cartoon direction in the fixed front/rear/face stage and chase camera. Improve readable costume/stone/hair surface definition and lighting. Keep source rights and derivative hashes current. Check actual engine images before saving. The current source budgets are Knight 24,328, Gargoyle 22,722 and Witch 27,854 triangles, each with one main imported surface; these are budgets, not measured phone frame rates.
2. **Mobile profiling and LOD decision.** Use a representative Android performance capture to identify skinning, shader, fill-rate and scene costs before choosing reductions. Any LOD must retain silhouette, facial behavior, staff/wing clearance and character-specific motion. Lower visual quality already reduces scenery visibility; hero LODs are not implemented or certified.
3. **Owner-signed preview build.** Compile the reviewed source, preserve the existing owner signing identity, assign the next development version code and verify package contents/signature/alignment. Publish or distribute only the concrete reviewed build through the authorized release path. An unsigned CI compile is not an installable owner-signed release.

## Device work still required

A physical Android phone is needed for sustained frame pacing, thermal behavior, touch/tilt comfort, screen insets, resume/restart and a real upgrade-install check. No phone is attached to this workspace. Production Play identity, store materials, privacy declarations and release-track testing remain separate readiness work in `GOOGLE_PLAY_READINESS.md`.

All current source assets and authoring tools are free to use in this development path. Continue with the existing admitted assets and original derivatives; no paid pack, new external account or engine migration is needed for the next code step.
