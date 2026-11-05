# Isolated Android art preview

The separately installed **Mystic Run Art Preview** uses `com.lamontlabs.knightgargoylewitch.artpreview`. Its development key is independent of the existing owner game key. It keeps its own save data and does not update or replace `com.lamontlabs.knightgargoylewitch.dev`.

The explicit exporter option is `tools/build_android.py --art-preview`. The default exporter retains the owner package and now checks its established signing certificate. An isolated preview is not an owner-signed update or a Google Play release.

The material checkpoint and actual engine review are in `MATERIAL_FINISH_REFINEMENT.md`. Source was saved before export. The verified build record below was added after the APK passed its checks.

The exporter checks the preserved certificate for the selected variant before export. It temporarily applies the APK identity and version, preserves the Play preset, and restores both source configuration files after success or failure. Three regression tests cover successful export configuration, failed export followed by an owner export, and malformed preset rejection. Private key material remains outside Git.

## Verified build 1017

November 5, 2026 · Lamont Labs

| Field | Actual value |
| --- | --- |
| Artifact | `Mystic_Run_0.6.2_Art_Preview_Build1017.apk` |
| Version | 0.6.2 / build 1017 |
| Source commit | `67bbd5cef7d60952730e143b9a4f3ebe86c333c4` |
| Source tree | `11f41ad88becd1289d5f359ef3239ee42725a6fd` |
| Bytes | 45511110 |
| APK SHA-256 | `3c243b49eb704456d2e898f4d4f94bd008889694ed02716df73d8f6a9224777c` |
| Signing certificate SHA-256 | `cced8d8dca20fd35d169f546802953375c76fad3559cdbcbe896271c61f26f5e` |
| Engine | `4.7.2.stable.official.ed1daf0bf` |
| Android | arm64-v8a; minimum API 24; target API 36 |
| Declared permission | Vibration only |

Local export passed signature and preserved-key verification, ZIP integrity, 16 KB ZIP alignment and the ELF load-segment alignment checks for both native libraries. All ten required engine, font and asset notices are present and byte-identical to the source notices. The archive contains no private signing files, build directory or development documentation. Both source configuration files were restored exactly after export. Every recorded source fingerprint matched the build input.

Current local validation passed 863 Godot assertions, 23 Python tests and 51 asset checks. Each of the three characters completed 3,600 ticks over 1,311.507 m with no damage, deaths, handoffs or off-screen runner-centre ticks. The local signature/package/manifest records and detailed test logs accompany the build.

This is an installable isolated development preview. Physical-phone installation, sustained frame pacing, thermal behavior, touch/tilt comfort and resume testing remain open. It does not replace the owner-update package, use the owner signing key or constitute a Google Play release.
