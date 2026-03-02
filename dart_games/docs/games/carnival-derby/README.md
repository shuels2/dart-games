# Carnival Derby

## Overview
Carnival Derby is a dart-based horse racing game where players race horses to reach a target score.

## Quick Facts
- **Players:** 2-8 players
- **Duration:** 10-15 minutes
- **Complexity:** Low-Medium (scoring, race mechanics)
- **Special Features:** Normal and Perfect Finish modes, inner/outer singles

## Game Documentation
- [Game Rules](game-rules.md) - Complete rules, mechanics, win conditions
- [Design System](design-system.md) - Yellow/amber carnival theme, fonts, styling
- [Components](components.md) - Dialog configs, dartboard emulator setup
- [Announcements](announcements.md) - Audio system, sound effects
- [Testing](testing.md) - 24 UI tests, 37 non-UI tests
- [Assets](assets.md) - 3 icons, 1 image, 2 sounds
- [Implementation Notes](implementation-notes.md) - Technical details

## File Locations
- **Screens:** `lib/screens/games/carnival_horse_race/`
- **Provider:** `lib/providers/horse_race_provider.dart`
- **Models:** `lib/models/horse_race_game.dart`
- **Services:** `lib/services/carnival_derby_announcement_helper.dart`
- **Sound Effects:** `lib/services/carnival_derby_sound_effects.dart`
- **Assets:** `assets/games/carnival_derby/`
- **Tests:** `integration_test/carnival_derby/carnival_derby_ui_test.dart`, `test/screens/games/carnival_horse_race/`

## Key Features
- Horse racing theme
- Normal mode (first to target score)
- Perfect Finish mode (exact score to win)
- Inner/outer single distinction
- Bust mechanics in exact score mode
- Carnival-themed visuals and sounds
