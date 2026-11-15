---
name: Knight comparison baselines
description: Avoid misattributing existing generator changes when reviewing a new Knight asset pass.
---

Compare a candidate against both the original checked-in GLB and an untouched-source rebuild using the same Blender version.

**Why:** The imported baked Knight lagged its generator. Rebuilding unchanged source revealed existing helmet/plume changes that were not part of the subsequent upper-armor pass. Comparing only against the checked-in binary would incorrectly credit those differences to the new work.

**Visual authority:** The owner approved the tracked MysticRun concept sheet for the Knight, Gargoyle and Witch. They explicitly said the characters do not have to be 3D; prioritize matching the illustration over preserving a particular rendering technique.

**How to apply:** Preserve the original binary, rebuild baseline source separately, disclose both baselines and render matched engine views. Check non-target geometry/skin/morph records against the rebuilt-source baseline before claiming they were preserved. Compare all three models with the approved sheet. Do not claim visual acceptance just because technical checks pass; 2D versus 3D representation remains an art-direction choice.
