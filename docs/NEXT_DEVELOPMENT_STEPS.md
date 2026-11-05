# MysticRun development queue

Lamont Labs · November 5, 2026

Work proceeds one item at a time. Save and verify each checkpoint before beginning the next item.

## Current owner priority

The owner rejected the remaining visual quality on November 5 and requested actual 3D asset generation and acquisition. `ASSET_BATCH_01.md` records five original props, 28 downloaded environment meshes, four rigged outfit assemblies and 20 modular clothing parts, with a standalone Godot review project. These are staged candidates, delivered as an asset ZIP and rebuildable from pinned sources. They have not replaced the current playable cast.

The next task is one visibly stronger Knight benchmark using intentional costume construction, head geometry, armor and materials, followed by motion and chase-camera review. The profiling and phone tasks below remain open and follow that benchmark.

## Completed checkpoints

| Work | Saved source or evidence |
| --- | --- |
| Free KayKit scenery, local import registry and bounded district pool | `19105d494285ca760b753a3e675198eb63921249` |
| Knight shape and action expressions | `90fcdc37eb4e6df392a296b32221ab59a4b54c6f` |
| Distinct Gargoyle with weighted wings and crouch | `2e4606d6ae24941d8d825408eb3a815d59621863` |
| Distinct Witch with facial morphs, braid and casting staff | `dbbbb65100742c238e9b2055d88b6f6cb978c9d1` |
| Gargoyle curved exterior surfaces and geometric regression check | `GARGOYLE_SURFACE_REFINEMENT.md` and its checkpoint commit |
| Character material and surface finish | `67bbd5cef7d60952730e143b9a4f3ebe86c333c4` and `MATERIAL_FINISH_REFINEMENT.md` |
| Separately installed Art Preview 0.6.2 / build 1017 | Verified APK and source identity in `ART_PREVIEW_BUILD.md` |
| Original signing identity recovered and owner-update build 1023 published | `ANDROID_UPDATE_IDENTITY.md`, matching original certificate, verified GitHub APK |

The code, generators, rights records, model hashes and actual engine review frames are in draft PR #5 on `quality/free-asset-foundry`. The original-game owner update is now build 1023. Development validation is not final art approval or Google Play readiness.

## Next code work

1. **Mobile profiling and LOD decision.** Use a representative Android performance capture to identify skinning, shader, fill-rate and scene costs before choosing reductions. Any LOD must retain silhouette, facial behavior, staff/wing clearance and character-specific motion. Lower visual quality already reduces scenery visibility; hero LODs are not implemented or certified. The current source budgets remain Knight 24,328, Gargoyle 22,722 and Witch 27,854 triangles, each with one main imported surface; these are budgets, not measured phone frame rates.
2. **Original-game update validation on a physical phone.** Install owner-signed build 1023 over the existing game and verify saved settings/records, cold start, pause/resume, touch/tilt controls and character selection. The package/certificate/version and save-format checks passed locally; an actual phone upgrade test remains open.

The separately installed **Mystic Run Art Preview** delivers the new material checkpoint without replacing the existing game or its save data. Its explicit package variant and verification are documented in `MATERIAL_FINISH_REFINEMENT.md` and `ART_PREVIEW_BUILD.md`. The original owner-update signing gate is now closed by build 1023. The original private key was recovered from the legacy `Relic_Relay_Development_Signing_Backup.zip`; normal updates must retain that identity.

## Device work still required

A physical Android phone is needed for sustained frame pacing, thermal behavior, touch/tilt comfort, screen insets, resume/restart and a real upgrade-install check. No phone is attached to this workspace. Production Play identity, store materials, privacy declarations and release-track testing remain separate readiness work in `GOOGLE_PLAY_READINESS.md`.

All current source assets and authoring tools are free to use in this development path. Continue with the existing admitted assets and original derivatives; no paid pack, new external account or engine migration is needed for the next code step.
