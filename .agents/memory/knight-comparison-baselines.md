---
name: Knight comparison baselines
description: Avoid misattributing existing generator changes when reviewing a new Knight asset pass.
---

Compare a candidate against both the original checked-in GLB and an untouched-source rebuild using the same Blender version.

**Why:** The imported baked Knight lagged its generator. Rebuilding unchanged source revealed existing helmet/plume changes that were not part of the subsequent upper-armor pass. Comparing only against the checked-in binary would incorrectly credit those differences to the new work.

**How to apply:** Preserve the original binary, rebuild baseline source separately, disclose both baselines and render matched engine views. Check non-target geometry/skin/morph records against the rebuilt-source baseline before claiming they were preserved.
