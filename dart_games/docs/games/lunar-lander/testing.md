# Lunar Lander - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** 131 (85 non-UI + 46 UI automation)
- **Non-UI Tests:** 85 tests across 4 files
- **UI Automation Tests:** 46 tests across 9 subdirectories (~61 minutes)

## Non-UI Tests

**Location:** `test/screens/games/lunar_lander/`, `test/models/`, `test/providers/`

### 1. lunar_lander_game_test.dart (33 tests)
`test/screens/games/lunar_lander/lunar_lander_game_test.dart`

Tests the `LunarLanderGame` model and core game logic via the `LunarLanderProvider`.

**Coverage:**
- Basic scoring: single, double, triple, outer bull, inner bull subtraction
- Altitude decreases correctly across darts and across turns
- Starting altitude initialization (100, 200, 300, 500)
- Rocket position proportional to altitude
- Hard Landing ON: bust behavior, turn voided and altitude reverts
- Hard Landing ON: remaining darts forfeited after bust
- Hard Landing ON: exact 0 is valid win (not a bust)
- Hard Landing ON: multiple busts across turns
- Hard Landing OFF: negative altitude allowed
- Hard Landing OFF: can continue playing from negative altitude
- Hard Landing OFF: can win from negative altitude
- Turn advancement after 3 darts
- Skip turn with and without darts thrown
- Win condition: first player to altitude 0
- Win with multiple players (2-8)
- Exact 0 wins immediately mid-turn
- Edit score updates altitude correctly
- Edit score can change game outcome

**Run:**
```bash
flutter test test/screens/games/lunar_lander/lunar_lander_game_test.dart
```

### 2. lunar_lander_announcement_test.dart (33 tests)
`test/screens/games/lunar_lander/lunar_lander_announcement_test.dart`

Tests the `LunarLanderAnnouncementHelper` including all announcement events, sound effect assignments, stacking precedence, and the max-2-announcements rule.

**Coverage:**
- All 10 announcement events (game start, player turn, standard descent, big descent, miss, near landing, crash landing, negative altitude, climbing back, touchdown)
- Sound effect assignments for each event
- Stacking precedence chain (Touchdown beats Crash Landing beats Climbing Back beats Negative Altitude beats Near Landing beats Big Descent beats Standard Descent beats Miss)
- Max 2 announcements per dart event enforcement
- "Remove your darts" always plays (unconditional)
- Priority level assignments (turnTransition, hitConfirm, statusChange, victory)
- Text generation with player names and altitude values

**Run:**
```bash
flutter test test/screens/games/lunar_lander/lunar_lander_announcement_test.dart
```

### 3. lunar_lander_game_serialization_test.dart (12 tests)
`test/models/lunar_lander_game_serialization_test.dart`

Tests `LunarLanderGame.toJson()` and `LunarLanderGame.fromJson()` round-trip serialization.

**Coverage:**
- Full game state serialization and deserialization
- Starting altitude preserved across serialization
- Hard landing enabled flag preserved
- Per-player altitude values preserved
- Turn start altitude snapshot preserved (for bust reversion)
- Current player index preserved
- Dart throw history preserved
- Winner state preserved
- Character assignments preserved
- Default values on deserialization

**Run:**
```bash
flutter test test/models/lunar_lander_game_serialization_test.dart
```

### 4. lunar_lander_save_restore_test.dart (7 tests)
`test/providers/lunar_lander_save_restore_test.dart`

Tests the Save & Resume lifecycle for `LunarLanderProvider`.

**Coverage:**
- Save game metadata creation (game name, player names, current player, turn count)
- Full game state restore via `SaveGameService`
- Gameplay continuation after restore (darts still count, altitudes correct)
- `resumedSavedGameId` lifecycle (set on resume, cleared on game completion)
- Restored game correctly reflects Hard Landing setting
- Restored altitude values match saved state

**Run:**
```bash
flutter test test/providers/lunar_lander_save_restore_test.dart
```

### Run All Lunar Lander Non-UI Tests
```bash
flutter test test/screens/games/lunar_lander/
flutter test test/models/lunar_lander_game_serialization_test.dart
flutter test test/providers/lunar_lander_save_restore_test.dart
```

## UI Automation Tests

**Location:** `integration_test/lunar_lander/`
**Run:** `./run_ui_tests.bat lunar_lander` or `./run_ui_tests_parallel.bat lunar_lander`
**Total:** 46 tests across 9 subdirectories

### Subdirectory Breakdown

| Subdirectory | Tests | Description |
|-------------|-------|-------------|
| `add_player/` | 3 tests | Add Player dialog: navigation, name validation, cancel |
| `edit_score/` | 4 tests | Edit Score dialog: open, change, cancel, verify |
| `gameplay/` | 10 tests | Core gameplay: dart subtraction, turns, bust, win |
| `menu_and_settings/` | 5 tests | Menu defaults, altitude slider, Hard Landing toggle, start |
| `navigation/` | 4 tests | Mandatory navigation tests (back, change settings, etc.) |
| `play_to_complete/` | 5 tests | Play-to-Complete strategy across 5 settings scenarios |
| `results_screen/` | 8 tests | Results display, navigation buttons, stats, victory music |
| `save_resume/` | 6 tests | Save/resume lifecycle |
| `visual_validation/` | 1 test | Screenshot capture (11 game states) |

### add_player/ (3 tests)

**File:** `integration_test/lunar_lander/add_player/`

**Coverage:**
- Navigate from home to Lunar Lander menu
- Add player with name — appears in player list
- Empty name validation rejected
- Whitespace-only name validation rejected (may be combined with above)
- Cancel closes dialog without adding player

### edit_score/ (4 tests)

**File:** `integration_test/lunar_lander/edit_score/`

**Coverage:**
- Edit Score dialog opens from RemoveDartsModal (not from a standalone button)
- Change dart value and save — altitude updates on descent track
- Cancel preserves original dart values
- Edit score miss handling — score=0 maps to 'Miss' display, Save button stays enabled

### gameplay/ (10 tests)

**File:** `integration_test/lunar_lander/gameplay/`

**Coverage:**
- Dart throw subtracts from altitude (single)
- Double hit subtracts correctly (face value x 2)
- Triple hit subtracts correctly (face value x 3)
- Descent track updates after dart (rocket moves down)
- Turn advances after 3 darts
- Skip turn button advances to next player
- Hard Landing ON: bust reverts altitude, crash state shown
- Hard Landing OFF: negative altitude allowed, game continues
- Touchdown at exactly altitude 0
- Multiple players tracked on descent tracks simultaneously

### menu_and_settings/ (5 tests)

**File:** `integration_test/lunar_lander/menu_and_settings/`

**Coverage:**
- Menu initial state: altitude slider at 200, Hard Landing toggle OFF
- Altitude slider can be adjusted (move to 100, 300, 500)
- Hard Landing toggle switches ON and OFF
- Start button disabled with fewer than 2 players
- Start button enabled with 2+ players and navigates to game screen

### navigation/ (4 tests)

**Files:** `integration_test/lunar_lander/navigation/`

These 4 tests are mandatory for every game and catch route stack bugs.

1. **menu_back_to_home_test.dart** — Navigate to Lunar Lander menu, tap back button, verify home screen with 3+ game cards visible. Catches broken menu back navigation.

2. **game_back_settings_persist_test.dart** — Change non-default settings (e.g., Hard Landing ON), start game, tap game back button, verify settings are preserved on menu. Catches settings lost on game-to-menu navigation.

3. **change_settings_back_to_home_test.dart** — Complete game, tap CHANGE MISSION, verify menu shows, tap back, verify home screen with 3+ game cards. Catches `(route) => false` bug that clears Home from route stack.

4. **change_settings_preserves_settings_test.dart** — Complete game, tap CHANGE MISSION, verify altitude and Hard Landing settings plus player selections are preserved on menu. Catches settings/players lost through results-to-menu navigation.

### play_to_complete/ (5 tests)

**Files:** `integration_test/lunar_lander/play_to_complete/`

Tests the `LunarLanderStrategy` Play-to-Complete implementation across different settings scenarios. Each test uses `PlayToCompleteHelpers.tapPlayToComplete()` and `waitForGameCompletion()`.

1. **default_settings_test.dart** — Game completes with default settings (altitude=200, Hard Landing=OFF). Verifies strategy can drive a full game to the results screen.

2. **mid_game_test.dart** — A few darts are thrown manually first to put the game in a mid-game state, then Play-to-Complete finishes the game. Verifies the strategy handles non-fresh game states.

3. **hard_landing_on_test.dart** — Hard Landing enabled. The strategy must avoid busting (never select a dart that would go below the remaining altitude). Verifies the strategy respects the bust rule.

4. **low_altitude_test.dart** — Starting altitude set to 100. Verifies strategy completes a shorter game correctly.

5. **high_altitude_test.dart** — Starting altitude set to 500. Verifies strategy completes a longer game without getting stuck.

### results_screen/ (8 tests)

**Files:** `integration_test/lunar_lander/results_screen/`

**Coverage:**
- Winner display: "MISSION ACCOMPLISHED!" title shown, winner name and character visible
- Rankings list: all players shown, ordered by altitude ascending (closest to 0 first)
- RELAUNCH button: restarts game with same players and settings
- CHANGE MISSION button: returns to menu with settings preserved
- MISSION CONTROL button: returns to home screen (uses `Navigator.popUntil` — home screen verified with 3+ game cards)
- Player stats updated: winner `gamesWon == 1`, losers `gamesWon == 0` (verifies `_updatePlayerStats` was called)
- Victory music triggered: `VictoryMusicService().isInitialized == true` after results screen loads
- Turn count displayed correctly on winner tile

The mandatory 3 results screen tests (exit navigation, player stats, victory music) are all covered.

### save_resume/ (6 tests)

**Files:** `integration_test/lunar_lander/save_resume/`

**Coverage:**
- Back button after dart thrown shows SaveGameModal
- Save game saves correctly, resume shows saved game in modal
- Resumed game state is correct (altitudes match, current player correct) — see Known Issues below
- Completed resumed game auto-deletes saved game
- Saving overwrites existing saved game
- Cancel save returns to game without saving

### visual_validation/ (1 test)

**File:** `integration_test/lunar_lander/visual_validation/lunar_lander_screenshot_test.dart`

Captures 11 screenshots for visual validation. Uses `test_driver/screenshot_test.dart` driver (NOT `integration_test.dart`).

**Screenshots captured:**
1. Menu screen — default settings, no players
2. Menu screen — with 2 players added, ready to start
3. Game screen — start of game, all rockets at top (ORBIT)
4. Game screen — after first dart (rocket has moved)
5. Game screen — Hard Landing badge visible (Hard Landing ON)
6. Game screen — crash animation state (bust, rocket pulling back)
7. Game screen — near landing state (altitude <= 20)
8. Game screen — Remove Darts modal visible
9. Game screen — mid-game, multiple players at various altitudes
10. Results screen — winner display, rankings, 3 buttons
11. Results screen — with multiple players ranked

## Widget Keys Used

### Menu Screen Keys
**Class:** `LunarLanderMenuKeys`
**File:** `lib/constants/test_keys.dart`

| Key | Widget |
|-----|--------|
| `LunarLanderMenuKeys.backButton` | AppBar back button |
| `LunarLanderMenuKeys.altitudeSlider` | Starting Altitude slider |
| `LunarLanderMenuKeys.hardLandingSwitch` | Hard Landing toggle |
| `LunarLanderMenuKeys.startGameButton` | "LAUNCH!" button |
| `LunarLanderMenuKeys.addPlayerButton` | "NEW PLAYER" button (header) |
| `LunarLanderMenuKeys.addPlayerButtonEmptyState` | "NEW PLAYER" button (empty state) |
| `LunarLanderMenuKeys.playerListView` | Player ListView |
| `LunarLanderMenuKeys.playerTile(id)` | Individual player tile |
| `LunarLanderMenuKeys.removePlayerButton(id)` | Player remove button |

### Game Screen Keys
**Class:** `LunarLanderGameKeys`
**File:** `lib/constants/test_keys.dart`

| Key | Widget |
|-----|--------|
| `LunarLanderGameKeys.skipTurnButton` | Skip Turn button in active player panel |
| `LunarLanderGameKeys.editScoreButton` | Edit Score button (inside RemoveDartsModal) |
| `LunarLanderGameKeys.descentTrack(playerId)` | Individual player descent track |
| `LunarLanderGameKeys.rocketIcon(playerId)` | Player rocket on descent track |
| `LunarLanderGameKeys.playerAvatar` | Active player avatar |
| `LunarLanderGameKeys.altitudeReadout` | Active player altitude display |
| `LunarLanderGameKeys.dartIndicator(index)` | Dart indicator slot (0, 1, 2) |
| `LunarLanderGameKeys.hardLandingBadge` | "HARD LANDING" badge |
| `LunarLanderGameKeys.turnSummary` | Current turn summary text |

### Results Screen Keys
**Class:** `LunarLanderResultsKeys`
**File:** `lib/constants/test_keys.dart`

| Key | Widget |
|-----|--------|
| `LunarLanderResultsKeys.winnerName` | Winner name text |
| `LunarLanderResultsKeys.winnerPhoto` | Winner character image |
| `LunarLanderResultsKeys.turnCount` | Winner turn count |
| `LunarLanderResultsKeys.playAgainButton` | "RELAUNCH" button |
| `LunarLanderResultsKeys.changeSettingsButton` | "CHANGE MISSION" button |
| `LunarLanderResultsKeys.backToMenuButton` | "MISSION CONTROL" button |
| `LunarLanderResultsKeys.playerRanking(index)` | Individual ranking row |

### Home Screen
| Key | Widget |
|-----|--------|
| `HomeKeys.lunarLanderCard` | Lunar Lander game card on home screen |

## Test Patterns

### Dart Throw Pattern (UI Tests)
```dart
// Throw T20 (triple 20 = 60 points)
await DartThrowHelpers.throwDart(tester, 'T20');
await PumpSequences.afterDartThrow(tester);

// Remove darts after 3 throws
await DartThrowHelpers.removeDarts(tester);
await PumpSequences.afterRemoveDarts(tester);
```

### Settings Configuration Pattern
```dart
// Set altitude slider to 100
await SettingsHelpers.setLunarLanderAltitude(tester, 100);

// Enable Hard Landing
await SettingsHelpers.toggleLunarLanderHardLanding(tester);
```

### Provider State Verification Pattern
```dart
final provider = ProviderHelpers.getLunarLanderProvider(tester);
expect(provider.currentPlayerAltitude, equals(140)); // 200 - 60
expect(provider.hasWinner, isFalse);
```

## Running Tests

### All Non-UI Tests
```bash
flutter test test/screens/games/lunar_lander/
flutter test test/models/lunar_lander_game_serialization_test.dart
flutter test test/providers/lunar_lander_save_restore_test.dart
```

### All UI Tests (Sequential)
```bash
./run_ui_tests.bat lunar_lander
```

### All UI Tests (Parallel — Recommended)
```bash
./run_ui_tests_parallel.bat lunar_lander
```

### Individual UI Test Subdirectory
```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/lunar_lander/gameplay/ \
  -d chrome
```

### Screenshot Test
```bash
# Use screenshot_test.dart driver, NOT integration_test.dart
flutter drive --driver=test_driver/screenshot_test.dart \
  --target=integration_test/lunar_lander/visual_validation/lunar_lander_screenshot_test.dart \
  -d chrome
```

## Spec Section 7 Options Coverage

| Option | Non-UI Tests | UI Tests |
|--------|--------------|----------|
| Starting Altitude (100/200/300/500) | lunar_lander_game_test.dart (initialization, proportional position) | menu_and_settings (slider), play_to_complete (low/high altitude) |
| Hard Landing ON/OFF | lunar_lander_game_test.dart (bust behavior, revert, negative) | gameplay (bust, negative), menu_and_settings (toggle), play_to_complete (hard_landing_on) |

## Known Issues

### save_resume/resumed_state_correct_test.dart — Infrastructure Flake

**Issue:** This test's logic passes ("All tests passed!" appears in the test log), but `flutter drive` then crashes during chromedriver teardown with `SocketException: errno = 1225`. The runner counts this as a FAILED test even though the actual test assertions all passed.

**Root cause:** This is a known `flutter drive` + chromedriver infrastructure bug that occurs during the driver teardown phase after test completion. It is NOT a Lunar Lander code bug — the game logic, save functionality, and state restoration all work correctly.

**Retry behavior:** The retry logic in both `run_ui_tests.bat` and `run_ui_tests_parallel_worker.bat` detects SocketException crashes. However, both retries hit the same deterministic teardown crash, so this test always shows as FAILED in the runner output.

**Effective pass rate:** 45/46 UI tests pass. The 1 "failing" test is this infrastructure flake.

**Workaround:** Manually inspect the test log to confirm "All tests passed!" before the SocketException. The game's save/resume functionality is also covered by the save_resume integration tests in `test/integration/save_resume_integration_test.dart` (non-UI, 100% pass rate).

**Tests affected:** `integration_test/lunar_lander/save_resume/resumed_state_correct_test.dart` only.
