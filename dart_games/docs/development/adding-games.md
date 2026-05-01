# Adding New Games

## Overview

This guide walks you through creating a new game for the Dart Games container app. Follow these steps to ensure proper integration with all shared systems.

## Prerequisites

Before starting:
- Familiarity with Flutter and Dart
- Understanding of the [Container App Architecture](../architecture/container-app.md)
- Knowledge of [Shared Systems](../architecture/shared-systems.md)
- Review existing games (Carnival Derby, Target Tag) as references

## Step-by-Step Guide

### 1. Create Game Directory Structure

Create your game's directory in the games folder:

```bash
mkdir -p lib/screens/games/your_game
```

### 2. Design Unique Visual Identity

Each game should have its own distinct theme:

**Define your game's:**
- Color palette (primary, secondary, accent colors)
- Typography (fonts from Google Fonts)
- Visual style (modern, retro, playful, technical, etc.)
- Animation style
- UI patterns

**Document in:** `docs/games/your_game/design-system.md`

**Examples:**
- Carnival Derby: Yellow/amber carnival theme, Montserrat/Bangers fonts
- Target Tag: Pink/green neon tech theme, Fredoka font

### 3. Create Game Screens

Create three core screens:

#### Menu Screen
**File:** `lib/screens/games/your_game/your_game_menu_screen.dart`

**Purpose:** Game setup and configuration

**Components:**
- Player selection (use `PlayerProvider.selectedPlayers`)
- Game settings (difficulty, mode, target score, etc.)
- Add player button (use `AddPlayerDialog` component)
- Start game button

**Key Integration:**
```dart
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/add_player/add_player.dart';

// Player selection
final playerProvider = Provider.of<PlayerProvider>(context);
final players = playerProvider.allPlayers;

// Add player
final player = await showAddPlayerDialog(
  context: context,
  config: AddPlayerDialogConfig.yourGame(),
);
```

#### Game Screen
**File:** `lib/screens/games/your_game/your_game_game_screen.dart`

**Purpose:** Active gameplay

**Components:**
- Game board/play area
- Player status displays
- Turn management
- Dartboard emulator (use shared components)
- Action buttons (skip turn, edit score, etc.)

**Key Integration:**
```dart
import '../../../providers/dartboard_provider.dart';
import '../../../providers/your_game_provider.dart';
import '../../../widgets/dartboard_emulator/dartboard_emulator.dart';

// Dartboard integration
final dartboardProvider = Provider.of<DartboardProvider>(context);

// Dartboard emulator
DartboardEmulatorSection(
  controller: _dartboardEmulatorController,
  isConnected: !dartboardProvider.isEmulator,
  config: DartboardSectionConfig.yourGame(),
  // ... handlers
)
```

#### Results Screen
**File:** `lib/screens/games/your_game/your_game_results_screen.dart`

**Purpose:** Winner announcement and game summary

**Components:**
- Winner display
- Game statistics
- Play again button
- Change settings button
- Victory music playback

**Key Integration:**
```dart
import '../../../services/victory_music_service.dart';

// Play victory music
final musicService = VictoryMusicService();
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  // Play music
}
```

### 4. Create Game Provider

**File:** `lib/providers/your_game_provider.dart`

**Purpose:** Manage game state

```dart
import 'package:flutter/foundation.dart';
import '../models/your_game_game.dart';

class YourGameProvider with ChangeNotifier {
  YourGameGame? _currentGame;

  YourGameGame? get currentGame => _currentGame;

  void startGame(List<String> playerIds, /* settings */) {
    _currentGame = YourGameGame(
      id: DateTime.now().toString(),
      startedAt: DateTime.now(),
      playerIds: playerIds,
      // ... initialize game state
    );
    notifyListeners();
  }

  void processDartThrow(int score, int multiplier) {
    // Update game state
    notifyListeners();
  }

  bool checkWinCondition() {
    // Check if game is won
    return false;
  }

  void advanceTurn() {
    // Move to next turn
    notifyListeners();
  }
}
```

### 5. Create Game Model

**File:** `lib/models/your_game_game.dart`

**Purpose:** Data structure for game state

```dart
class YourGameGame {
  final String id;
  final DateTime startedAt;
  final List<String> playerIds;
  // ... game-specific state

  YourGameGame({
    required this.id,
    required this.startedAt,
    required this.playerIds,
    // ... initialize fields
  });

  // Serialization methods if needed
  Map<String, dynamic> toJson() { /* ... */ }
  factory YourGameGame.fromJson(Map<String, dynamic> json) { /* ... */ }
}
```

### 6. Integrate with Global Systems

**REQUIRED INTEGRATIONS:**

See [Game Integration Requirements](game-integration.md) for complete details.

**Summary:**
- ✅ Use `PlayerProvider` for user management
- ✅ Use `GameAnnouncementQueueService` for announcements
- ✅ Use `VictoryMusicService` for victory music
- ✅ Use `DartboardProvider` for dart input
- ✅ Create announcement helper class
- ✅ Update player stats for ALL players (winners and losers)
- ✅ Track game duration

### 7. Organize Game Assets

Create asset folders:

```bash
mkdir -p assets/games/your_game/icons
mkdir -p assets/games/your_game/images
mkdir -p assets/games/your_game/sounds
```

Place all game assets in these folders. See [Asset Organization](asset-organization.md) for details.

### 8. Create Component Configurations

Create factory methods for shared components:

**File:** `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`

```dart
// Add to DartboardSectionConfig class
factory DartboardSectionConfig.yourGame() {
  return DartboardSectionConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    // ... other styling
  );
}

// Add to DartboardFABConfig class
factory DartboardFABConfig.yourGame() {
  return DartboardFABConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    // ... other styling
  );
}
```

**File:** `lib/widgets/add_player/add_player_dialog_config.dart`

```dart
// Add to AddPlayerDialogConfig class
factory AddPlayerDialogConfig.yourGame() {
  return AddPlayerDialogConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    // ... other styling
  );
}
```

**File:** `lib/widgets/edit_score/edit_score_dialog_config.dart`

```dart
// Add to EditScoreDialogConfig class
factory EditScoreDialogConfig.yourGame() {
  return EditScoreDialogConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    // ... other styling
  );
}
```

**File:** `lib/widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart`

```dart
// Add to DartboardPausedModalConfig class
factory DartboardPausedModalConfig.yourGame() {
  return DartboardPausedModalConfig(
    backgroundColor: const Color(0xYOURCOLOR),
    borderColor: const Color(0xYOURCOLOR),
    boxShadowColor: const Color(0xYOURCOLOR),
    boxShadowOpacity: 0.3,
    iconColor: const Color(0xYOURCOLOR),
    titleTextStyle: GoogleFonts.yourFont(
      color: const Color(0xYOURCOLOR),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    messageTextStyle: GoogleFonts.yourFont(
      color: Colors.white,
      fontSize: 18,
    ),
  );
}
```

### 9. Implement Play to Complete Strategy

Create a strategy for auto-playing the game to completion:

**File:** `lib/services/play_to_complete/your_game_strategy.dart`

```dart
import '../../widgets/dartboard_emulator/play_to_complete_strategy.dart';
import '../../providers/your_game_provider.dart';

class YourGameStrategy implements PlayToCompleteStrategy {
  @override
  bool isGameComplete(BuildContext context) {
    return context.read<YourGameProvider>().hasWinner;
  }

  @override
  bool shouldAutoTakeout(BuildContext context) {
    return context.read<YourGameProvider>().shouldPromptTakeout;
  }

  @override
  SimulatedThrow? getNextThrow(BuildContext context) {
    // Read current game state and settings from provider
    // Return the optimal throw for the current situation
    // Return null if game is done
  }
}
```

**Also add:**
- `PlayToCompleteButtonConfig.yourGame()` factory in `dartboard_emulator_config.dart`
- Wire strategy + runner into game screen (see [Dartboard Emulator - Play to Complete](dartboard-emulator.md#play-to-complete))
- Add auto-play guards on announcement/takeout delay chains in game screen

### 10. Create Announcement Helper

**File:** `lib/services/your_game_announcement_helper.dart`

See [Announcement System Integration](announcement-system.md) for complete guide.

### 11. Create Sound Effects Service (Optional)

**File:** `lib/services/your_game_sound_effects.dart`

```dart
class YourGameSoundEffects {
  static const String _basePath = 'assets/games/your_game/sounds/';

  static const SoundEffectConfig soundEffect1 = SoundEffectConfig(
    assetPath: '${_basePath}SoundEffect1.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );
}
```

### 12. Add Widget Keys for Testing

**File:** `lib/constants/test_keys.dart`

```dart
class YourGameMenuKeys {
  static const startButton = Key('menu_yg_start_button');
  static const addPlayerButton = Key('menu_yg_add_player_button');
  static playerTile(String playerId) => Key('menu_yg_player_tile_$playerId');
}

class YourGameGameKeys {
  static const skipTurnButton = Key('game_yg_skip_turn_button');
  // ... other keys
}

class YourGameResultsKeys {
  static const playAgainButton = Key('results_yg_play_again_button');
  // ... other keys
}
```

See [Widget Keys](widget-keys.md) for complete guide.

### 13. Add Game Card to Home Screen

**File:** `lib/screens/home_screen.dart`

```dart
// Add to game cards list
GameCard(
  title: 'Your Game',
  icon: 'assets/games/your_game/icons/icon.png',
  onTap: () {
    Navigator.pushNamed(context, '/your_game_menu');
  },
)
```

### 14. Add Routes

**File:** `lib/main.dart`

```dart
routes: {
  // ... existing routes
  '/your_game_menu': (context) => YourGameMenuScreen(),
  '/your_game_game': (context) => YourGameGameScreen(),
  '/your_game_results': (context) => YourGameResultsScreen(),
}
```

### 15. Create Tests and Run Spec Coverage Audit

Create test files in a game-specific subfolder under `integration_test/`:
- `integration_test/your_game/your_game_menu_test.dart`
- `integration_test/your_game/your_game_gameplay_test.dart`
- `integration_test/your_game/your_game_results_test.dart`
- `integration_test/your_game/your_game_visual_validation_test.dart`
- `integration_test/your_game/your_game_edit_score_test.dart`
- `integration_test/your_game/your_game_showcase_test.dart`
- `test/screens/games/your_game/your_game_game_test.dart`
- `test/screens/games/your_game/your_game_user_management_test.dart`

Follow patterns from existing games.

#### Mandatory Results Screen UI Tests

The results screen UI tests MUST cover all three of the following. Unit tests alone are not sufficient — each of these bugs is invisible to unit tests but caught only by the full UI flow:

**1. Exit button navigates to game selection (not root route)**
Complete a game → click the exit/leave button → assert multiple game cards are visible. Use at least three game card assertions (e.g. `getCarnivalDerbyCard()`, `getTargetTagCard()`, `getMonsterMashCard()`). A single-card assertion is a false positive because `pushNamedAndRemoveUntil('/')` also shows the home screen in the test environment. The implementation must use `Navigator.popUntil(context, (route) => route.isFirst)` — using `pushNamedAndRemoveUntil('/')` navigates to the dartboard registration page in real use.

**2. Player stats updated after victory**
Complete a game → land on results screen → pump extra time for async API calls → read `PlayerProvider` via `ProviderHelpers.findPlayerByName` → assert winner has `gamesPlayed == 1`, `gamesWon == 1`, and a `gameHistory` entry with the correct `gameName`; assert every loser has `gamesPlayed == 1`, `gamesWon == 0`. If `_updatePlayerStats()` is accidentally omitted from `initState`, stats stay at 0 and this test fails — but the non-UI user management test still passes.

**3. Victory music triggered after victory**
`resetServerState()` resets `VictoryMusicService._initialized` to `false`. After the results screen loads, assert `VictoryMusicService().isInitialized == true`. This proves `_playVictoryMusic()` called `getRandomMusicSource()` → `initialize()` from `initState`. If `_playVictoryMusic()` is accidentally omitted, `isInitialized` stays `false` and the test fails.

See `integration_test/clockwork_quest/results/winner_stats_updated_test.dart` for the reference implementation of tests 2 and 3, and `integration_test/clockwork_quest/results/leave_tower_test.dart` for test 1.

#### User Management Non-UI Tests

Also create `test/screens/games/your_game/your_game_user_management_test.dart` following the pattern in `test/screens/games/clockwork_quest/clockwork_quest_user_management_test.dart`. This test validates the `updatePlayerStats` business logic in isolation (winner/loser flags, duration, game name, persistence across reload). It complements but does not replace the UI flow test above.

**MANDATORY: After writing tests, run a Spec Coverage Audit.**
Cross-reference EVERY option from spec Section 7 and EVERY visual element from Section 10 against actual test files. For each option, verify there is at least one non-UI test AND one UI test that exercises it. Write any missing tests before proceeding. See [Spec Coverage Audit](../testing/spec-coverage-audit.md) for the full procedure.

### 16. Create Game Documentation

Copy the game template:

```bash
cp -r docs/games/_GAME_TEMPLATE docs/games/your_game
```

Fill out all 8 template files:
- README.md
- game-rules.md
- design-system.md
- components.md
- announcements.md
- testing.md
- assets.md
- implementation-notes.md

### 17. Check for Data Migration Needs

If your game changes the shape of any existing server-side SQLite schema (renaming columns, changing field types in shared models like Player or SavedGameMetadata), you must add a data migration. Adding new columns or new optional fields with defaults does NOT require a migration.

See [Data Migrations](data-migrations.md) for how to add one.

### 18. Update Main Documentation

Update `CLAUDE.md` with:
- New test counts
- Link to your game documentation
- Any game-specific critical notes

### 19. Test Everything

**Run all tests:**
```bash
flutter test
```

**Run UI automation tests:**
```bash
./run_ui_tests.bat your_game
```

**Update parallel test runner:**
Add your game name to the `GAMES` variable in `run_ui_tests_parallel.bat`.
Ports are assigned automatically. See [UI Automation - Adding a New Game](../testing/ui-automation.md#adding-a-new-game-to-parallel-tests).

**Run Play to Complete tests:**
```bash
./run_ui_tests_parallel.bat your_game/play_to_complete
```

**Manual testing:**
- Test on web
- Test on tablet (if available)
- Test all game modes
- Test edge cases
- Test Play to Complete with default and non-default settings

### 20. Commit Your Work

```bash
git add .
git commit -m "Add [Your Game] to Dart Games

- Implemented 3 screens (menu, game, results)
- Created game provider and model
- Integrated with all shared systems
- Added tests ([N] UI tests, [M] non-UI tests)
- Created game documentation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## Checklist

Use this checklist to ensure complete integration:

- [ ] Created game directory structure
- [ ] Designed unique visual identity
- [ ] Created menu, game, and results screens
- [ ] Created game provider
- [ ] Created game model
- [ ] Integrated with PlayerProvider
- [ ] Integrated with GameAnnouncementQueueService
- [ ] Integrated with VictoryMusicService
- [ ] Integrated with DartboardProvider
- [ ] Created announcement helper
- [ ] Organized game assets
- [ ] Created component configurations
- [ ] Created sound effects service (if needed)
- [ ] Added widget keys
- [ ] Added game card to home screen
- [ ] Added routes
- [ ] Created all tests
- [ ] Created game documentation (8 files)
- [ ] Updated main CLAUDE.md
- [ ] All tests pass (272+ non-UI tests)
- [ ] Manually tested on web
- [ ] Manually tested on tablet (if available)

## Reference Implementations

- **Carnival Derby:** `lib/screens/games/carnival_horse_race/`
- **Target Tag:** `lib/screens/games/target_tag/`

## Related Documentation

- [Game Integration Requirements](game-integration.md)
- [Asset Organization](asset-organization.md)
- [Announcement System Integration](announcement-system.md)
- [Dartboard Emulator Integration](dartboard-emulator.md)
- [Add Player Dialog Integration](add-player-dialog.md)
- [Edit Score Dialog Integration](edit-score-dialog.md)
- [Widget Keys](widget-keys.md)
