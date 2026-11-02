# Mystic Run 0.4.0 development status

November 2, 2026 · Lamont Labs

Implemented: calibrated continuous tilt steering, sensor fallback, recentering,
inversion and sensitivity settings; faster starting speeds; a shared elevation
profile; grade-aware runner/camera/prop alignment; one character per run; cinematic
opening; revised Play hub and gameplay HUD; material, lighting, cloth and world
architecture changes. See GAMEPLAY_AND_NAVIGATION.md for the current contract.

The older relay and fixed-speed design is superseded for playable runs. Knight,
Gargoyle and Witch remain selectable before starting. Existing local records,
settings, package identity and the owner's signing identity are retained.

Local verification covers 427 core, 38 gesture/course, 112 native navigation/input,
35 tilt/elevation and 18 animation assertions. Three automated 60-second runs
traversed approximately 1.31 km per character without damage, death or handoffs.
The rendered desktop pass also exercises the actual gameplay scene and camera.
The signed APK manifest identifies the exact source commit and GitHub build; the
workflow artifact is the authoritative CI evidence for that commit.

This remains a development alpha. The requested premium production art target is
not approved. Further character/environment art, authored set pieces and device
performance work remain. Synthetic gravity and desktop checks do not establish
Android sensor orientation, phone comfort, sustained frame rate or thermal safety.
