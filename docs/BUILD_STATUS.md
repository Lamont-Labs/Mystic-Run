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
