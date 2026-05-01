# Shared Test Helpers Reference

## Overview

Shared test helpers live in two synchronized folders:
- `integration_test/shared/` — used by UI automation tests (414 tests)
- `test/shared/` — used by non-UI tests (1190 tests)

Both folders contain the same files with the same function signatures. When modifying any shared helper, **both copies must be updated**. See [Test Maintenance](test-maintenance.md) for synchronization rules.

## Helper Files

### Core Helpers

| File | Purpose | Key Functions |
|------|---------|---------------|
| `ui_test_helpers.dart` | Navigation, player management, game start | `navigateToGameMenu()`, `addPlayer()`, `startGame()` |
| `element_finders.dart` | Widget key-based finders for all games | `getStartButton()`, `getAddPlayerButton()`, game card finders |
| `provider_helpers.dart` | Provider state access for assertions | `getTargetTagProvider()`, `getClockworkQuestProvider()`, per-game state readers |
| `pump_sequences.dart` | Standardized frame pumping | `simpleUpdate()`, `fullRebuild()`, `navigationComplete()` |
| `game_ui_config.dart` | Per-game UI configuration | `GameUIConfig.targetTag()`, `.carnivalDerby()`, `.monsterMash()`, etc. |

### Game Setup & Dart Mechanics

| File | Purpose | Key Functions |
|------|---------|---------------|
| `dart_throw_helpers.dart` | All dart simulation via mock API | `throwDartViaMock()`, `throwBullseyeViaMock()`, `throwOuterBullViaMock()`, `throwMissViaMock()`, `clickDartsRemoved()`, `completeTurnWithMisses()`, `getMockApi()` |
| `game_setup_helpers.dart` | Per-game setup with settings | `setupAndStartClockworkQuest()`, `setupAndStartTargetTag()`, `setupAndStartCarnivalDerby()`, `setupAndStartMonsterMash()`, `setupAndStartReefRoyale()` |
| `settings_helpers.dart` | Settings toggle/slider manipulation | `toggleTargetTagTeamMode()`, `setMonsterMashHealthMax()`, per-game settings |
| `save_resume_helpers.dart` | Save/resume test patterns | `navigateToGameScreen()`, `preSaveGame()`, `preSaveTwoGames()`, `GameSaveConfig` factories |

### Specialized Helpers

| File | Purpose | Key Functions |
|------|---------|---------------|
| `edit_score_helpers.dart` | Edit score dialog operations | `openEditScore()`, `setDartInEditScore()`, `updateScore()` |
| `results_helpers.dart` | Results screen verification | `verifyWinnerDisplay()`, `verifyPlayerStats()` |
| `play_to_complete_helpers.dart` | Play-to-complete test support | Auto-play test utilities |
| `text_entry_helper.dart` | Text input simulation | `enterText()` for player name fields |

## Decision Tree: Where Does My Helper Belong?

```
Is this a dart-throwing mechanic (throw, miss, bullseye, remove darts)?
  → DartThrowHelpers (dart_throw_helpers.dart)

Is this game setup (navigate to menu, configure settings, add players, start)?
  → GameSetupHelpers (game_setup_helpers.dart)

Is this a settings toggle or slider?
  → SettingsHelpers (settings_helpers.dart)

Is this save/resume boilerplate (pre-save, navigate to saved game)?
  → SaveResumeHelpers (save_resume_helpers.dart)

Is this a game-specific win condition or scoring sequence?
  → Game's own _helpers.dart (e.g., integration_test/clockwork_quest/gameplay/_helpers.dart)

Is this a game-specific visual assertion (dart indicator color, badge, buff panel)?
  → Game's own _helpers.dart

Is this a game-specific provider shortcut for complex assertions?
  → Game's own _helpers.dart
```

## Game-Specific `_helpers.dart` Convention

Each game's test subdirectories (gameplay, navigation, results, save_resume, etc.) have a `_helpers.dart` file. These files follow a **delegate pattern**:

1. **Import shared helpers** — never copy function bodies
2. **One-line delegates** — wrap shared functions to preserve local function names
3. **Game-specific logic only** — keep functions that can't be generalized

### Template `_helpers.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.yourGame();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  // Add game-specific settings parameters here
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartYourGame(
      tester,
      config,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
}) async {
  // Game-specific dart sequences to reach win condition
  // This logic is unique per game and cannot be shared
}
```

### Save/Resume `_helpers.dart` Template

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

final config = GameUIConfig.yourGame();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> throwOneDart(WidgetTester tester) =>
    DartThrowHelpers.throwDartViaMock(tester, 20); // Use appropriate first target

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.yourGame());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.yourGame(),
      GameSaveConfig.yourGameSecond(),
    );
```

## Adding Shared Helpers for a New Game

When creating a new game, extend these shared files:

### 1. `game_ui_config.dart`
Add a factory constructor:
```dart
factory GameUIConfig.yourGame() => GameUIConfig(
  gameName: 'Your Game',
  menuRoute: '/your_game_menu',
  // ... game-specific UI keys and routes
);
```

### 2. `game_setup_helpers.dart`
Add a setup function:
```dart
static Future<void> setupAndStartYourGame(
  WidgetTester tester,
  GameUIConfig config, {
  // Game-specific settings parameters
  List<String>? playerNames,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  // Toggle settings as needed
  final names = playerNames ?? ['Player A', 'Player B'];
  for (final name in names) {
    await UITestHelpers.addPlayer(tester, name, config);
  }
  await UITestHelpers.startGame(tester, config);
}
```

### 3. `save_resume_helpers.dart`
Add `GameSaveConfig` factories:
```dart
factory GameSaveConfig.yourGame() => GameSaveConfig(
  gameType: 'your_game',
  gameModeName: 'Your Game',
  // ... game-specific save metadata
);
factory GameSaveConfig.yourGameSecond() => GameSaveConfig(
  // Second config for preSaveTwoGames tests
);
```

### 4. `settings_helpers.dart`
Add settings manipulation functions:
```dart
static Future<void> toggleYourGameSomeSetting(WidgetTester tester) async {
  // Find and toggle the setting widget
}
```

### 5. `provider_helpers.dart`
Add provider access functions:
```dart
static YourGameProvider getYourGameProvider(WidgetTester tester) {
  // Access provider from widget tree
}
```

### 6. Sync to `test/shared/`
Copy all additions to the corresponding files in `test/shared/`.

## Related Documentation

- [Test Maintenance](test-maintenance.md) — synchronization rules
- [UI Automation](ui-automation.md) — running UI tests
- [Adding New Games](../development/adding-games.md) — full game creation guide
