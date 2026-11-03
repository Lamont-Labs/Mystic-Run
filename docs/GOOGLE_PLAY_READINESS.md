# Google Play preparation — Mystic Run 0.6.0

Reviewed November 2, 2026. This checklist records engineering work and outstanding submission steps; it does not claim Play approval.

## In the game and build pipeline

- The app runs offline. The Android export disables INTERNET and network-state permissions; the build and signing scripts inspect the packaged manifest and reject unexpected permissions or target API below 36. The expected declared permission is vibration. Verify this again on the actual release bundle.
- The in-app privacy screen explains locally stored records, local motion input, the absence of accounts, ads, analytics and purchases in this build, and how to clear progress. `privacy-policy.html` is a matching draft for a public website.
- The signing verifier checks APK alignment and native library ELF alignment for 16 KB pages. A real 16 KB-page Android device or emulator test is still required.
- An unsigned engineering AAB was built locally with the `Android Play Bundle` preset and passed bundletool validation. Its manifest targets API 36, requires API 24 or newer, supports arm64 and declares vibration as its only permission. Its bundle configuration requests 16 KB native-library alignment, and both ELF libraries passed 16 KB segment checks. This engineering bundle uses the development application ID and version code 1011; it has not been signed or tested on a device.

## Before a Play submission

1. Decide the production application ID and versioning. The current development APK uses `com.lamontlabs.knightgargoylewitch.dev`; changing an already-published application ID creates a different app and must be reconciled with the owner's actual Play listing.
2. Rebuild the release AAB with the confirmed production application ID and version code, sign it using the appropriate upload key, then verify its manifest, signing identity, Play Integrity and 16 KB compatibility. Do not substitute or disclose the preserved development key.
3. Publish `privacy-policy.html` on a publicly accessible, stable HTTPS page. Add the actual URL to the in-app notice and the Play listing. Re-review the notice and Data safety answers if any SDK, network access, advertising, account or purchase behavior changes.
4. Complete the actual Play Console declarations, including Data safety, advertising, target audience, content rating, app access and store listing. Complete developer identity and account requirements as applicable.
5. If this is a personal developer account created after November 13, 2023, check whether Google requires the 12-tester, 14-day closed test before production access. Account and existing-listing status have not been verified.
6. Install and play on representative Android phones, including tilt calibration, touch and screen insets, accessibility, sustained performance, and a 16 KB-page device or emulator. Review all store assets and perform a release-candidate regression pass.

## Official references

- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Prepare your app for review and privacy policy requirements](https://support.google.com/googleplay/android-developer/answer/9859455)
- [Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Personal account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Android 16 KB page-size compatibility](https://developer.android.com/guide/practices/page-sizes)
- [Godot Android export options](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html)
