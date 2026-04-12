# Clockwork Quest - Testing

## Test Summary

**Total Tests:** 189 tests
- **Non-UI Tests:** 84 tests (66 game logic + 18 announcements)
- **UI Automation Tests:** 105 tests (7 test files, ~57 minutes runtime)

## Non-UI Tests

Location: `test/screens/games/clockwork_quest/`

### Test Files

#### 1. clockwork_quest_game_test.dart (66 tests)
Tests the `ClockworkQuestGame` model and core game logic.

**Coverage:**
- Model initialization with all options
- Target progression logic (sequential 1-20)
- Bullseye mode (gear 21)
- Speed mode (any order hits)
- Lap tracking and completion
- Win condition detection
- Multi-player games (2-8 players)
- Inventor character assignments
- Edit score with speed mode and bullseye
- Full game completion with all option permutations
- Edge cases (serialization, clearGame, ignored inputs)
- Serialization (toJson/fromJson)

**Key Test Groups:**
- Basic mechanics (initialization, target advancement, misses, laps)
- Multi-player (3-player init, 8-player init, turn cycling, varied winners, 8-player completion)
- Inventor assignments (unique per player, all 8 assigned, valid image paths, correct type)
- Edit score in speed mode (restore targets, add new gears, clear on all misses)
- Edit score with bullseye (restore bullseye target, change miss to bull completes game)
- Full game completion (bullseye, speed mode, speed+bullseye, 3-lap, 3-lap+bullseye, speed+3-laps, speed+bullseye+2-laps)
- Edge cases (bull without includeBullseye, speed+bull edges, ignored during takeout/finished, empty sector, future/previous target, clearGame, serialization roundtrip)

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

#### 1. clockwork_quest_add_player_test.dart (10 tests, ~4 min)
Tests player addition, selection, and dialog validation.

**Coverage:**
- Navigation to Clockwork Quest menu
- Add player with name shows in player list
- Add multiple players (3 players)
- Add Player dialog has required UI elements (name field, add/cancel buttons)
- Add player with empty name is rejected
- Add player with whitespace-only name is rejected
- Cancel add player dialog closes without adding
- Added player can be selected
- Select and deselect player toggle
- Remove player from selected list

#### 2. clockwork_quest_menu_and_settings_test.dart (20 tests, ~7 min)
Tests menu screen, all game settings, and start game configurations.

**Coverage:**
- Menu screen shows all settings controls (Include Bullseye, Speed Mode, Number of Laps)
- Default settings are correct (Bullseye OFF, Speed OFF, 1 Lap)
- Toggle Include Bullseye ON and OFF
- Toggle Speed Mode ON and OFF
- Change Number of Laps to 3 and cycle through all values (2-5)
- Enable Bullseye + Speed Mode together
- Enable all options (Bullseye + Speed + 5 Laps)
- Start button disabled with 0 players and 1 player
- Start button enabled with 2 players
- Start game with default settings, Bullseye, Speed Mode, 3 Laps, all options
- Back button returns to home screen
- Resume game button is present

#### 3. clockwork_quest_gameplay_test.dart (36 tests, ~17 min)
Tests core gameplay mechanics, all options, multi-player, and end-to-end games.

**Coverage:**
- Game starts with correct initial state
- Hit correct target advances gear, wrong target does not
- Sequential progression 1 through 3
- Three darts triggers takeout prompt
- Turn advances after darts removed
- Skip turn advances to next player
- Dart indicators update after each throw
- Gear widgets transition from inactive to active
- Opponent tiles visible on game screen
- Double/Triple on correct target still advances 1 gear (normal mode)
- Bullseye ON: must hit bull after 20, hitting bull at 21 completes lap
- Bullseye OFF: hitting 20 wins game
- Bullseye ON: gear 21 widget shown as inactive
- Speed mode: any gear number counts, already activated gear ignored
- Speed mode: completing all gears wins
- Speed mode with bullseye: must also hit bull
- 2 laps: completing 1 lap resets target, completing both laps wins
- Lap counter visible when laps > 1, hidden when laps = 1
- Full game: P1 wins with sequential hits
- 3-player game: opponent tiles visible for both opponents
- 4-player game: turn cycles through all 4 players
- Full game with bullseye: P1 wins after hitting bull
- Full game with speed mode: P1 wins hitting gears in any order
- 3-player game completes and shows results screen

#### 4. clockwork_quest_edit_score_test.dart (11 tests, ~6 min)
Tests manual score editing with all game modes.

**Coverage:**
- Edit score button appears after 3 darts, not visible before
- Edit score dialog opens with all elements
- Cancel edit score closes dialog
- Cancel edit score preserves target progression
- Edit score changes misses to hits (advance target)
- Edit score changes hits to misses (revert target)
- Edit score with partial changes (2 hits, 1 miss)
- Edit score in speed mode changes completed gears
- Edit score in speed mode adds new gears from misses
- Edit score at bullseye target changes miss to Bull, completing game

#### 5. clockwork_quest_results_test.dart (11 tests, ~9 min)
Tests results screen display, navigation, and multi-player results.

**Coverage:**
- Results screen shows after game completion with all 3 action buttons
- Winner name and title displayed on results screen
- Rankings list shows all players with individual rank tiles
- Play Again returns to game screen with same players
- Change Settings returns to menu with settings visible
- Change Settings preserves players from game
- Leave Tower returns to home screen
- Results screen after bullseye game shows winner
- Results screen with 3 players shows all in rankings
- Results with 3 players — Play Again preserves all 3 players

#### 6. clockwork_quest_save_resume_test.dart (16 tests, ~10 min)
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
- Save and resume preserves all game settings
- Save and resume preserves player progress
- Multiple saved games listed independently
- Resume game button enabled/disabled states
- Cancel save modal returns to game
- Save modal shows correct player names

#### 7. clockwork_quest_screenshot_test.dart (1 test, ~4 min)
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

All 3 implemented options have 100% test coverage (non-UI + UI):

| Option | Non-UI Tests | UI Tests |
|--------|--------------|----------|
| Include Bullseye | ✓ Game logic (multiple) | ✓ Gameplay #15-18, Edit Score #11, Results #9 |
| Speed Mode | ✓ Game logic (multiple) | ✓ Gameplay #19-22, #35, Edit Score #9-10 |
| Number of Laps | ✓ Game logic (multiple) | ✓ Gameplay #24-26 |

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

1. **Pre-build:** `flutter test` (all 727 non-UI tests must pass)
2. **Optional:** UI automation tests can be run selectively
3. **Pre-deployment:** Manual visual validation via screenshot test

## Known Issues

None. All tests passing at 100% rate.
