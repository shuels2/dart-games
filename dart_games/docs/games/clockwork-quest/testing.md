# Clockwork Quest - Testing

## Test Summary

**Total Tests:** 77 tests
- **Non-UI Tests:** 29 tests (model, provider, announcements)
- **UI Automation Tests:** 48 tests (7 test files, ~34 minutes runtime)

## Non-UI Tests

Location: `test/screens/games/clockwork_quest/`

### Test Files

#### 1. clockwork_quest_game_test.dart (29 tests)
Tests the `ClockworkQuestGame` model and core game logic.

**Coverage:**
- Model initialization with all 4 options
- Target progression logic (sequential 1-20)
- Bullseye mode (gear 21)
- D/T Count option (doubles/triples advancing 2/3 gears)
- Speed mode (2 darts instead of 3)
- Lap tracking and completion
- Win condition detection
- Serialization (toJson/fromJson)

**Key Test Cases:**
- `includeBullseye sets maxTarget to 21`
- `without includeBullseye, maxTarget is 20`
- `initial state has all players at gear 1`
- `hitting correct target advances player`
- `hitting wrong target does not advance`
- `doubleTriplesCount option allows doubles and triples`
- `without doubleTriplesCount, only singles count`
- `completing required laps wins the game`
- `multiple laps required to win`
- `speedMode reduces maxDartsPerTurn to 2`

#### 2. clockwork_quest_announcement_test.dart (18 tests)
Tests announcement logic and sound effects.

**Coverage:**
- All 14 announcement events
- Sound effect assignments
- MAX 2 announcements rule
- Announcement priority ordering
- Text generation with player names

**Key Test Cases:**
- `Game Start announcement`
- `Player Turn announcement`
- `Gear Activated announcement`
- `Double Advance announcement`
- `Triple Advance announcement`
- `Miss announcement`
- `Bullseye Target announcement`
- `Bullseye Hit announcement`
- `Halfway milestone announcement`
- `Near Victory announcement`
- `Lap Complete announcement`
- `Speed Mode Time Expiry announcement`
- `Victory announcement`
- `Remove Darts announcement`

## UI Automation Tests

Location: `integration_test/clockwork_quest/`

Run with: `./run_ui_tests.bat clockwork_quest`

### Test Files

#### 1. clockwork_quest_add_player_test.dart (6 tests, ~4 min)
Tests player addition and selection functionality.

**Coverage:**
- Navigation to menu
- Add Player dialog operations
- Player selection/deselection
- Start button enable/disable states
- Player name validation
- Maximum player count (8)

#### 2. clockwork_quest_menu_and_settings_test.dart (8 tests, ~5 min)
Tests menu screen and all 4 game settings.

**Coverage:**
- Include Bullseye toggle
- D/T Count toggle
- Speed Mode toggle
- Number of Laps dropdown (1-5)
- Settings persistence
- Start game with various configurations
- Navigation to game screen

#### 3. clockwork_quest_gameplay_test.dart (14 tests, ~8 min)
Tests core gameplay mechanics and win conditions.

**Coverage:**
- Sequential target advancement (1→2→3...→20)
- Bullseye mode (must hit gear 21 after 20)
- D/T Count ON (double advances 2, triple advances 3)
- D/T Count OFF (only singles count)
- Speed Mode (2 darts per turn)
- Multiple laps (reset to gear 1 after completing circuit)
- Win detection (complete all gears in all laps)
- Dart processing with mock API

#### 4. clockwork_quest_edit_score_test.dart (4 tests, ~3 min)
Tests manual score editing functionality.

**Coverage:**
- Edit score button appears after 3 darts
- Edit score dialog opens with current darts
- Cancel preserves original progress
- Edit recalculates target progression

#### 5. clockwork_quest_results_test.dart (5 tests, ~4 min)
Tests results screen and navigation.

**Coverage:**
- Results screen shows after game completion
- Winner name displayed
- Play Again returns to game screen
- Change Settings returns to menu
- Back to Menu returns to home

#### 6. clockwork_quest_save_resume_test.dart (10 tests, ~7 min)
Tests save/resume game functionality.

**Coverage:**
- Back button with 0 darts navigates without save modal
- Back button after progress shows save modal
- Don't Save navigates without saving
- Save button saves game
- Resume Game modal shows when saved games exist
- Resume Game loads correct game state
- Start New Game dismisses modal
- Delete individual saved game
- Delete all saved games
- Resumed game auto-deletes on completion

#### 7. clockwork_quest_screenshot_test.dart (1 test, ~3 min)
Captures 18 screenshots for visual validation.

**Screenshots:**
1. Menu default state
2. Include Bullseye ON
3. D/T Count ON
4. Speed Mode ON
5. Number of Laps = 3
6. Menu with players ready
7. Game start (default settings)
8. After first dart (gear advancement)
9. Three darts thrown
10. Takeout modal
11. Player 2 turn
12. Mid-game progression
13. Final gear (near victory)
14. Results screen (standard mode)
15. Menu with Bullseye enabled
16. Game with Bullseye mode
17. Bullseye hit
18. Results screen (bullseye win)

## Running Tests

### All Non-UI Tests
```bash
flutter test test/screens/games/clockwork_quest/
```

### All UI Tests
```bash
./run_ui_tests.bat clockwork_quest
```

### Individual UI Test Files
```bash
# Add player tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/clockwork_quest/clockwork_quest_add_player_test.dart -d chrome

# Menu and settings tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/clockwork_quest/clockwork_quest_menu_and_settings_test.dart -d chrome

# Gameplay tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/clockwork_quest/clockwork_quest_gameplay_test.dart -d chrome

# Edit score tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/clockwork_quest/clockwork_quest_edit_score_test.dart -d chrome

# Results tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/clockwork_quest/clockwork_quest_results_test.dart -d chrome

# Save/resume tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/clockwork_quest/clockwork_quest_save_resume_test.dart -d chrome

# Screenshot test (uses different driver)
flutter drive --driver=test_driver/screenshot_test.dart --target=integration_test/clockwork_quest/clockwork_quest_screenshot_test.dart -d chrome
```

## Test Coverage

### Spec Section 7 Options Coverage

All 4 options have 100% test coverage (non-UI + UI):

| Option | Non-UI Tests | UI Tests |
|--------|--------------|----------|
| Include Bullseye | ✓ Model test | ✓ Gameplay test #7 |
| D/T Count | ✓ Model tests (2) | ✓ Gameplay tests #4-6 |
| Speed Mode | ✓ Model test | ✓ Menu test #4 |
| Number of Laps | ✓ Model tests (2) | ✓ Gameplay test #14 |

### Code Coverage

**Models:** 100% (all methods tested)
**Providers:** ~95% (core logic fully tested, some edge cases)
**Announcements:** 100% (all 14 events tested)
**Screens:** ~85% (visual elements not unit-tested, covered by UI tests)

## Test Helpers

### Shared Test Utilities

Location: `integration_test/shared/`

**ElementFinders:**
- 18 Clockwork Quest-specific finders
- Menu, game, and results screen elements

**GameUIConfig:**
- `GameUIConfig.clockworkQuest()` factory
- Provides game-specific element getters

**ProviderHelpers:**
- `getClockworkQuestProvider()`
- `getClockworkQuestPlayerCurrentTarget()`
- `getClockworkQuestPlayerLapsCompleted()`
- `isClockworkQuestGameActive()`
- `getClockworkQuestCurrentPlayerId()`
- `getClockworkQuestCurrentPlayerDartsThrown()`
- `setClockworkQuestPlayerTarget()` (test utility)

**SettingsHelpers:**
- `toggleClockworkQuestIncludeBullseye()`
- `toggleClockworkQuestDoubleTriplesCount()`
- `toggleClockworkQuestSpeedMode()`
- `selectClockworkQuestLaps()`
- `addClockworkQuestPlayer()`

## CI/CD Integration

All tests run as part of the build pipeline:

1. **Pre-build:** `flutter test` (all 672 non-UI tests must pass)
2. **Optional:** UI automation tests can be run selectively
3. **Pre-deployment:** Manual visual validation via screenshot test

## Known Issues

None. All tests passing at 100% rate.
