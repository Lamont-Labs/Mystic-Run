# Android update identity

Lamont Labs · November 5, 2026

Normal MysticRun releases update the existing installed game. Retain its application ID and signing identity, then increase the version code. A separate Art Preview installation is a different delivery variant and requires an explicit request.

| Identity | Required value |
| --- | --- |
| Existing game package | `com.lamontlabs.knightgargoylewitch.dev` |
| Existing game certificate SHA-256 | `f5ee5d42ec692e402b52c0457be35c24fe1f92229005002155f675040dddb9c9` |
| Keystore alias | `androiddebugkey` |
| Baseline published build | 1016 |
| Reviewed three-character update | 1023 |
| Update compilation source | `67bbd5cef7d60952730e143b9a4f3ebe86c333c4` |
| Successful compilation run | 42047036017 |

## Recovered original key

The original key was recovered from the owner's private backup named **Relic_Relay_Development_Signing_Backup.zip**. Use this exact legacy filename when recovering the key. The recovered certificate exactly matches published MysticRun builds 1003 through 1016.

The backup already exists in the owner's private files. Keep the key and any credentials outside Git. Check the recovered public certificate before signing. A newly generated key cannot replace this identity for normal updates.

## Build 1023

Build 1023 is an owner-package update using the original key. It contains the reviewed Knight, Gargoyle, Witch, material finish and free scenery. The signed APK and reconstruction record preserve the successful GitHub compilation's game payload bytes.

Verification against build 1016 confirms the same package, same certificate and a higher version code. Save/load functions, profile defaults, progression code and core/content source are unchanged. Signature, package/version, offline permissions, ZIP integrity and 16 KB archive/native alignment passed. All ten required engine, font and asset notices match the source.

The release record is in `.github/android-releases/build1023.json`. It binds the actual APK digest, successful compilation origin, public signing certificate and compatibility evidence. Physical-phone upgrade installation, frame pacing, thermal behavior and touch/tilt comfort remain untested.

## Art Preview

The separately installed Art Preview uses `com.lamontlabs.knightgargoylewitch.artpreview` and a different key. It is not the update target for the existing game. Preserve that preview identity for users who already installed it, and use the original game identity for normal update deliveries.

[Download the verified original-game update](https://github.com/Lamont-Labs/Mystic-Run/releases/download/v0.6.1-build1023/Mystic_Run_0.6.1_Three_Character_Update_Build1023.apk).
