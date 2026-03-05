# Save & Resume Game

## Overview

The save/resume feature allows players to save in-progress games and resume them later. It is a global shared component with per-game theming following the established Config pattern.

## Architecture

### Storage
- **SharedPreferences** — Saved games are persisted as JSON string lists
- **Key pattern:** `saved_games_{game_type}` (e.g., `saved_games_carnival_derby`)
- **No limit** on number of saved games per game type
- **Auto-delete:** Saved games are automatically deleted when a resumed game finishes

### Files

| File | Purpose |
|------|---------|
| `lib/models/saved_game_metadata.dart` | Data model for saved game entries |
| `lib/services/save_game_service.dart` | CRUD operations for SharedPreferences |
| `lib/widgets/save_game_modal/save_game_modal.dart` | Save confirmation modal (back button) |
| `lib/widgets/save_game_modal/save_game_modal_config.dart` | Per-game theming for save modal |
| `lib/widgets/resume_game_modal/resume_game_modal.dart` | Resume/new game modal (home screen) |
| `lib/widgets/resume_game_modal/resume_game_modal_config.dart` | Per-game theming for resume modal |

### Config Pattern

Both modals use the established Config pattern with per-game factory methods:
- `.carnivalDerby()`
- `.targetTag()`
- `.monsterMash()`
- `.reefRoyale()`

## Game Model Serialization

All 4 game models have `toJson()` and `fromJson()` for full state round-tripping:
- `HorseRaceGame` — `lib/models/horse_race_game.dart`
- `TargetTagGame` — `lib/models/target_tag_game.dart`
- `MonsterMashGame` — `lib/models/monster_mash_game.dart`
- `ReefRoyaleGame` — `lib/models/reef_royale_game.dart`

### Serialization Rules
- Enums → `.name` string, deserialize with `.firstWhere()` on `.name`
- `Set<int>` → `List<int>`, deserialize back to `.toSet()`
- `Map<int, int>` → `Map<String, int>` (JSON keys must be strings)
- `totalDartsThrown` and `totalTurns` per-player maps MUST be serialized

## Provider Integration

Each provider has:
- `saveGame(List<Player> players)` — Creates metadata and persists
- `restoreGame(SavedGameMetadata savedGame)` — Deserializes and restores state
- `resumedSavedGameId` — Tracks which saved game was resumed
- `clearResumedSavedGameId()` — Called after auto-delete

### Game-Specific Metadata

| Game | progressInfo | gameModeName | leadingPlayerScore |
|------|-------------|-------------|-------------------|
| Carnival Derby | "Leading: {score} pts" | "Target: {X}" + options | "{score} pts" |
| Target Tag | "{X} of {Y} players remaining" | "Solo"/"Team" + options | "{shields} shields" |
| Monster Mash | "Round {X}" | "HP: {X}" + options | "{health} HP" |
| Reef Royale | "Round {X}" | "Standard"/"Cursed Tide" + options | "{corals}/7 corals" |

## Save Flow (Back Button)

1. User presses back on game screen
2. Check `totalDartsThrown.values.any((c) => c > 0)`
3. If no darts thrown → normal pop
4. If darts thrown → show SaveGameModal
5. "Save Game" → call `provider.saveGame()`, then pop
6. "Don't Save" → pop without saving

### PopScope Integration
Each game screen wraps `Scaffold` in `PopScope` with `canPop: !hasDartsThrown` to intercept system back button/gesture.

## Resume Flow (Home Screen)

1. User taps game card on home screen
2. Check `SaveGameService.hasSavedGames(gameType)`
3. If no saved games → navigate to menu screen
4. If saved games exist → show ResumeGameModal
5. User can select a saved game tile, then tap "Resume Game"
6. "Resume Game" → `provider.restoreGame()`, navigate to game screen
7. "Start New Game" → navigate to menu screen
8. Individual tiles can be deleted, or "Delete All"

## Auto-Delete on Completion

When a resumed game reaches the results screen:
1. `_updatePlayerStats()` completes stats saving
2. Check `provider.resumedSavedGameId`
3. If set → `SaveGameService.deleteSavedGame()` removes the save
4. `provider.clearResumedSavedGameId()` clears tracking

## Widget Keys

All interactive elements have widget keys in `lib/constants/test_keys.dart`:
- `SaveGameModalKeys` — overlay, container, icon, title, message, saveButton, dontSaveButton
- `ResumeGameModalKeys` — overlay, container, title, savedGamesList, savedGameTile(id), deleteSavedGameButton(id), tileDate(id), tilePlayers(id), tileProgress(id), tileMode(id), tileLeader(id), resumeGameButton, startNewGameButton, deleteAllButton, emptyStateText

## Tests (167 tests)

### Non-UI Tests (131 tests)

| Category | File | Count |
|----------|------|-------|
| Model serialization | `test/models/*_serialization_test.dart` | 55 |
| Save game service | `test/services/save_game_service_test.dart` | 12 |
| Provider save/restore | `test/providers/*_save_restore_test.dart` | 28 |
| Save game modal | `test/widgets/save_game_modal_test.dart` | 8 |
| Resume game modal | `test/widgets/resume_game_modal_test.dart` | 13 |
| Integration | `test/integration/save_resume_integration_test.dart` | 15 |

### UI Automation Tests (36 tests)

| Game | File | Count |
|------|------|-------|
| Carnival Derby | `integration_test/carnival_derby/carnival_derby_save_resume_test.dart` | 9 |
| Target Tag | `integration_test/target_tag/target_tag_save_resume_test.dart` | 9 |
| Monster Mash | `integration_test/monster_mash/monster_mash_save_resume_test.dart` | 9 |
| Reef Royale | `integration_test/reef_royale/reef_royale_save_resume_test.dart` | 9 |

Each UI test file covers:
1. Back button with 0 darts — no save modal
2. Back button after darts thrown — save modal appears
3. Don't Save — navigates without saving
4. Save — saves game and navigates back
5. Home → tap game with saved games → resume modal appears
6. Resume Game — loads game screen with correct state
7. Start New Game — navigates to menu
8. Delete individual saved game
9. Delete all saved games

## Adding Save/Resume to a New Game

1. Add `toJson()` and `fromJson()` to the game model
2. Add `saveGame()`, `restoreGame()`, `_resumedSavedGameId`, `clearResumedSavedGameId()` to the provider
3. Add factory methods to `SaveGameModalConfig` and `ResumeGameModalConfig`
4. Integrate `SaveGameModal` into the game screen (back button + PopScope + Stack)
5. Add `_handleGameTap` case in `home_screen.dart`
6. Add auto-delete logic in the results screen's `_updatePlayerStats()`
7. Add widget keys to `test_keys.dart`
8. Write serialization, provider save/restore, and integration tests
