# Pirate's Grid

## Overview

Pirate's Grid is a dart-based tic-tac-toe game for exactly 2 players set in a pirate treasure map world. Players take turns throwing darts at a 3x3 grid of targets — hit the right target to plant your pirate flag in that square, and be the first captain to get three in a row to claim the treasure. With configurable difficulty (Easy/Medium/Hard), Best Of rounds, Steal Mode (mutiny!), and Speed Play, the game scales from a quick beginner match to a strategic Best Of 5 showdown.

## Quick Facts
- **Players:** 2 (exactly)
- **Duration:** 3-15 minutes (depends on Best Of setting)
- **Complexity:** Very Low
- **Theme:** Pirate treasure map — parchment textures, jolly roger flags, Pirata One / Lora fonts
- **Special Features:** 3x3 grid tic-tac-toe with dart targets, configurable Target Difficulty (Easy/Medium/Hard), Best Of rounds (1/3/5), Steal Mode (replace opponent flags), Speed Play (15-second turn timer)

## Game Documentation
- [Game Rules](game-rules.md) - Complete rules, mechanics, win conditions
- [Design System](design-system.md) - Color theme, fonts, styling
- [Components](components.md) - Dialog configs, dartboard emulator setup
- [Announcements](announcements.md) - Audio system, sound effects
- [Testing](testing.md) - Test coverage details
- [Assets](assets.md) - Asset inventory
- [Implementation Notes](implementation-notes.md) - Technical details, gotchas

## File Locations
- **Screens:** `lib/screens/games/pirates_grid/`
- **Provider:** `lib/providers/pirates_grid_provider.dart`
- **Models:** `lib/models/pirates_grid_game.dart`
- **Services:** `lib/services/pirates_grid_announcement_helper.dart`
- **Sound Effects:** `lib/services/pirates_grid_sound_effects.dart`
- **Play-to-Complete Strategy:** `lib/services/play_to_complete/pirates_grid_strategy.dart`
- **Utilities:** `lib/screens/games/pirates_grid/utils/` (three_in_a_row_checker, grid_target_generator)
- **Assets:** `assets/games/pirates_grid/`
- **Non-UI Tests:** `test/screens/games/pirates_grid/`, `test/models/pirates_grid_serialization_test.dart`, `test/providers/pirates_grid_save_restore_test.dart`
- **UI Tests:** `integration_test/pirates_grid/`

## Key Features
- 3x3 grid tic-tac-toe with dart targets — each cell has a specific number or segment requirement
- Three difficulty levels change how grid targets are assigned (Easy: any segment, Medium: doubles/triples required, Hard: specific T/D/Bull per cell)
- Best Of rounds (1/3/5) with grid reset and round score tracker; starting player alternates each round
- Steal Mode: when ON, hitting a target already claimed by the opponent replaces their flag with yours (mutiny!)
- Speed Play: 15-second countdown timer per turn — turn auto-ends when the timer expires
- Full Save and Resume game integration, including mid-match Best Of state

## Spec Reference
- **Spec file:** `docs/research/games/tier1/pirates-grid.md`
- **Based on:** Tic-Tac-Toe / GoDartsPro
