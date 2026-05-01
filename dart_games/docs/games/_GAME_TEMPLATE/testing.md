# [Game Name] - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** [X UI + Y non-UI = Z total]
- **UI Automation Tests:** [X] tests (~[duration] minutes)
- **Non-UI Tests:** [Y] tests

### Test Files

#### UI Automation Tests
**Location:** `integration_test/[game_name]/`

1. **[game_name]_menu_test.dart** ([N] tests, ~[M] minutes)
   - [Brief description of what this file tests]

2. **[game_name]_gameplay_test.dart** ([N] tests, ~[M] minutes)
   - [Brief description of what this file tests]

3. **[game_name]_results_test.dart** ([N] tests, ~[M] minutes)
   - [Brief description of what this file tests]

#### Non-UI Tests
**Location:** `test/screens/games/[game_name]/`

1. **[game_name]_game_with_announcements_test.dart** ([N] tests)
   - [Brief description of what this file tests]

2. **[game_name]_user_management_test.dart** ([N] tests)
   - [Brief description of what this file tests]

## Running Tests

### Run All Game Tests (Non-UI)
```bash
flutter test test/screens/games/[game_name]/
```

### Run Specific Test File
```bash
flutter test test/screens/games/[game_name]/[test_file].dart
```

### Run UI Automation Tests
```bash
# Start chromedriver first
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# In separate terminal, run UI tests
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/[game_name]/[game_name]_menu_test.dart \
  -d chrome
```

### Run Selective UI Tests
```bash
./run_ui_tests.bat [game_name]
```

## Test Coverage

### Menu Screen Tests
**File:** `integration_test/[game_name]/[game_name]_menu_test.dart`

**Scenarios Covered:**
- [ ] Player selection and deselection
- [ ] Add player functionality
- [ ] Game settings validation
- [ ] Start button enable/disable logic
- [ ] Settings persistence
- [ ] [Other menu-specific scenarios]

**Key Test Cases:**
1. **Test [N]: [Description]**
   - Validates: [What is validated]
   - Key assertions: [Main assertions]

[List key test cases]

### Gameplay Tests
**File:** `integration_test/[game_name]/[game_name]_gameplay_test.dart`

**Scenarios Covered:**
- [ ] Turn progression
- [ ] Scoring mechanics
- [ ] Win condition detection
- [ ] Special mechanics ([list specific mechanics])
- [ ] Edge cases
- [ ] [Other gameplay scenarios]

**Key Test Cases:**
1. **Test [N]: [Description]**
   - Validates: [What is validated]
   - Key assertions: [Main assertions]

[List key test cases]

### Results Screen Tests
**File:** `integration_test/[game_name]/[game_name]_results_test.dart`

**Scenarios Covered:**
- [ ] Winner display
- [ ] Statistics display
- [ ] Play again functionality
- [ ] Settings preservation
- [ ] **Exit button returns to game selection screen** — use `Navigator.popUntil(context, (route) => route.isFirst)`, NOT `pushNamedAndRemoveUntil('/', ...)`. Assert multiple game cards are visible after navigation (not just one), so the test would fail if the wrong route is used.
- [ ] **Player stats updated on victory** — after the results screen loads and async calls settle, read `PlayerProvider` via `ProviderHelpers.findPlayerByName` and assert `gamesPlayed == 1`, `gamesWon == 1` for the winner and `gamesWon == 0` for all losers, plus a `gameHistory` entry with the correct `gameName`. This validates the full UI flow, not just that `updatePlayerStats` works in isolation.
- [ ] **Victory music triggered on victory** — `resetServerState()` resets `VictoryMusicService._initialized` to `false`; after the results screen loads assert `VictoryMusicService().isInitialized == true`. This proves `_playVictoryMusic()` ran in `initState` — a unit test cannot catch a missing call.
- [ ] [Other results screen scenarios]

**Key Test Cases:**
1. **Test [N]: [Description]**
   - Validates: [What is validated]
   - Key assertions: [Main assertions]

[List key test cases]

### Non-UI Game Logic Tests
**File:** `test/screens/games/[game_name]/[game_name]_game_with_announcements_test.dart`

**Scenarios Covered:**
- [ ] Game state transitions
- [ ] Scoring calculations
- [ ] Announcement triggering
- [ ] Sound effect integration
- [ ] Edge case handling
- [ ] [Other logic scenarios]

**Key Test Cases:**
1. **Test [N]: [Description]**
   - Validates: [What is validated]
   - Key assertions: [Main assertions]

[List key test cases]

### User Management Tests
**File:** `test/screens/games/[game_name]/[game_name]_user_management_test.dart`

**Scenarios Covered:**
- [ ] Winner stat tracking
- [ ] Loser stat tracking
- [ ] Game duration recording
- [ ] Stats persistence
- [ ] Multi-game accumulation
- [ ] [Other user management scenarios]

**Key Test Cases:**
1. **Test [N]: [Description]**
   - Validates: [What is validated]
   - Key assertions: [Main assertions]

[List key test cases]

## Widget Keys Used

### Menu Screen Keys
**Class:** `[GameName]MenuKeys`
**File:** `lib/constants/test_keys.dart`

- `startButton` - Start game button
- `addPlayerButton` - Add player button
- `playerTile(playerId)` - Player selection tile
- `[otherKey]` - [Description]

### Game Screen Keys
**Class:** `[GameName]GameKeys`
**File:** `lib/constants/test_keys.dart`

- `skipTurnButton` - Skip turn button
- `dartsRemovedButton` - Remove darts button
- `dartSingle[N]` - Dartboard single number buttons
- `dartDouble[N]` - Dartboard double number buttons
- `dartTriple[N]` - Dartboard triple number buttons
- `[otherKey]` - [Description]

### Results Screen Keys
**Class:** `[GameName]ResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `playAgainButton` - Play again button
- `changeSettingsButton` - Change settings button
- `leaveButton` - Exit/leave button (returns to game selection) — required for navigation test
- `[otherKey]` - [Description]

## Test Patterns

### [Pattern 1 Name]
**Used In:** [Which tests use this pattern]
**Purpose:** [What this pattern accomplishes]

**Example:**
```dart
[Code example]
```

### [Pattern 2 Name]
**Used In:** [Which tests use this pattern]
**Purpose:** [What this pattern accomplishes]

**Example:**
```dart
[Code example]
```

## Known Test Quirks

### [Quirk 1]
**Issue:** [Description of the quirk]
**Workaround:** [How to handle it]
**Tests Affected:** [Which tests are affected]

### [Quirk 2]
**Issue:** [Description of the quirk]
**Workaround:** [How to handle it]
**Tests Affected:** [Which tests are affected]

## Play to Complete Tests
**Location:** `integration_test/[game_name]/play_to_complete/`

**Required Tests:**
- `default_settings_test.dart` — Game completes with default settings
- One test per game-critical setting (settings that change strategy behavior)
- `mid_game_test.dart` — Manual darts thrown first, then Play to Complete finishes

**Pattern:**
```dart
await UITestHelpers.resetServerState();
await UITestHelpers.navigateToGameMenu(tester, config);
// Configure settings if needed
await UITestHelpers.addPlayer(tester, 'Player A', config);
await UITestHelpers.addPlayer(tester, 'Player B', config);
await UITestHelpers.startGame(tester, config);
await PlayToCompleteHelpers.tapPlayToComplete(tester);
await PlayToCompleteHelpers.waitForGameCompletion(tester, isComplete: () => provider.hasWinner);
expect(provider.hasWinner, isTrue);
expect(config.getPlayAgainButton(), findsOneWidget);
```

## Visual Validation Tests

### [Visual Test 1]
**File:** [Test file name]
**Test Number:** [N]
**Validates:** [What visual elements are validated]
**Colors Checked:** [Specific color hex codes]
**Properties Checked:** [Border, opacity, glow, etc.]

### [Visual Test 2]
**File:** [Test file name]
**Test Number:** [N]
**Validates:** [What visual elements are validated]
**Colors Checked:** [Specific color hex codes]
**Properties Checked:** [Border, opacity, glow, etc.]

## Future Test Needs
[List any testing gaps or future test scenarios to add]
- [ ] [Scenario 1]
- [ ] [Scenario 2]
- [ ] [Scenario 3]
