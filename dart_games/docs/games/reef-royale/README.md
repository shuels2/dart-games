# Reef Royale

Reef Royale is a coral-claiming dart game for 2-8 players where each player controls a sea creature. Hit your target numbers to grow coral colonies, claim all 7 corals, and harvest pearls from your rivals' unclaimed reefs!

## Quick Facts

- **Players:** 2-8
- **Duration:** 10-30 minutes
- **Complexity:** Medium (marking, claiming, pearl scoring)
- **Special Features:** 8 sea creatures, 7 coral types, 3 bonus buffs, Cursed Tide mode, neighbor numbers, random reefs

## Test Summary

- **Non-UI Tests:** ~150 tests (game logic + announcements)
- **UI Automation Tests:** 67 tests (~45 minutes)

## File Locations

| Category | Path |
|----------|------|
| Model | `lib/models/reef_royale_game.dart` |
| Provider | `lib/providers/reef_royale_provider.dart` |
| Menu Screen | `lib/screens/games/reef_royale/reef_royale_menu_screen.dart` |
| Game Screen | `lib/screens/games/reef_royale/reef_royale_game_screen.dart` |
| Results Screen | `lib/screens/games/reef_royale/reef_royale_results_screen.dart` |
| Announcements | `lib/services/reef_royale_announcement_helper.dart` |
| Sound Effects | `lib/services/reef_royale_sound_effects.dart` |
| Assets | `assets/games/reef_royale/` |
| Non-UI Tests | `test/screens/games/reef_royale/` |
| UI Tests | `integration_test/reef_royale_*.dart` |

## Key Features

- **Cricket-style marking** — hit numbers 3 times (or 2 with Easy Claim) to claim corals
- **Pearl scoring** — earn pearls from claimed targets while opponents haven't claimed them
- **Cursed Tide mode** — pearls go to opponents; lowest pearl count wins
- **Random Reefs** — randomized target numbers each game
- **Neighbor Numbers** — adjacent dartboard numbers also count as hits
- **Bonus Buffs** — Riptide Rush (2x marks), Pearl Fever (2x pearls), Ink Cloud (hides opponent info)
- **8 unique sea creatures** with distinct artwork

## Documentation Index

- [Game Rules](game-rules.md) — Mechanics, scoring, win conditions
- [Design System](design-system.md) — Colors, typography, visual identity
- [Components](components.md) — Shared and custom UI components
- [Assets](assets.md) — Character, coral, sound, and image assets
- [Announcements](announcements.md) — Audio system and sound effects
- [Testing](testing.md) — Test structure and coverage
- [Implementation Notes](implementation-notes.md) — Architecture and gotchas
