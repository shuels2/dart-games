# Lunar Lander

## Overview

Lunar Lander is a retro NASA space mission dart game based on Moon Landing (Countdown/Dartsee). Players pilot their rockets from orbit to the lunar surface by subtracting dart scores from their starting altitude. The first astronaut to reach exactly zero altitude — or overshoot into negative territory with Hard Landing disabled — achieves a safe Touchdown and wins the mission.

## Quick Facts
- **Players:** 2-8
- **Duration:** 8-20 minutes
- **Complexity:** Low
- **Theme:** Retro NASA propaganda poster meets Pixar's Wall-E warmth
- **Special Features:** Descent track visual per player, configurable starting altitude (100-500), Hard Landing bust rule, 8 astronaut animal characters with random assignment

## Game Documentation
- [Game Rules](game-rules.md) - Complete rules, mechanics, win conditions
- [Design System](design-system.md) - Color theme, fonts, styling
- [Components](components.md) - Dialog configs, dartboard emulator setup
- [Announcements](announcements.md) - Audio system, sound effects
- [Testing](testing.md) - Test coverage details
- [Assets](assets.md) - Asset inventory
- [Implementation Notes](implementation-notes.md) - Technical details, gotchas

## File Locations
- **Screens:** `lib/screens/games/lunar_lander/`
- **Provider:** `lib/providers/lunar_lander_provider.dart`
- **Models:** `lib/models/lunar_lander_game.dart`
- **Services:** `lib/services/lunar_lander_announcement_helper.dart`
- **Sound Effects:** `lib/services/lunar_lander_sound_effects.dart`
- **Play-to-Complete Strategy:** `lib/services/play_to_complete/lunar_lander_strategy.dart`
- **Assets:** `assets/games/lunar_lander/`
- **Non-UI Tests:** `test/screens/games/lunar_lander/`, `test/models/lunar_lander_game_serialization_test.dart`, `test/providers/lunar_lander_save_restore_test.dart`
- **UI Tests:** `integration_test/lunar_lander/`

## Key Features
- Vertical descent track per player showing rocket position proportional to remaining altitude
- Two configurable options: Starting Altitude slider (100-500, default 200) and Hard Landing toggle (bust rule, default OFF)
- Hard Landing ON: going below 0 voids the turn and reverts altitude (crash animation + HARD LANDING badge)
- Hard Landing OFF: negative altitude is allowed and still wins the game (overshoot lands on moon)
- Random character assignment from 8 astronaut animal characters at game start (Reef Royale shuffle pattern)
- Full Save and Resume game integration

## Spec Reference
- **Spec file:** `C:\Users\steve\Downloads\LunarLander\lunar-lander.md`
- **Based on:** Moon Landing / Countdown (Dartsee)
