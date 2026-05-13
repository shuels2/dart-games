# Gladiator Arena

## Overview

Gladiator Arena is an Eliminator-style dart game where players race to accumulate Glory Points and reach a configurable target score. The deadly twist: if your score exactly matches an opponent's at the end of your turn, they get knocked off their podium back to zero! Victory belongs to the champion who reaches the target first — optionally requiring a double finish (Champion's Strike). The theme is Spartacus meets Disney's Hercules: epic Roman colosseum grandeur rendered in warm, family-friendly Disney animation style.

## Quick Facts

- **Players:** 2-8
- **Duration:** 10-25 minutes
- **Complexity:** Medium
- **Theme:** Spartacus meets Disney's Hercules — Roman colosseum, golden laurels, sun-drenched arena sands
- **Player List Pattern:** Dual-List (`DualPlayerListPanel`) — no team mode
- **Special Features:** Glory Points race, Knockoff rule (score-match resets opponent), Champion's Strike Double Finish, Shield Round (every 5th round blocks knockoffs), Speed Play 25-second timer, 8 gladiator animal characters randomly assigned at game start

## Game Documentation

- [Game Rules](game-rules.md) - Complete rules, mechanics, win conditions
- [Design System](design-system.md) - Color theme, fonts, styling
- [Components](components.md) - Dialog configs, dartboard emulator setup
- [Announcements](announcements.md) - Audio system, sound effects
- [Testing](testing.md) - Test coverage details
- [Assets](assets.md) - Asset inventory
- [Implementation Notes](implementation-notes.md) - Technical details, gotchas

## File Locations

- **Screens:** `lib/screens/games/gladiator_arena/`
- **Provider:** `lib/providers/gladiator_arena_provider.dart`
- **Models:** `lib/models/gladiator_arena_game.dart`
- **Services:** `lib/services/gladiator_arena_announcement_helper.dart`
- **Sound Effects:** `lib/services/gladiator_arena_sound_effects.dart`
- **Play-to-Complete Strategy:** `lib/services/play_to_complete/gladiator_arena_strategy.dart`
- **Assets:** `assets/games/gladiator_arena/`
- **Non-UI Tests:** `test/screens/games/gladiator_arena/`, `test/models/gladiator_arena_serialization_test.dart`, `test/providers/gladiator_arena_provider_game_test.dart`, `test/providers/gladiator_arena_save_restore_test.dart`
- **UI Tests:** `integration_test/gladiator_arena/`

## Key Features

- **Glory Points race:** First player to reach (or exceed, when Double Finish is OFF) the configurable target score wins
- **Knockoff rule:** Land on exactly another player's score at end of turn — they reset to zero (the game's signature dramatic mechanic)
- **Champion's Strike Double Finish (ON by default):** Final dart must be a double landing exactly on the target; overshooting OR hitting the target without a double = BUST (score reverts)
- **Shield Round (OFF by default):** Every 5th round a shield banner appears and all knockoffs are blocked — gives players periodic protection against repeated resets
- **Speed Play (OFF by default):** 25-second countdown per turn; timer freezes when the turn ends (same pattern as Pirate's Grid); unthrown darts are lost when timer expires
- **Podium display:** Each player is shown as a vertical podium bar whose height scales proportionally to their score vs. the target — instantly readable scoreboard
- **8 gladiator animal characters** randomly assigned at game start: Leo the Lion, Aquila the Eagle, Lupus the Wolf, Ursus the Bear, Corvus the Raven, Taurus the Bull, Serpens the Snake, Falco the Falcon
- **Full Save and Resume game integration**

## Spec Reference

- **Spec file:** `docs/research/games/tier2/gladiator-arena.md`
- **Based on:** Eliminator (GoDartsPro)
