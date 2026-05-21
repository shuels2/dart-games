# Tiki Golf

Tiki Golf is a Lilo & Stitch-styled mini-golf dart game for 2-16 players. Every game shuffles 9 holes — each hole gets a random dartboard target number and a randomly-ordered tropical themed image, so no two rounds play the same. Hit the hole's number on your first dart for a birdie, second for par, third for bogey. Miss them all? Splash! Play Solo for the Golden Tiki trophy (2-4 players), or split into up to 4 tropical teams of up to 4 players each in Team mode (3-16 players total) using best-ball scoring.

## Quick Facts

- **Players:** Solo: 2-4 · Team: 3-16 (2-4 teams × 1-4 players each)
- **Duration:** 10-30 minutes (30+ minutes for 16-player team games)
- **Complexity:** Low (Solo) / Low-Medium (Team)
- **Special Features:** Per-game randomization of both hole targets and hole images; variable darts per turn (3-6); optional Mulligan (one free re-throw per player per game); Team best-ball scoring; per-team group play (real golf format)

## Game Documentation

- [Game Rules](game-rules.md) — Objective, turn structure, scoring table, win conditions, edge cases
- [Design System](design-system.md) — Tropical color palette, Boogaloo + Nunito typography, screen styling
- [Components](components.md) — Dialog configs, dartboard emulator setup, Mulligan modal variant
- [Announcements](announcements.md) — 14 announcement events, 11-rank precedence chain, 8 sound effects
- [Testing](testing.md) — Test file inventory, REAL counts, Tiki Golf-specific test categories
- [Assets](assets.md) — 26 asset files (18 image/icon/crest files + 8 sounds), canonical paths
- [Implementation Notes](implementation-notes.md) — Variable-dart turn logic, mulligan flow, per-game randomization, provider deviations

## File Locations

| Category | Path |
|----------|------|
| Model | `lib/models/tiki_golf_game.dart` |
| Provider | `lib/providers/tiki_golf_provider.dart` |
| Menu Screen | `lib/screens/games/tiki_golf/tiki_golf_menu_screen.dart` |
| Game Screen | `lib/screens/games/tiki_golf/tiki_golf_game_screen.dart` |
| Results Screen | `lib/screens/games/tiki_golf/tiki_golf_results_screen.dart` |
| Announcements | `lib/services/tiki_golf_announcement_helper.dart` |
| Sound Effects | `lib/services/tiki_golf_sound_effects.dart` |
| Play to Complete | `lib/services/play_to_complete/tiki_golf_strategy.dart` |
| Assets | `assets/games/tiki_golf/` |
| Non-UI Tests | `test/screens/games/tiki_golf/` |
| Provider Tests | `test/providers/tiki_golf_provider_game_test.dart`, `test/providers/tiki_golf_save_restore_test.dart` |
| Model Tests | `test/models/tiki_golf_serialization_test.dart` |
| UI Tests | `integration_test/tiki_golf/` |

## Key Features

- **Per-game randomization** — 9 hole target numbers and 9 hole theme images are both independently shuffled at game start; the same shuffle is preserved through save/resume
- **Variable darts per turn** — Max Darts setting (3/4/5/6) controls how many darts each player throws per hole; the first game in this codebase with this mechanic
- **Mulligan** — Optional per-player once-per-game re-throw that activates only after a Splash; triggers a custom pre-takeout modal variant (USE MULLIGAN vs NEXT PLAYER buttons)
- **Team best-ball scoring** — Each team's hole score is the minimum (best) of all its players' scores for that hole; entire team plays through before next team (real golf format)
- **Random team distribution** — In Random assignment mode, team count and sizes are auto-derived from the selected player count using a precise distribution table (3-16 players → 2-4 teams)
- **Golden Tiki trophy** — Solo winner is the Golden Tiki Champion; team winner is awarded to all players on the winning team (Target Tag pattern)
