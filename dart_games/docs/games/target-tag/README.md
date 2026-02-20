# Target Tag

## Overview
Target Tag is a shield-based elimination dart game for 2-10 players supporting both solo and team modes.

## Quick Facts
- **Players:** 2-10 (solo mode) or 2-10 in 2-5 teams (team mode)
- **Duration:** 10-20 minutes
- **Complexity:** Medium (shields, tagged-in status, eliminations)
- **Special Features:** Hero bonus, team mode, dart indicators

## Game Documentation
- [Game Rules](game-rules.md) - Complete rules, mechanics, win conditions
- [Design System](design-system.md) - Pink/green neon theme, fonts, styling
- [Components](components.md) - Dialog configs, dartboard emulator setup
- [Announcements](announcements.md) - Audio system, 15 sound effects
- [Testing](testing.md) - 53 UI tests, 46 non-UI tests, coverage details
- [Assets](assets.md) - 11 icons, 15 sound effects inventory
- [Implementation Notes](implementation-notes.md) - Technical details, gotchas

## File Locations
- **Screens:** `lib/screens/games/target_tag/`
- **Provider:** `lib/providers/target_tag_provider.dart`
- **Models:** `lib/models/target_tag_game.dart`
- **Services:** `lib/services/target_tag_announcement_helper.dart`
- **Sound Effects:** `lib/services/target_tag_sound_effects.dart`
- **Assets:** `assets/games/target_tag/`
- **Tests:** `integration_test/target_tag_*.dart`, `test/screens/games/target_tag/`

## Key Features
- Solo and team elimination gameplay
- Shield system (0-3 shields)
- Tagged-in status mechanic
- Hero bonus multiplier
- Visual dart indicators (D1/D2/D3) with color coding
- 15 unique sound effects
- Comprehensive announcement system
