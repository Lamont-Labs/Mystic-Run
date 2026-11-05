# MysticRun permanent Android signing

The permanent signing identity is held in the existing private backup `MysticRun_Permanent_Signing_Backup.zip`. Do not create a replacement key, commit the backup, print its contents, or change the application ID.

| Property | Value |
| --- | --- |
| Application ID | `com.lamontlabs.knightgargoylewitch.dev` |
| Permanent certificate SHA-256 | `6cae555cdc35ea335e5ca6f29252bfad9ebc1cbc9a12c83e18c7eb1038a6a8cf` |
| Key alias | `androiddebugkey` |
| Keystore Actions secret | `RELAY_DEVELOPMENT_KEYSTORE_BASE64` |
| Password Actions secret | `RELAY_DEVELOPMENT_KEY_PASSWORD` |
| Signed release workflow | `.github/workflows/android-apk.yml` |

The two secret values must come directly from the preserved backup. Set them only as repository Actions secrets through an authenticated GitHub settings session or a CLI session with permission to manage Actions secrets. They must never pass through a Git commit, release asset, workflow input, or log. The connected GitHub repository tools do not provide a secrets-management operation.

The signed workflow runs only on main, fails if the key or password is absent, verifies the public certificate before exporting, checks the game and Android release contracts, builds a higher-version APK, verifies it again, publishes a prerelease, and downloads it again to check the actual published bytes. Disposable runner key files and editor signing settings are removed even after a failure.

For an already successful unsigned main compilation, `tools/sign_android.py --permanent-identity` signs with this same preserved key. The public reconstruction publisher can publish those verified APK bytes without putting a private signing key in Git. Public reconstruction records contain existing APK bytes and signature metadata, never the private key or password.

## Existing phone installation

The earlier original-game certificate is `f5ee5d42ec692e402b52c0457be35c24fe1f92229005002155f675040dddb9c9`. Builds signed with the permanent certificate cannot update an installation signed with that earlier certificate, even though the application ID is the same. A higher version code alone does not solve a certificate mismatch.

Do not uninstall the existing phone app or discard its saves. Its installation is outside this release task. A phone already using the permanent certificate can accept a higher-version permanent-key APK. Physical phone upgrade behavior and game performance must be tested separately; build verification is not a claim that a physical phone was tested.

Historical legacy-key releases remain valid and are checked against their original certificate. The legacy release documentation remains in `docs/ANDROID_UPDATE_IDENTITY.md`.
