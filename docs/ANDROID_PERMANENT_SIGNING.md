# MysticRun replacement permanent Android signing

All future normal APKs must reuse the existing replacement backup. Never generate
a key, commit signing material, or uninstall/modify the phone game to fix a mismatch.

| Identity | Required value |
| --- | --- |
| Package | `com.lamontlabs.knightgargoylewitch.dev` |
| Alias | `mysticrun` |
| Certificate SHA-256 | `8ccd240d320a0ac8568581d5c7e005538033681d8b882058d673c80719dfd859` |

## Secure configuration

The existing **Mystic Run Android APK** workflow is
`.github/workflows/android-apk.yml`. It is manual, main-only, and read-only with
respect to repository contents. Configure a GitHub environment named
`android-signing`, restrict it to main, and require owner approval before jobs run.
Using GitHub's secure environment-secret interface, configure:

- `MYSTICRUN_KEYSTORE_BASE64`: the existing replacement keystore, base64 encoded.
- `MYSTICRUN_STORE_PASSWORD`: its existing store password.
- `MYSTICRUN_KEY_PASSWORD`: the existing `mysticrun` private-key password.

Do not supply values in chat, command arguments, source files, or logs. Do not
reuse older `RELAY_DEVELOPMENT_*` secrets on assumption. Missing credentials,
wrong alias, or wrong certificate stop the build. This change does not configure
remote secrets or claim that these environments/approval policies already exist.
Runner signing files are private and removed even on failure.

## Build and verification

The workflow compiles unsigned using `tools/build_android.py --unsigned`, then
uses `tools/sign_android.py`. Direct normal signed exports are blocked to avoid
Godot's older debug-key configuration. The separate, explicitly selected Art
Preview variant is not changed by this task.

For approved local signing, provide the existing keystore path and both passwords
through a protected environment/secret manager, then run:

```sh
python3 tools/sign_android.py \
  --apk /protected/input.apk --manifest /protected/apk-manifest.json \
  --sdk /path/to/android-sdk --keystore /protected/existing.keystore \
  --expected-commit FULL_SOURCE_COMMIT \
  --output /protected/verified/Mystic_Run_Build.apk
```

Add `--expected-run-id` for a known GitHub compilation. `--permanent-identity`
remains an optional compatibility flag; omitting it cannot select an old key.
No default password or legacy-signing fallback exists.

Before exposing an APK download, verification checks unsigned input digest and
provenance, exact package/version, the pinned certificate, exactly one signer,
both v2 and v3 signatures, 16 KB ZIP/native alignment, offline permissions, ZIP
integrity, unchanged game-file hashes, bundled notices, resource-table file
references, and parsing of packaged binary XML. Resource parsing uses `aapt2`
and fails on an empty parse or missing file, including themed-icon XML.
These checks do not repair resources: a failed icon-resource build must be
fixed in its separate PR. Only fully verified APKs and evidence are uploaded.
Output paths must not already exist.

## Publishing and compatibility

Signing never creates a GitHub Release. **Publish installable Android APK**
(`.github/workflows/publish-android.yml`) now requires a separate manual run on
main with explicit publication approval and uses the `android-release`
environment. Configure owner approval there too. It independently rechecks the
final APK rather than trusting manifest verification flags.

The older original certificate (`f5ee5d42…`) and previous permanent certificate
(`6cae555c…`) remain recognized only for historical release reconstruction.
Neither is accepted for new normal signing. A replacement-key APK cannot update
an installation using either older key. Updates to replacement-key installations
also require a higher version code; the workflow increments its run-based code,
but cannot determine the version installed on a phone. Do not uninstall the phone
app or discard saves. No physical-device test is implied by build verification.
