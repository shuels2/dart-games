# Save & Resume Game

## Overview

The save/resume feature allows players to save in-progress games and resume them later. It is a global shared component with per-game theming following the established Config pattern.

## Architecture

### Storage
- **Server API** — Saved games are persisted on the server via `ApiClient` calls to the saved games REST endpoint
- **Organized by game type** (e.g., `carnival_derby`, `target_tag`)
- **No limit** on number of saved games per game type
- **Auto-delete:** Saved games are automatically deleted when a resumed game finishes

### Files

| File | Purpose |
|------|---------|
| `lib/models/saved_game_metadata.dart` | Data model for saved game entries |
| `lib/services/save_game_service.dart` | CRUD operations via server API |
| `lib/widgets/save_game_modal/save_game_modal.dart` | Save confirmation modal (back button) |
| `lib/widgets/save_game_modal/save_game_modal_config.dart` | Per-game theming for save modal |
| `lib/widgets/resume_game_modal/resume_game_modal.dart` | Resume/new game modal (menu screen) |
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

## Resume Flow (Menu Screen)

1. User taps game card on home screen → navigates to menu screen
2. Menu screen `initState` checks `SaveGameService.hasSavedGames(gameType)`
3. If no saved games → menu screen loads normally
4. If saved games exist → show ResumeGameModal overlay on menu screen
5. User can select a saved game tile, then tap "Resume Game"
6. "Resume Game" → `provider.restoreGame()`, navigate to game screen
7. "Start New Game" → dismiss modal, menu screen is visible underneath
8. Individual tiles can be deleted, or "Delete All"

## Resume Game Button (Menu Screen)

Each game's menu screen includes a ResumeGameButton in the AppBar, positioned just to the left of the DartboardConnectionInfo widget. This button provides quick access to the Resume Game Modal without requiring users to navigate back to the home screen.

### Component Location
**File:** `lib/widgets/resume_game_button.dart`

### Props
```dart
ResumeGameButton({
  required bool hasSavedGames,      // Enable/disable button
  required VoidCallback onPressed,   // Callback when pressed
  required Color color,              // Game-specific theme color
  Color? disabledColor,              // Optional disabled color (defaults to color with 30% opacity)
  double iconSize = 28,              // Icon size (defaults to 28)
})
```

### Usage Pattern
Each game menu screen:
1. Adds state variable: `bool _hasSavedGames = false;`
2. Adds check method:
```dart
Future<void> _checkForSavedGames() async {
  final hasSaved = await SaveGameService().hasSavedGames('{game_type}');
  if (mounted) {
    setState(() => _hasSavedGames = hasSaved);
  }
}
```
3. Calls `_checkForSavedGames()` on:
   - Initial screen load (`initState`)
   - Resume modal close callback (`onClose`)
   - Start new game callback (`onStartNewGame`)
4. Adds button to AppBar:
```dart
AppBar(
  actions: [
    ResumeGameButton(
      hasSavedGames: _hasSavedGames,
      onPressed: () => setState(() => _showResumeModal = true),
      color: {gameThemeColor},
    ),
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: DartboardConnectionInfo(...),
    ),
  ],
)
```

### Per-Game Colors
| Game | Color | Value |
|------|-------|-------|
| Target Tag | White | `Colors.white` |
| Carnival Derby | Cloud Dancer | `Color(0xFFF0E2D0)` |
| Monster Mash | Mist | `Color(0xFFD3D8D2)` |
| Reef Royale | Pearl White | `Color(0xFFFFF8F0)` |

### Button States
- **Enabled:** Icon shows in game theme color, tooltip shows "Resume saved game"
- **Disabled:** Icon shows at 30% opacity, tooltip shows "No saved games"
- **Icon:** `Icons.history` (consistent across all games)

## Auto-Delete on Completion

When a resumed game reaches the results screen, `_deleteResumedSavedGame()` fires independently as its own async call from `addPostFrameCallback`:
1. Check `provider.resumedSavedGameId`
2. If set → `SaveGameService.deleteSavedGame()` removes the save
3. `provider.clearResumedSavedGameId()` clears tracking

The delete runs concurrently with `_updatePlayerStats()`, not sequentially after it. This ensures the saved game is removed promptly without waiting for all player stats HTTP calls to complete.

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
5. Home → tap game → menu screen → resume modal appears
6. Resume Game — loads game screen with correct state
7. Start New Game — navigates to menu
8. Delete individual saved game
9. Delete all saved games

## Adding Save/Resume to a New Game

1. Add `toJson()` and `fromJson()` to the game model
2. Add `saveGame()`, `restoreGame()`, `_resumedSavedGameId`, `clearResumedSavedGameId()` to the provider
3. Add factory methods to `SaveGameModalConfig` and `ResumeGameModalConfig`
4. Integrate `SaveGameModal` into the game screen (back button + PopScope + Stack)
5. Add `ResumeGameModal` to the menu screen (imports, `_showResumeModal` state, `initState` check, `_resumeGame` method, Stack overlay)
6. Add `_deleteResumedSavedGame()` as a separate async call in the results screen's `addPostFrameCallback`
7. Add widget keys to `test_keys.dart`
8. Write serialization, provider save/restore, and integration tests
