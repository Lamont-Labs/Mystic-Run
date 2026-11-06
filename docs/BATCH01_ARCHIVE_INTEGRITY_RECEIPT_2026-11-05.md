# MysticRun Batch01 — handoff archive integrity receipt

Verification date: 2026-11-05 (project local date)  
Source: `MysticRun_Next_Chat_Handoff_2026-11-05.zip` → `asset_batch/MysticRun_3D_Assets_Batch01_2026-11-05.zip`  
Method: read-only inspection of nested ZIP, manifest-to-asset SHA-256 comparison, GLB magic check.

| Category | Assets | SHA-256 verified |
| --- | ---: | ---: |
| Lamont Labs original models | 5 | 5 |
| Quaternius outfit models | 24 | 24 |
| KayKit environment models | 28 | 28 |
| **Total** | **57** | **57** |

- Total GLB payload: **54,941,692 bytes**.
- Unknown/unpinned models: **0**.
- SHA-256 mismatches: **0**.
- Invalid GLB magic values: **0**.
- Verified using the archived `original-assets.json`, `outfit-assets.json`, and `kaykit-dungeon.lock.json` files.
- This is a **source archive integrity** receipt, **not** evidence of Godot import, runtime visual quality, asset placement, or Android release readiness.
- The two scenery assets already committed to the branch have separate passing Godot integration evidence. The remaining archived models must still be staged and reviewed.
- Existing Android signing identity and package ID are unchanged.

**Release gate:** PR #8 remains unmerged until asset import and gameplay CI can execute successfully. Runner-allocation failure tracked by Issue #9.
