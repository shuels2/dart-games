# Carnival Derby - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** 61 tests (24 UI + 37 non-UI)
- **UI Automation Tests:** 24 tests (~12 minutes)
- **Non-UI Tests:** 37 tests (11 game logic + 26 user management)

### Test Files

#### UI Automation Tests
**Location:** `integration_test/`

1. **carnival_derby_ui_test.dart** (24 tests, ~12 minutes)
   - Menu player selection and settings
   - Game mechanics (Normal and Perfect Finish modes)
   - Skip turn and edit score functionality
   - Multi-player races and edge cases
   - Results screen functionality

#### Non-UI Tests
**Location:** `test/screens/games/carnival_horse_race/`

1. **carnival_derby_game_with_announcements_test.dart** (11 tests)
   - Normal mode game logic with announcements
   - Perfect Finish mode with bust mechanics
   - Dart scoring and announcement integration
   - Skip turn functionality
   - Results screen announcements

2. **carnival_derby_user_management_test.dart** (26 tests)
   - Winner/loser stat tracking with game duration
   - Stats persistence across app restarts
   - Multi-player game tracking
   - Skip turn stat tracking
   - Edit score stat preservation

## Running Tests

### Run All Game Tests (Non-UI)
```bash
flutter test test/screens/games/carnival_horse_race/
```

### Run Specific Test File
```bash
# Game logic tests
flutter test test/screens/games/carnival_horse_race/carnival_derby_game_with_announcements_test.dart

# User management tests
flutter test test/screens/games/carnival_horse_race/carnival_derby_user_management_test.dart
```

### Run UI Automation Tests
```bash
# Start chromedriver first
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# In separate terminal, run UI tests
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/carnival_derby_ui_test.dart \
  -d chrome
```

### Run Selective UI Tests
```bash
./run_ui_tests.bat carnival_derby
```

## Test Coverage

### Menu Screen Tests
**File:** `integration_test/carnival_derby_ui_test.dart`

**Scenarios Covered:**
- [x] Player selection and deselection
- [x] Add player functionality
- [x] Target score slider (20-250)
- [x] Perfect Finish mode toggle
- [x] Start button enable/disable logic
- [x] Settings persistence
- [x] Max 8 players enforcement

**Key Test Cases:**
1. **Test 1-2: Menu - Player Selection**
   - Validates: Player selection, deselection, max 8 players
   - Key assertions: Selected player count, Start button enabled/disabled

2. **Test 3-4: Menu - Target Score Settings**
   - Validates: Target score slider (20-250), Perfect Finish mode toggle
   - Key assertions: Score value updates, toggle state changes

### Gameplay Tests
**File:** `integration_test/carnival_derby_ui_test.dart`

**Scenarios Covered:**
- [x] Turn progression
- [x] Dart scoring (singles, doubles, triples, bulls)
- [x] Normal mode win condition (reach/exceed target)
- [x] Perfect Finish mode bust mechanics
- [x] Skip turn functionality
- [x] Edit score functionality
- [x] Multi-player races
- [x] Edge cases (exact finish, first dart win, bust on each dart)

**Key Test Cases:**
1. **Test 5-7: Game - Basic Race Mechanics - Normal Mode**
   - Validates: Dart scoring, score accumulation, win on exceed target
   - Key assertions: Scores update correctly, winner detected

2. **Test 8-11: Game - Perfect Finish Mode - Bust Mechanics**
   - Validates: Bust when exceeding target, score preservation, exact win
   - Key assertions: Score doesn't change on bust, win on exact target

3. **Test 12-14: Game - Skip Turn Functionality**
   - Validates: Skip button, visual markers (―), turn advancement
   - Key assertions: Darts filled with markers, next player's turn

4. **Test 15-16: Game - Edit Score Functionality**
   - Validates: Edit score dialog, score recalculation
   - Key assertions: Updated scores reflected, turn state preserved

5. **Test 17-18: Game - Multi-Player Race**
   - Validates: Turn rotation, independent player scores
   - Key assertions: Current player changes, scores tracked separately

6. **Test 19-21: Edge Cases**
   - Validates: Win on first dart, bust on each dart position, exact finish
   - Key assertions: Game state correct for unusual scenarios

### Results Screen Tests
**File:** `integration_test/carnival_derby_ui_test.dart`

**Scenarios Covered:**
- [x] Winner display
- [x] Final score display
- [x] Turn statistics
- [x] Play again functionality
- [x] Settings preservation on replay
- [x] Change settings navigation

**Key Test Cases:**
1. **Test 22-24: Results Screen**
   - Validates: Winner name shown, Play Again returns to game with same settings, Change Settings returns to menu
   - Key assertions: Winner displayed, settings preserved, navigation correct

### Non-UI Game Logic Tests
**File:** `test/screens/games/carnival_horse_race/carnival_derby_game_with_announcements_test.dart`

**Scenarios Covered:**
- [x] Game state transitions (setup → playing → finished)
- [x] Scoring calculations (all dart types)
- [x] Announcement triggering with correct messages
- [x] Sound effect integration
- [x] Normal mode win detection
- [x] Perfect Finish mode bust and exact win
- [x] Edge case handling

**Key Test Cases:**
1. **Test 1-4: Normal Mode Game Logic**
   - Validates: Dart scoring, win on reach/exceed, multiple players
   - Key assertions: Scores calculated correctly, correct announcements with sound effects

2. **Test 5-10: Perfect Finish Mode**
   - Validates: Bust mechanics, score preservation, exact win detection
   - Key assertions: Bust announcement, score unchanged, win on exact target

3. **Test 11: Results Screen Announcements**
   - Validates: Game complete and winner announcements
   - Key assertions: Correct announcement text and priority levels

### User Management Tests
**File:** `test/screens/games/carnival_horse_race/carnival_derby_user_management_test.dart`

**Scenarios Covered:**
- [x] Winner stat tracking with game duration
- [x] Loser stat tracking with game duration
- [x] Multi-game accumulation
- [x] Stats persistence across app restarts
- [x] Max 8 players selection enforcement
- [x] Skip turn stat tracking
- [x] Edit score stat preservation
- [x] Partial turn stat tracking

**Key Test Cases:**
1. **Test 1-3: Basic Winner Tracking**
   - Validates: Games won incremented, game duration recorded, "Carnival Derby" game name
   - Key assertions: gamesWon count, duration in history, game name correct

2. **Test 4-9: Multi-Player Stats**
   - Validates: Both winner and loser receive game history with identical duration
   - Key assertions: Winner has gamesWon++, losers have gamesPlayed++ only, all have same duration

3. **Test 10-15: Stats Persistence**
   - Validates: Stats survive app restart via SharedPreferences
   - Key assertions: Stats reload correctly, accumulate across sessions

4. **Test 16-20: Max Players and Selection**
   - Validates: 8 player max enforced, selection/deselection
   - Key assertions: Cannot select 9th player, selection state correct

5. **Test 21-23: Skip Turn Tracking**
   - Validates: Skip turn does NOT count as throws or turns
   - Key assertions: dartThrows = 0, turns = 0 after skip

6. **Test 24-26: Edit Score Preservation**
   - Validates: Editing scores doesn't affect turn/dart counts incorrectly
   - Key assertions: Turn counts remain accurate after edits

## Widget Keys Used

### Menu Screen Keys
**Class:** `CarnivalDerbyMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `startButton` - Start game button
- `addPlayerButton` - Add player button
- `playerTile(playerId)` - Player selection tile
- `targetScoreSlider` - Target score slider
- `exactScoreModeSwitch` - Perfect Finish mode toggle

### Game Screen Keys
**Class:** `CarnivalDerbyGameKeys`
**File:** `lib/constants/test_keys.dart`

- `skipTurnButton` - Skip turn button
- `editScoreButton` - Edit score button
- `dartsRemovedButton` - Remove darts button
- `playerScorePanel(playerId)` - Player score display panel
- `currentPlayerIndicator` - Current player glow/highlight

### Results Screen Keys
**Class:** `CarnivalDerbyResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `playAgainButton` - Play again button
- `changeSettingsButton` - Change settings button
- `winnerDisplay` - Winner name and trophy display

## Test Patterns

### Announcement Verification Pattern
**Used In:** Game logic tests
**Purpose:** Verify announcements are queued with correct text and sound effects

**Example:**
```dart
// Throw dart and verify announcement
provider.processDartThrow(20, dartDisplay: 'S20');
expect(announcements.length, 1);
expect(announcements[0].message, '20');
expect(announcements[0].priority, AudioPriority.hitConfirm);
expect(announcements[0].soundEffect, CarnivalDerbySoundEffects.singleHit);
```

### Game Duration Tracking Pattern
**Used In:** User management tests
**Purpose:** Verify all players receive identical game duration in history

**Example:**
```dart
final gameDuration = Duration(minutes: 5);

// Both winner and loser should have same duration
final winnerHistory = playerProvider.getPlayerHistory(winnerId);
expect(winnerHistory[0].duration, gameDuration);

final loserHistory = playerProvider.getPlayerHistory(loserId);
expect(loserHistory[0].duration, gameDuration);
```

### Settings Persistence Pattern
**Used In:** UI automation tests
**Purpose:** Verify settings persist across screen transitions

**Example:**
```dart
// Set target score to 150
await tester.drag(find.byKey(CarnivalDerbyMenuKeys.targetScoreSlider), Offset(100, 0));
final score = find.text('150');
expect(score, findsOneWidget);

// Navigate away and back
await tester.tap(find.text('Home'));
await tester.pump();
await tester.tap(find.text('Carnival Derby'));
await tester.pump();

// Verify setting preserved
expect(find.text('150'), findsOneWidget);
```

## Known Test Quirks

### UI Test Timing with Announcements
**Issue:** UI tests must wait for announcement sequences to complete before advancing

**Workaround:** Use appropriate pump sequences and delays:
```dart
await tester.tap(dartButton);
await tester.pump(); // Process tap
await tester.pump(Duration(seconds: 2)); // Wait for announcement
await tester.pump(); // Process announcement complete
```

**Tests Affected:** All UI tests that trigger dart throws or game events

### Edit Score Dialog Button State
**Issue:** Submit button disabled until all 3 darts have valid ring+number selections

**Workaround:** Select ring AND number for each dart before expecting submit button enabled

**Tests Affected:** Edit score tests (Test 15-16)

### Perfect Finish Mode Bust Detection
**Issue:** Bust detection happens during `processDartThrow`, not after turn ends

**Workaround:** Check `currentPlayerBusted` flag immediately after throw, not after turn

**Tests Affected:** Perfect Finish mode tests (Test 8-11)

## Visual Validation Tests

No specific visual validation tests for Carnival Derby (unlike Target Tag which has dedicated visual validation test file). Visual elements are validated as part of gameplay tests.

**Visual Elements Validated in Gameplay Tests:**
- Current player glow effect (Canary Yellow border and shadow)
- Score display updates
- Race track horse positions
- Winner display on results screen

## Future Test Needs

- [ ] Test network multiplayer functionality (when implemented)
- [ ] Test handicap system (when implemented)
- [ ] Test tournament bracket mode (when implemented)
- [ ] Test animated horse sprites (when implemented)
- [ ] Performance tests for 8-player games with rapid scoring
- [ ] Cross-platform compatibility tests (web, iOS, Android tablets)
- [ ] Accessibility tests (screen reader, high contrast)
- [ ] Edge case: Simultaneous exact finish (if network multiplayer added)
- [ ] Edge case: Very large target scores (>200)
- [ ] Visual regression tests for UI changes
