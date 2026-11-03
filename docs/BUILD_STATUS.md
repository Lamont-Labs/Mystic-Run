# Mystic Run 0.6.0 development status

November 2, 2026 · Lamont Labs

The game implements swipe-based strikes, character specials, earned traversal powers, nine optional secret routes and unique treasures, fourteen achievements and persistent mastery. Brighter colors, animated runners, floating lanterns, star pickups and comic feedback make the game more playful. See the [gameplay guide](GAMEPLAY_AND_NAVIGATION.md).

## Verification

Local tests passed **791 Godot assertions**: 427 core, 38 gesture/course, 125 adventure/progression, 148 native navigation, 35 tilt/elevation and 18 animation. The navigation suite also passed with actual rendered desktop GUI hit testing. Each of the three runners completed a scripted 3,600-tick basic-only run of about 1.31 km with zero damage, deaths, handoffs or off-screen runner-centre ticks. Four Android manifest-policy guard cases and six signed-archive reconstruction tests passed.

Actual desktop frames of the home screen and three distinct secret-room themes were inspected. Secret-room renders grant mastery only in memory for the test. These checks do not establish physical Android touch comfort, sensor orientation, battery life, sustained frame pacing or final art approval.


## Android and Play status

A signed **local development APK** was built from source commit `9f9e5364a8de4bee301e87d9670dd9ffb11aff9a`: version 0.6.0 / 1011, 38,349,720 bytes, SHA-256 `49653f1ea53e848269e25fc658093fa408350117e528ea76304534df2d8bbcb0`. All 100 packaged runtime source and asset hashes matched the reviewed files. The APK uses the existing owner signing identity and passes signature, ZIP integrity, unchanged payload, bundled notices, 16 KB archive alignment and 16 KB native ELF segment alignment checks. Its packaged manifest targets API 36, supports API 24 and later, and declares vibration as its only permission. It has not been installed on a physical Android device.

This 0.6.0 APK was compiled and signed locally; it has not been published as a GitHub release. The remote branch contains an earlier 0.6.0 checkpoint, while the final source and this local build record are in the local working repository. A production AAB, public privacy-policy URL, Play Console declarations, applicable closed testing and actual device validation remain open. See [Google Play preparation](GOOGLE_PLAY_READINESS.md).
