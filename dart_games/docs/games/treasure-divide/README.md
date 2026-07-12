# Treasure Divide

Treasure Divide is a Halve It pirate adventure for 2-8 Solo pirates or 3-10 Team players. Sail the seven seas, collect gold coins by hitting each round's target number, and try to keep your treasure — miss all 3 darts and HALF spills overboard! Navigate through 7, 9, or 12 island stops on the treasure map, and the richest pirate (or crew) at the end wins.

## Quick Facts

- **Players:** Solo: 2-8 · Team: 3-10 (doubles crews of 2, up to 5 crews)
- **Duration:** ~15 minutes (9-round default), 10 min for 7 rounds, 20 min for 12 rounds
- **Complexity:** Low-Medium
- **Special Features:** Halve It scoring with pirate theme; Solo Crew 6-dart fairness rule; Quarter It variant; Custom Targets randomization; Pirate Theme Overlay system (PirateAvatarWidget + mediapipe face detection)

## Game Documentation

- [Game Rules](game-rules.md) — Halve It rules, scoring, halving, Quarter It, target sequences, team mode
- [Design System](design-system.md) — Treasure Gold/Ocean Teal palette, PirataOne/Merriweather typography, screen styling
- [Components](components.md) — Dialog configs, dartboard emulator setup, Play to Complete strategy
- [Announcements](announcements.md) — 22 announcement events, per-dart precedence chain, 8 sound effects
- [Testing](testing.md) — Test file inventory, REAL counts, TD-specific test categories
- [Assets](assets.md) — 22 theme accessory PNGs + 6 crests + 5 piece images + 8 sounds + icon + background
- [Implementation Notes](implementation-notes.md) — Provider pattern, sentinel constants, randomDistribution, Solo crew rule, Pirate Theme Overlay System, mediapipe stack, 10 product bugs fixed

## File Locations

| Category | Path |
|----------|------|
| Model | `lib/models/treasure_divide_game.dart` |
| Provider | `lib/providers/treasure_divide_provider.dart` |
| Menu Screen | `lib/screens/games/treasure_divide/treasure_divide_menu_screen.dart` |
| Game Screen | `lib/screens/games/treasure_divide/treasure_divide_game_screen.dart` |
| Results Screen | `lib/screens/games/treasure_divide/treasure_divide_results_screen.dart` |
| Announcements | `lib/services/treasure_divide_announcement_helper.dart` |
| Sound Effects | `lib/services/treasure_divide_sound_effects.dart` |
| Play to Complete | `lib/services/play_to_complete/treasure_divide_strategy.dart` |
| Custom Widgets | `lib/widgets/treasure_divide/` (PirateAvatarWidget, TreasureMapWidget, pirate_themes.dart) |
| Assets | `assets/games/treasure_divide/` |
| Non-UI Tests | `test/screens/games/treasure_divide/` |
| Provider Tests | `test/providers/treasure_divide_provider_game_test.dart`, `test/providers/treasure_divide_save_restore_test.dart` |
| Model Tests | `test/models/treasure_divide_serialization_test.dart` |
| Widget Tests | `test/widgets/treasure_divide/pirate_avatar_widget_test.dart` |
| UI Tests | `integration_test/treasure_divide/` |

## Key Features

- **Halve It rules** — Each round has a specific target (20, 19, 18, Any Double, 17, 16, 15, Any Triple, Bull). Hit the target at least once to bank your haul; miss all 3 darts and your running total is halved (or quartered with Quarter It ON)
- **Solo Crew 6-dart fairness rule** — In Team mode, a 1-player (odd) crew throws 6 darts in a single turn to match the combined throw count of a paired crew; halving fires only when all 6 darts miss
- **Quarter It variant** — Optional setting that changes the miss penalty from ÷2 to ÷4 with more dramatic animations and "A storm hits!" announcement
- **Custom Targets** — Optional randomization of the target number sequence; future islands display "???" until they become the active round
- **Pirate Theme Overlay System** — Each player's avatar photo is dressed up with themed pirate accessories (hats, eyepatches, parrots, etc.) driven by server-side mediapipe face landmark detection; 8 distinct themes assigned per-game via shuffle; heuristic fallback when landmarks unavailable
