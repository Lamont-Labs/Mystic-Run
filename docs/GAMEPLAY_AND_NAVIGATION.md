# Mystic Run 0.6.0 — Gameplay and navigation

November 2, 2026 · Lamont Labs

Mystic Run is an offline portrait runner. Pick the Knight, Gargoyle or Witch on the home screen; that character stays with you for the whole run. Choose Endless or a finite Citadel, Spires or Rift expedition. The first Endless run teaches the controls in a protected stretch; lessons may be skipped and replayed from Settings.

## Controls

- Tilt to steer continuously, or select the separate thumb steering pad. The pad owns its touch so steering cannot trigger an attack.
- Swipe up to jump, down to slide, and left or right to perform a basic strike. A tap does not attack; there is no basic-attack button.
- Use the special button for Sunburst (Knight), Stone Pop (Gargoyle) or Starfall (Witch). These combat abilities are available from the beginning and recharge independently.
- Pause releases held input. Tilt is recalibrated on resume. Reduced motion softens decorative menu and effect animations while preserving necessary movement cues.

An approaching enemy gets a preparatory bracket, then an active strike cue. Basic attacks are buffered in the outer cue range and require the appropriate range, lane, height and clear line of sight. Specials resolve actual targets instead of advancing the runner or switching character.

## Mastery and secrets

Runs award each character mastery XP from unprotected distance, earned stars, defeated enemies, newly discovered treasure and course clears. The protected lesson stretch and practice sentinel grant no mastery. At 60 XP, the chosen character unlocks Sunbreak, Skyglide or Riftwalk. These contextual traversal abilities are distinct from combat specials and are optional for the ordinary route.

Each expedition contains one portal for each runner, accessible only with that runner's earned traversal ability. Align with the portal's lane and swipe up to enter. Endless cycles through the three districts and their corresponding portals. Each 96-metre pocket has stars, an encounter, a physical treasure and its own level-and-runner architecture; its exit rejoins the ordinary route. Treasures are awarded once, including on replay. The journal records all nine and fourteen achievements; saves migrate and sanitize older profiles.

## Feedback and results

Star pickups, combo pop-ups, lively motion, a special recharge ring and bright landmarks add energy and make actions easier to read. Results show distance, score, mastery XP, newly unlocked abilities, discoveries and badges. Replay a route or change runner from the results screen. Settings includes an offline privacy notice and a confirmation flow to clear saved progress while retaining preferences.

## Testing boundaries

Automated scene tests exercise all nine rooms, treasure pickup, exit, controls, progression, saves and achievements. Actual desktop renders include a scripted temporary mastery unlock to inspect secret chambers. These checks are not measurements of Android touch comfort, sensor orientation, device performance or final visual approval.
