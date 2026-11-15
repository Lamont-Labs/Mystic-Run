# Defold build feasibility, not a game port

This isolated probe compiles a tiny collection, Lua script, label, font and shaders
for ARM64 Android using Bob 1.14.1 and Java 25. It then bundles a **Linux headless**
engine and runs Lua API assertions. No editor or editor activation is involved.

Run `python3 tools/verify_defold_build.py` from the repository root with Java 25.
The script downloads the pinned official Bob JAR and verifies its release SHA-256.
All generated output stays in ignored `generated-artifacts/defold-build-proof/`.
The separate GitHub workflow provisions Java 25, has read-only repository
permissions, and does not reference environments, signing secrets or releases.

**Android compilation is not an APK, Android-device execution, save migration,
installation compatibility, playable runner, or evidence of animation quality.**
The Android `bundle` command is deliberately absent: Bob otherwise creates a
debug keystore automatically. No new key is permitted in this project.

The canonical package is retained as a configuration guard only. No version
code or installation compatibility is asserted by this probe. Future APK work
must use the existing trusted GitHub signing/release pipeline, locked certificate,
increasing version code and explicit save migration, after separate authorization.

## Status

**Passed the real GitHub run:** [compilation and runtime evidence](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/43775231466).
Tested implementation commit: `528d5d594281882eccd3e2490cb6812896f4254c`.

- Temurin Java 25.0.5; pinned Bob/engine 1.14.1.
- ARM64 Android resource compilation: **3.742 seconds**. Checked seven nonempty
  outputs and their SHA-256 hashes, including Lua bytecode, collection, label,
  compiled configuration and archive/index/manifest. Archive data: 58,573 bytes.
- Linux headless build/bundle: **3.949 seconds**.
- Actual Linux engine execution: **0.250 seconds**, exit zero; log confirmed
  `DEFOLD_BUILD_PROOF_RUNTIME_OK` after running Lua engine API assertions.
- The first run compiled Android resources but failed to launch Linux due to a
  missing OpenAL library. The successful run installed that Ubuntu dependency.
- No Android bundling/signing, APK, release, phone modification, gameplay rendering,
  Android-device execution or installation/update compatibility test occurred.

The workspace GitHub client's artifact ZIP download returned HTTP 401. Results
were verified from the successful run's accessible console logs instead; do not
claim the ZIP was downloaded or independently inspected.

**Recommendation:** Defold passed this editor-free compilation gate. A small
playable, rendered character/control prototype is the next evaluation gate, not
a full migration. Signed APK packaging and save migration remain unproven.

## Sources

- https://defold.com/manuals/bob/
- https://github.com/defold/defold/releases/tag/1.14.1
- https://defold.com/license/
- Signing-default audit:
  https://github.com/defold/defold/blob/1.14.1/com.dynamo.cr/com.dynamo.cr.bob/src/com/dynamo/bob/bundle/AndroidBundler.java

Defold is source-available under the Defold License, not MIT.
Existing MysticRun concept art remains noncommercial-only; this probe uses none.
