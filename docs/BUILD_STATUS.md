# Mystic Run 0.3.0 development status

October 31, 2026 · Lamont Labs

This is the navigation and runner-mechanics revision after the owner rejected the
0.2.0 feel. See GAMEPLAY_AND_NAVIGATION.md for the exact changes and limits, and
ART_DIRECTION.md for the original art provenance and the still-open quality target.

Implemented: native Home/Team/Routes/Records navigation, three finite expeditions,
Endless Relay, interactive practice, pause/settings/controls Back paths, explanatory
results and local run history. Input, lane transitions, camera follow, crouch,
combat timing, Witch blink, encounter phrases and visible fractures are revised.

The package remains `com.lamontlabs.knightgargoylewitch.dev`; owner signing identity
is preserved. GitHub compiles the APK, then the signed release is independently
reconstructed and byte/certificate/package/alignment checked before publication.
The signed APK manifest is authoritative for the source commit, run and exact bytes.

Actual core, control, navigation, animation and run reports are in tests/evidence/.
Rendered previews are actual Godot frames, with scripted desktop input disclosed.
Physical-phone performance and human game-feel approval are not established by
these checks. The owner's premium quality target remains open.

## Build evidence

GitHub compilation 41216289193 succeeded from source
`66b0edd64b5bcbeabf364813cad249d45111b19b`. The signed APK is
`Mystic_Run_0.3.0_GitHub_Build1006.apk`, version code 1006, 38,307,893 bytes.
SHA-256: `e3131c63a89244a8a2bfde3351f4eb5be79b99debe898982c8aec8ba16e8a9f6`.
The original signing certificate, package/version, ZIP integrity, unchanged game
payload, APK/native 16 KB alignment and six license notices were checked.
Eighty-eight runtime source and asset hashes match the GitHub compilation manifest.

Local results: 427 core checks, 38 control/course checks, 107 native GUI/input/flow
checks, 18 rig checks, and six release-reconstruction contracts passed. Three
portrait 60-second runs completed about 810–813 m with three handoffs each,
zero damage/deaths and zero off-screen runner-centre ticks, covering all six
directed teammate changes. These runs use the disclosed automated driver.
