# Fluid movement and living-world gameplay milestone

## Playable changes

- Gargoyle cutout height changed from 2.48 to 1.59 world units: a 35.9% reduction.
  Collision dimensions and gameplay hit rules remain shared with the other heroes.
- All three heroes render through a 28×32 subdivided cutout mesh. Smooth weighted
  hip, knee and shoulder articulation is continuous, with secondary cloth/wing
  motion, attack follow-through, airborne tuck and damage recoil. Approved
  character images remain the visual source; original rigs and assets are retained.
- This is procedural articulated 2D animation, **not** twelve newly drawn raster
  frames. Initial AI-generated twelve-cell sheets repeated poses and were rejected.
- Existing distinct action images now have premultiplied-alpha 100 ms pose blends.
  Reduced Motion disables articulation and transitions. Running bob is smaller;
  lane movement uses a quintic ease with zero endpoint acceleration, jump input
  buffering is 180 ms, and falling gravity is slightly stronger than rising gravity.
- Castle Heights, Enchanted Wilds and Ember Ruins have distinct generated vistas,
  detailed paving textures and transparent painted landmarks, plus corresponding
  architecture, foliage, crystals, fog and particle palettes.
- Endless-run biomes follow pure distance state: 384 m per biome with a 72 m
  crossfade into the next. The sequence repeats deterministically, independently
  of character choice, encounter RNG, rewards and profile data.
- Ahead-of-player chunks and obstacle motifs use their own world stations.
  All variants retain the existing road width, length, collision and elevation
  contracts. Presentation does not insert a biome-loading pause.
- World allocation stays bounded: eleven track chunks and twelve recycled
  landmark instances. Textures and meshes are local/preloaded; there are no
  runtime asset downloads or unbounded streaming queues.
- Finite courses, training, secret routes, progression and controls remain present.

## Verification

- New continuous-motion/biome suite: 331 assertions, now required in GitHub CI.
- Existing core: 427 assertions; concept sprites: 156; environments: 9.
- Controls: 38; scenery: 11; adventure/progression: 125; navigation: 148;
  tilt/elevation: 35; rig motion: 29; Knight expressions: 15; Gargoyle: 16;
  Witch: 19. All passed locally.
- Python tools: 65 tests; release reconstruction: 28 tests. All passed.
- Three actual rendered 3,600-tick runs (one per hero) crossed the complete biome
  cycle over 1,311.5 m, with no reported incidents, damage, deaths, off-screen
  character ticks or character switches. Final artwork received additional
  actual-game rendered reviews at disclosed seeded stations.
- Screenshots are game-owned captures, not concept compositions. The short
  Knight motion clip comes from actual game frames with scripted jump/slide
  input. Review-station screenshots disclose their seeded starting distances;
  the long runs are the evidence for continuous progression.
- Source PNGs and rejected experiments are retained under the ignored workspace
  generated-artifacts archive. Runtime textures, content hashes, provenance,
  processing script and rights metadata are committed.

## Limits and Android release

Desktop checks and software-renderer captures do not certify Samsung S23 frame
pacing, touch latency, thermal behavior or final artistic approval. No physical
phone has been operated from this workspace. Review the released update on the
owner's phone for those aspects.

The existing automatic GitHub pipeline performs APK compilation, permanent-key
signing, independent signature/package/version/resource/integrity/alignment
verification, baseline update eligibility checks and release-download hash checks.
Build 2009's package and permanent certificate are unchanged; version codes must
exceed the installed baseline and all published versions. No phone uninstall,
save reset, signing-key replacement or manual deployment approval is introduced.
