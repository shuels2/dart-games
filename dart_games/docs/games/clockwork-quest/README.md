# Clockwork Quest

Clockwork Quest is a steampunk dart progression game for 2-8 players where each player races through gears 1-20 (or 1-21 with bullseye) in sequential order. Hit the right gears to advance your clockwork mechanism and be the first to complete the circuit!

## Quick Facts

- **Players:** 2-8
- **Duration:** 10-25 minutes
- **Complexity:** Simple (sequential target progression)
- **Special Features:** Bullseye gear 21, speed mode (2 darts), doubles/triples count, multiple laps

## Test Summary

- **Non-UI Tests:** 29 tests (game logic + announcements)
- **UI Automation Tests:** 48 tests (~34 minutes)
- **Total:** 77 tests

## File Locations

| Category | Path |
|----------|------|
| Model | `lib/models/clockwork_quest_game.dart` |
| Provider | `lib/providers/clockwork_quest_provider.dart` |
| Menu Screen | `lib/screens/games/clockwork_quest/clockwork_quest_menu_screen.dart` |
| Game Screen | `lib/screens/games/clockwork_quest/clockwork_quest_game_screen.dart` |
| Results Screen | `lib/screens/games/clockwork_quest/clockwork_quest_results_screen.dart` |
| Announcements | `lib/services/clockwork_quest_announcement_helper.dart` |
| Sound Effects | `lib/services/clockwork_quest_sound_effects.dart` |
| Assets | `assets/games/clockwork_quest/` |
| Non-UI Tests | `test/screens/games/clockwork_quest/` |
| UI Tests | `integration_test/clockwork_quest/clockwork_quest_*.dart` |

## Key Features

- **Sequential progression** — advance through gears 1-20 in order
- **Bullseye mode** — adds gear 21 (bullseye) as final target
- **D/T Count** — doubles/triples count as 2/3 advances instead of just marking
- **Speed Mode** — 2 darts per turn instead of 3 for faster gameplay
- **Multiple laps** — complete the circuit 1-5 times to win
- **Steampunk theme** — brass gears, copper accents, clocktower imagery

## Documentation Index

- [Game Rules](game-rules.md) — Mechanics, scoring, win conditions
- [Design System](design-system.md) — Colors, typography, visual identity
- [Components](components.md) — Shared and custom UI components
- [Assets](assets.md) — Gear, sound, and image assets
- [Announcements](announcements.md) — Audio system and sound effects
- [Testing](testing.md) — Test structure and coverage
- [Implementation Notes](implementation-notes.md) — Architecture and gotchas
