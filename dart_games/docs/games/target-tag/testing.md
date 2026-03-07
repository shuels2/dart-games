# Target Tag - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** 130 tests (62 UI + 68 non-UI)
- **UI Automation Tests:** 62 tests (~48 minutes)
- **Non-UI Tests:** 68 tests (54 game logic/announcements + 14 user management)

### Test Files

#### UI Automation Tests
**Location:** `integration_test/target_tag/`

1. **target_tag_menu_and_mechanics_test.dart** (24 tests, ~16 minutes)
   - Player selection and game settings validation
   - Team mode configuration and mechanics
   - Edit score functionality
   - Player tile visual highlighting

2. **target_tag_visual_validation_test.dart** (4 tests, ~5 minutes)
   - Current player badge visibility
   - Tagged In visual state
   - Eliminated player visual state
   - Team mode Tagged In visual

3. **target_tag_gameplay_test.dart** (13 tests, ~9 minutes)
   - Hero bonus mechanics
   - Dart highlighting (D1/D2/D3)
   - Game settings panel
   - Victory screen validation

4. **target_tag_add_player_test.dart** (6 tests, ~3 minutes)
   - Navigation and player setup
   - Add player with name only
   - Photo upload UI elements
   - Name validation (empty, whitespace)
   - Cancel button functionality

5. **target_tag_results_screen_test.dart** (6 tests, ~7 minutes)
   - Solo mode victory display
   - Play again settings preservation
   - Change settings navigation
   - Team mode victory display
   - Team settings preservation
   - Hero Bonus setting preservation

6. **target_tag_save_resume_test.dart** (9 tests, ~8 minutes)
   - Save game modal (back button behavior)
   - Resume game modal (auto-show, game selection)
   - Resume game button (enabled/disabled states)
   - Save/resume/complete full cycle
   - Auto-delete on game completion

#### Non-UI Tests
**Location:** `test/screens/games/target_tag/`

1. **target_tag_game_with_announcements_test.dart** (54 tests)
   - Solo mode game logic with announcements (Tests 1-8)
   - Team mode mechanics with announcements (Tests 9-14)
   - Hero bonus behavior (Tests 15-17)
   - Turn management (Tests 18-19)
   - Edit score functionality (Tests 20-24)
   - Edge cases and complex scenarios (Tests 25-32)
   - Precedence coverage tests (Tests 33-41): Tagged Out suppression by higher priorities, hero bonus Tagged In without opponent status change, irrelevant number hits, bullseye/outer bull, multiple eliminations, multiple Tagged Outs, winner on 3rd dart

2. **target_tag_user_management_test.dart** (14 tests)
   - Winner/loser stat tracking with duration
   - Stats persistence across app restarts
   - Solo and team mode statistics
   - Max 10 players selection enforcement
   - Skip turn stat tracking

## Running Tests

### Run All Game Tests (Non-UI)
```bash
flutter test test/screens/games/target_tag/
```

### Run Specific Test File
```bash
# Game logic tests
flutter test test/screens/games/target_tag/target_tag_game_with_announcements_test.dart

# User management tests
flutter test test/screens/games/target_tag/target_tag_user_management_test.dart
```

### Run UI Automation Tests
```bash
# Start chromedriver first
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# In separate terminal, run UI tests (6 test files)
cd dart_games

# Menu and mechanics (24 tests)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_menu_and_mechanics_test.dart \
  -d chrome

# Visual validation (4 tests)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_visual_validation_test.dart \
  -d chrome

# Gameplay (13 tests)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_gameplay_test.dart \
  -d chrome

# Add player (6 tests)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_add_player_test.dart \
  -d chrome

# Results screen (6 tests)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_results_screen_test.dart \
  -d chrome

# Save & Resume (9 tests)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_save_resume_test.dart \
  -d chrome
```

### Run Selective UI Tests
```bash
./run_ui_tests.bat target_tag
```

## Test Coverage

### Menu Screen Tests
**File:** `integration_test/target_tag/target_tag_menu_and_mechanics_test.dart`

**Scenarios Covered:**
- [x] Player selection and deselection (max 10 solo, max 5 teams)
- [x] Add player functionality
- [x] Shield Max slider (1-10)
- [x] Hero Bonus toggle
- [x] Solo vs Team mode toggle
- [x] Team assignment and management
- [x] Start button enable/disable logic
- [x] Settings validation
- [x] Edit score behavior
- [x] Player tile highlighting

**Key Test Cases:**
1. **Test 1: Player Selection** - Validates selection/deselection, max 10 solo players
2. **Tests 2-7: Menu Settings** - Shield Max, Hero Bonus, mode toggle, validation
3. **Tests 8-10: Team Mode** - Max 5 teams, team assignment, player distribution
4. **Tests 11-12: Add Player Button** - Enabled/disabled states
5. **Tests 13: Hero Bonus Toggle** - Setting persistence
6. **Tests 14-17: Edit Score** - Dialog behavior, score updates
7. **Tests 18-23: Player Tile Highlighting** - Current player, Tagged In, eliminated states

### Visual Validation Tests
**File:** `integration_test/target_tag/target_tag_visual_validation_test.dart`

**Scenarios Covered:**
- [x] Current player badge visibility ("YOUR TURN")
- [x] Tagged In badge and pink border
- [x] Eliminated state (strikethrough, opacity 50%)
- [x] Team mode Tagged In visual

**Key Test Cases:**
1. **Test 1: Current Player Badge** - Validates "YOUR TURN" badge appears
2. **Test 2: Tagged In + Current** - Combined visual state validation
3. **Test 3: Eliminated Visual** - Red strikethrough, 50% opacity, border
4. **Test 4: Team Tagged In** - Team badge display

### Gameplay Tests
**File:** `integration_test/target_tag/target_tag_gameplay_test.dart`

**Scenarios Covered:**
- [x] Hero Bonus mechanics (double/triple requirements)
- [x] Opponent targets display
- [x] Dart highlighting (D1/D2/D3 result indicators)
- [x] Game settings panel (shields, target, Hero Bonus display)
- [x] Victory detection
- [x] Victory screen display

**Key Test Cases:**
1. **Tests 1-8: Hero Bonus & Opponent Targets** - Buff mechanics, target grid
2. **Tests 9-10: Dart Highlighting** - Visual feedback per dart (green/pink borders)
3. **Test 11: Game Settings Panel** - Active player info display
4. **Tests 12-13: Victory Screen** - Winner announcement, confetti, stats

### Add Player Tests
**File:** `integration_test/target_tag/target_tag_add_player_test.dart`

**Scenarios Covered:**
- [x] Navigation to Target Tag menu
- [x] Initial player setup
- [x] Add player with name only (no photo)
- [x] Photo upload UI elements
- [x] Name validation (empty name)
- [x] Name validation (whitespace-only)
- [x] Cancel button functionality

**Key Test Cases:**
1. **Test 1: Navigation** - Launch app, navigate to Target Tag
2. **Test 2: Add Name Only** - Create player without photo
3. **Test 3: Photo UI** - Camera and gallery buttons present
4. **Tests 4-5: Validation** - Empty and whitespace-only names rejected
5. **Test 6: Cancel** - Dialog dismisses without creating player

### Results Screen Tests
**File:** `integration_test/target_tag/target_tag_results_screen_test.dart`

**Scenarios Covered:**
- [x] Solo mode victory display (single winner)
- [x] Play again preserves settings (solo mode)
- [x] Change settings returns to menu
- [x] Team mode victory display (multiple winners)
- [x] Play again preserves team settings
- [x] Hero Bonus setting preserved

**Key Test Cases:**
1. **Test 1: Solo Victory** - Winner name, trophy, statistics
2. **Test 2: Play Again Solo** - Settings preserved, new game starts
3. **Test 3: Change Settings** - Returns to menu with previous settings
4. **Test 4: Team Victory** - Multiple winners displayed
5. **Test 5: Play Again Team** - Team assignments preserved
6. **Test 6: Hero Bonus Preserved** - Setting carries over to new game

### Non-UI Game Logic Tests
**File:** `test/screens/games/target_tag/target_tag_game_with_announcements_test.dart`

**Scenarios Covered:**
- [x] Shield building mechanics (hit own target)
- [x] Tagged In status (reach Shield Max)
- [x] Opponent attacks (Tagged In player hits opponent target)
- [x] Eliminations (hit opponent at 0 shields)
- [x] Hero Bonus mechanics (correct multiplier required)
- [x] Team mode (shared shields, team Tagged In, team elimination)
- [x] Turn management (skip turn, advance turn)
- [x] Edit score (undo/redo shields, Tagged In, eliminations)
- [x] Edge cases (simultaneous events, multiple eliminations, 10 players, 5 teams)

**Key Test Cases:**
1. **Tests 1-8: Solo Mode** - Shield building, Tagged In, attacks, eliminations, low shields, victory
2. **Tests 9-14: Team Mode** - Team setup, team Tagged In, team elimination, last team standing
3. **Tests 15-17: Hero Bonus** - Fill to max, attacks while Tagged In, team Hero attacks
4. **Tests 18-19: Turn Management** - Skip turns, multiple skips
5. **Tests 20-24: Edit Score** - Add/remove shields, undo eliminations, team adjustments
6. **Tests 25-32: Edge Cases** - Simultaneous events, regaining Tagged In, all bullseyes, max players/teams

### User Management Tests
**File:** `test/screens/games/target_tag/target_tag_user_management_test.dart`

**Scenarios Covered:**
- [x] Winner stat tracking with game duration
- [x] Loser stat tracking with game duration
- [x] Multi-game accumulation
- [x] Stats persistence across app restarts
- [x] Solo and team mode statistics
- [x] Max 10 players selection enforcement
- [x] Skip turn stat tracking

**Key Test Cases:**
1. **Tests 1-3: Basic Tracking** - Games won, duration, game name
2. **Tests 4-9: Solo & Team Stats** - Winners and losers both get duration, team wins
3. **Tests 10-12: Persistence** - Stats reload correctly, accumulate
4. **Test 13: Max Players** - 10 player limit enforced
5. **Test 14: Skip Turn** - Does NOT count as throws or turns

## Widget Keys Used

### Menu Screen Keys
**Class:** `TargetTagMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `startButton` - Start game button
- `addPlayerButton` - Add player button
- `playerTile(playerId)` - Player selection tile
- `shieldMaxSlider` - Shield Max slider (1-10)
- `heroBonusToggle` - Hero Bonus toggle switch
- `gameModeToggle` - Solo/Team mode toggle

### Game Screen Keys
**Class:** `TargetTagGameKeys`
**File:** `lib/constants/test_keys.dart`

- `skipTurnButton` - Skip turn button
- `editScoreButton` - Edit score button
- `removeDartsButton` - Remove darts button
- `activePlayerPanel` - Active player display panel
- `opponentTargetsGrid` - Opponent targets grid
- `playerTile(playerId)` - Player tile in list
- `currentPlayerBadge` - "YOUR TURN" badge
- `taggedInBadge` - "TAGGED IN" badge

### Results Screen Keys
**Class:** `TargetTagResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `playAgainButton` - Play again button
- `changeSettingsButton` - Change settings button
- `winnerDisplay` - Winner name and photo display

## Test Patterns

### Announcement Verification Pattern
**Used In:** Game logic tests
**Purpose:** Verify announcements queued with correct text and sound effects

**Example:**
```dart
// Build shields and verify announcement
provider.processDartThrow(20, 'single', 20, 'S20');
expect(announcements.last.message, '1 shields');
expect(announcements.last.priority, AudioPriority.shieldStatus);
expect(announcements.last.soundEffect, TargetTagSoundEffects.shieldGained);
```

### Game Duration Tracking Pattern
**Used In:** User management tests
**Purpose:** Verify all players receive identical duration in history

**Example:**
```dart
final gameDuration = Duration(minutes: 5);

// Winner and losers should have same duration
final winnerHistory = playerProvider.getPlayerHistory(winnerId);
expect(winnerHistory[0].duration, gameDuration);

final loserHistory = playerProvider.getPlayerHistory(loserId);
expect(loserHistory[0].duration, gameDuration);
```

### Visual Validation Pattern
**Used In:** Visual validation tests
**Purpose:** Verify visual elements have correct colors, borders, opacity

**Example:**
```dart
// Find player tile
final tile = find.byKey(TargetTagGameKeys.playerTile(playerId));

// Verify Tagged In visual state
final container = tester.widget<Container>(tile);
final decoration = container.decoration as BoxDecoration;
expect(decoration.border, isNotNull);
expect((decoration.border as Border).top.color, const Color(0xFFFF007A));

// Verify badge present
expect(find.text('TAGGED IN'), findsOneWidget);
```

## Known Test Quirks

### UI Test Timing with Complex Announcements
**Issue:** Multiple announcements (shield gain + Tagged In + low shields) require wait time

**Workaround:** Use appropriate pump sequences with delays:
```dart
await tester.tap(dartButton);
await tester.pump(); // Process tap
await tester.pump(Duration(seconds: 3)); // Wait for announcements
await tester.pump(); // Process complete
```

**Tests Affected:** All gameplay UI tests with shield changes

### Edit Score Dialog Per-Dart Borders
**Issue:** Target Tag shows per-dart border colors (green/pink) based on result type

**Workaround:** Test must compute expected colors and verify each dart's border

**Tests Affected:** Edit score tests (Tests 14-17)

### Team Mode Icon Randomization
**Issue:** Team icons randomly assigned at game start

**Workaround:** Tests use deterministic icon assignment via `teamIconOverrides`

**Tests Affected:** Team mode tests (Tests 8-10)

## Visual Validation Tests

Target Tag has dedicated visual validation test file with pixel-perfect checks:

### Test 1: Current Player Badge
**Validates:** "YOUR TURN" badge visibility
**Colors Checked:** Badge background, text color
**Properties Checked:** Border presence, badge positioning

### Test 2: Tagged In + Current Player
**Validates:** Combined visual state (both badges)
**Colors Checked:** Hot Pink border (#FF007A)
**Properties Checked:** "TAGGED IN" badge, border glow

### Test 3: Eliminated Player
**Validates:** Elimination visual state
**Colors Checked:** Red strikethrough, border color
**Properties Checked:** 50% opacity, "ELIMINATED" overlay, strikethrough line

### Test 4: Team Tagged In
**Validates:** Team mode Tagged In visual
**Colors Checked:** Team badge colors
**Properties Checked:** Team icon, shared Tagged In status

## Future Test Needs

- [ ] Test Sudden Death mode (when UI implemented)
- [ ] Test power-ups (when feature added)
- [ ] Test 20-player support (if implemented)
- [ ] Performance tests for 10-player games
- [ ] Cross-platform tests (web, iOS, Android)
- [ ] Accessibility tests (screen reader, contrast)
- [ ] Network multiplayer tests (if implemented)
- [ ] Edge case: All players reach Tagged In simultaneously
- [ ] Edge case: Multiple eliminations in one dart sequence
- [ ] Visual regression tests for UI changes
