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

Pending the real GitHub compilation run. See the resulting logs and `evidence.json`;
do not infer success from this source being committed.

## Sources

- https://defold.com/manuals/bob/
- https://github.com/defold/defold/releases/tag/1.14.1
- https://defold.com/license/
- Signing-default audit:
  https://github.com/defold/defold/blob/1.14.1/com.dynamo.cr/com.dynamo.cr.bob/src/com/dynamo/bob/bundle/AndroidBundler.java

Defold is source-available under the Defold License, not MIT.
Existing MysticRun concept art remains noncommercial-only; this probe uses none.
