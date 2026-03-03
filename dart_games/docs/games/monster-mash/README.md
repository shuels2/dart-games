# Monster Mash

## Overview
Monster Mash is an HP-based elimination dart game for 2-8 players where each player controls a classic monster. Hit your target number to heal, hit opponents' targets to deal damage, and be the last monster standing!

## Quick Facts
- **Players:** 2-8
- **Duration:** 10-30 minutes
- **Complexity:** Medium (HP management, buffs, elimination)
- **Special Features:** 8 unique monsters, 4 bonus buffs, speed play mode, health-reactive character art

## Game Documentation
- [Game Rules](game-rules.md) - Complete rules, mechanics, win conditions
- [Design System](design-system.md) - Dark gothic theme, stone buttons, lightning effects
- [Components](components.md) - Dialog configs, dartboard emulator setup, StoneDialogButton
- [Announcements](announcements.md) - Audio system, 11 sound effects (4 native + 7 borrowed)
- [Testing](testing.md) - 51 UI tests, 55 non-UI tests, coverage details
- [Assets](assets.md) - 32 character images, 3 icons, 2 images, 4 sounds
- [Implementation Notes](implementation-notes.md) - Technical details, health image system, buff mechanics

## File Locations
- **Screens:** `lib/screens/games/monster_mash/`
- **Provider:** `lib/providers/monster_mash_provider.dart`
- **Models:** `lib/models/monster_mash_game.dart`
- **Services:** `lib/services/monster_mash_announcement_helper.dart`
- **Sound Effects:** `lib/services/monster_mash_sound_effects.dart`
- **Assets:** `assets/games/monster_mash/`
- **Tests:** `integration_test/monster_mash/monster_mash_*.dart`, `test/screens/games/monster_mash/`

## Key Features
- 8 classic monsters (Dracula, Frankenstein, Mummy, Wolf Man, Invisible Man, Gill Man, Mr. Hyde, Phantom)
- Health-reactive character art (4 states per monster based on HP percentage)
- 4 bonus buffs (Blood Moon, Ancient Bandages, Shadow Walk, Laboratory Spark)
- Speed Play mode with configurable round limit
- Stone tablet button design with lightning animation effects
- Comprehensive announcement system with monster-themed voice lines
- Hat Trick detection (3 darts on same opponent)
- Clutch Heal detection (healing while critically low)

## Test Summary
- **Non-UI Tests:** 65 tests (47 game logic + 18 announcements)
- **UI Automation Tests:** 51 tests (~32 minutes)
- **Total:** 116 tests
