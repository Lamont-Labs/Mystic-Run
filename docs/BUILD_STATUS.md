# Mystic Run 0.6.0 development status

November 2, 2026 · Lamont Labs

The game implements swipe-based strikes, character specials, earned traversal powers, nine optional secret routes and unique treasures, fourteen achievements and persistent mastery. Brighter colors, animated runners, floating lanterns, star pickups and comic feedback make the game more playful. See the [gameplay guide](GAMEPLAY_AND_NAVIGATION.md).

## Verification

Local tests passed **791 Godot assertions**: 427 core, 38 gesture/course, 125 adventure/progression, 148 native navigation, 35 tilt/elevation and 18 animation. The navigation suite also passed with actual rendered desktop GUI hit testing. Each of the three runners completed a scripted 3,600-tick basic-only run of about 1.31 km with zero damage, deaths, handoffs or off-screen runner-centre ticks. Four Android manifest-policy guard cases and six signed-archive reconstruction tests passed.

Actual desktop frames of the home screen and three distinct secret-room themes were inspected. Secret-room renders grant mastery only in memory for the test. These checks do not establish physical Android touch comfort, sensor orientation, battery life, sustained frame pacing or final art approval.


## Android and Play status

A signed **GitHub-compiled development APK** is prepared from source commit `192aacb10ca6c8f4830365cb6cfe039e3e719781`: version 0.6.0 / 1013, 38,349,720 bytes, SHA-256 `3b32b4ff973c74d2735fcfb63d09689542f50868ed8413d77ef4e1b411c1186c`. All 100 packaged runtime source and asset hashes matched the reviewed files. The APK uses the existing owner signing identity and passes signature, ZIP integrity, unchanged payload, bundled notices, 16 KB archive alignment and 16 KB native ELF segment alignment checks. Its packaged manifest targets API 36, supports API 24 and later, and declares vibration as its only permission. It has not been installed on a physical Android device.

The signed-archive record `.github/android-releases/build1013.json` lets the release workflow reconstruct the exact APK from the [successful GitHub compilation](https://github.com/Lamont-Labs/Mystic-Run/actions/runs/41567667407) and publish it to the repository's releases. An unsigned engineering AAB also passes bundletool validation and 16 KB native-library checks. Production identity and signing, a public privacy-policy URL, Play Console declarations, applicable closed testing and actual device validation remain open. See [Google Play preparation](GOOGLE_PLAY_READINESS.md).
