# Reef Royale - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** 252 tests (185 non-UI + 67 UI)
- **Non-UI Tests:** 185 tests (153 game logic + 32 announcements)
- **UI Automation Tests:** 67 tests (~45 minutes)

### Test Files

#### Non-UI Tests
**Location:** `test/screens/games/reef_royale/`

1. **reef_royale_game_test.dart** (153 tests)
   - DartboardLayout utilities (18 tests)
   - Game creation and setup (7 tests)
   - Miss processing (5 tests)
   - Dart marking mechanics (7 tests)
   - Coral claiming and locking (7 tests)
   - Pearl scoring (5 tests)
   - Cursed Tide mode (3 tests)
   - Neighbor number resolution (18 tests)
   - Bonus buff mechanics (8 tests)
   - Win conditions and ranking (5 tests)
   - Turn management (4 tests)
   - Edit score functionality (3 tests)
   - Target resolution (3 tests)
   - Display helpers (9 tests)
   - ReefRoyaleProvider logic (16 tests)
   - Random Reefs (1 test)
   - Multi-player scoring (2 tests)
   - Skip turn edge cases (3 tests)

2. **reef_royale_announcement_test.dart** (32 tests)
   - Game event announcements (4 tests)
   - Dart event announcements (6 tests)
   - Claim and lock events (2 tests)
   - Scoring events (3 tests)
   - Buff announcements (3 tests)
   - Game completion events (3 tests)
   - Announcement precedence — max 2 per dart (6 tests)
   - Game state integration (6 tests)

#### UI Automation Tests
**Location:** `integration_test/`

1. **reef_royale_menu_and_settings_test.dart** (10 tests, ~3 min)
   - Game option visibility and toggle behavior
   - Game mode dropdown
   - Speed Play and Round Limit slider
   - Start game navigation

2. **reef_royale_add_player_test.dart** (6 tests, ~2 min)
   - Add player dialog and validation
   - Start button enable/disable logic
   - Cancel button functionality

3. **reef_royale_gameplay_test.dart** (30 tests, ~15 min)
   - Dart throw processing and mark accumulation
   - Coral claiming and pearl scoring
   - Dart indicator color coding
   - Game options (Cursed Tide, Neighbor Numbers, Buffs, Speed Play, Random Reefs)
   - Skip turn and miss behavior
   - Shared neighbor multi-target hits

4. **reef_royale_edit_score_test.dart** (6 tests, ~4 min)
   - Edit score dialog behavior
   - Mark recalculation
   - Claim removal on mark reduction

5. **reef_royale_results_screen_test.dart** (6 tests, ~4 min)
   - Winner display and rankings
   - Navigation (Play Again, Change Settings, Back to Menu)

6. **reef_royale_visual_validation_test.dart** (7 tests, ~3 min)
   - Coral card claim state
   - Active player panel components
   - Dart indicators and buff banner
   - Badge visibility (present when enabled, absent when disabled)

7. **reef_royale_screenshot_test.dart** (1 test, ~10 min)
   - Captures 15 screenshots across all screens and option combinations

8. **reef_royale_showcase_test.dart** (1 test, ~4 min)
   - End-to-end game with Easy Claim, Neighbors, and Buffs enabled

## Test Coverage

### Menu and Settings Tests
**File:** `integration_test/reef_royale_menu_and_settings_test.dart`

**Scenarios Covered:**
- [x] All 8 game options visible on menu screen
- [x] Easy Claim toggle
- [x] Neighbor Numbers toggle
- [x] Bonus Buffs toggle
- [x] Speed Play toggle enables Round Limit slider
- [x] Round Limit slider value setting
- [x] Start game with default settings
- [x] Start game with all options enabled
- [x] Game mode dropdown changes to Cursed Tide
- [x] Random Reefs and Show Hints toggles

**Key Test Cases:**
1. **Test 1: Menu Options** — All 8 option controls visible (dropdown, toggles, slider)
2. **Tests 2-4: Toggles** — Easy Claim, Neighbor Numbers, Bonus Buffs switches
3. **Tests 5-6: Speed Play** — Toggle enables slider, slider sets value
4. **Tests 7-8: Start Game** — Default settings and all options enabled
5. **Test 9: Cursed Tide** — Game mode dropdown selection
6. **Test 10: Random Reefs** — Random Reefs and Show Hints toggles

### Add Player Tests
**File:** `integration_test/reef_royale_add_player_test.dart`

**Scenarios Covered:**
- [x] Add player via dialog shows player in list
- [x] Two players enables start button
- [x] Empty name rejected
- [x] Cancel dialog does not add player
- [x] Player tile appears after adding
- [x] Start button disabled with fewer than 2 players

**Key Test Cases:**
1. **Test 1: Add Player** — Dialog creates player, appears in list
2. **Test 2: Start Button** — Enabled only with 2+ selected players
3. **Test 3: Empty Name** — Validation rejects empty input
4. **Test 4: Cancel** — Dialog dismisses without creating player
5. **Test 5: Player Tile** — Tile displays after add and select
6. **Test 6: Minimum Players** — Start disabled with <2 players

### Gameplay Tests
**File:** `integration_test/reef_royale_gameplay_test.dart`

**Scenarios Covered:**
- [x] Initial game state (marks, pearls, round)
- [x] Single/double/triple dart mark accumulation
- [x] Coral claiming at mark threshold
- [x] Miss processing
- [x] Three-dart takeout prompt
- [x] Turn advancement after darts removed
- [x] Pearl scoring on claimed targets
- [x] Skip turn behavior
- [x] Easy Claim (2-mark threshold)
- [x] Non-target number rejection
- [x] Bullseye (2 marks) and outer bull (1 mark)
- [x] Locked target blocking
- [x] Win detection (all 7 corals claimed)
- [x] Dart indicator colors (green, pink, aqua, gold)
- [x] Cursed Tide pearl redirection and badge
- [x] Riptide Rush mark doubling and badge
- [x] Pearl Fever pearl doubling
- [x] Speed Play round counter
- [x] Random Reefs non-standard targets
- [x] Shared neighbor multi-target hits
- [x] Pulsing glow on multi-target indicators
- [x] Neighbors badge visibility
- [x] Target-only direct hit (not also neighbor)

**Key Test Cases:**
1. **Tests 1-5: Basic Mechanics** — Single/double/triple marks, miss, initial state
2. **Tests 6-7: Turn Flow** — Takeout prompt after 3 darts, turn advancement
3. **Tests 8-9: Scoring** — Pearl scoring on claimed, skip turn
4. **Tests 10-13: Options** — Easy Claim, non-target, bullseye, outer bull
5. **Tests 14-15: Game End** — Locked target, win with all 7 corals
6. **Tests 16-18: Dart Indicators** — Green (hit), pink (miss), gold (claim), aqua (neighbor)
7. **Tests 19-20: Advanced Indicators** — Neighbor aqua border, pearl gold border
8. **Tests 21-23: Game Options** — Cursed Tide badge + pearls, Riptide Rush, Pearl Fever
9. **Tests 24-25: More Options** — Speed Play counter, Random Reefs cards
10. **Tests 26-30: Neighbor Mechanics** — Shared neighbor marks, skip/miss indicators, pulsing glow, direct-only hits

### Edit Score Tests
**File:** `integration_test/reef_royale_edit_score_test.dart`

**Scenarios Covered:**
- [x] Edit score button appears after 3 darts
- [x] Dialog opens with current dart values
- [x] Cancel preserves original scores
- [x] Mark recalculation on edit
- [x] Claim removal when marks drop below threshold
- [x] Win trigger when final target claimed via edit

**Key Test Cases:**
1. **Test 1: Button Visibility** — Edit score appears after 3 darts thrown
2. **Test 2: Dialog Content** — Shows current darts in dialog
3. **Test 3: Cancel** — Preserves original state on cancel
4. **Test 4: Recalculation** — Marks updated after score edit
5. **Test 5: Claim Removal** — Claim reverted if marks drop below threshold
6. **Test 6: Win via Edit** — Final coral claimed through score correction

### Results Screen Tests
**File:** `integration_test/reef_royale_results_screen_test.dart`

**Scenarios Covered:**
- [x] Results screen appears after game completion
- [x] Winner name displayed
- [x] Play Again returns to game screen
- [x] Change Settings returns to menu
- [x] Back to Menu returns to home screen
- [x] Rankings show correct order

**Key Test Cases:**
1. **Test 1: Results Display** — Screen shows after win condition met
2. **Test 2: Winner Name** — Correct winner name displayed
3. **Test 3: Play Again** — New game starts with same settings
4. **Test 4: Change Settings** — Returns to menu with options preserved
5. **Test 5: Back to Menu** — Returns to home screen
6. **Test 6: Rankings** — Players ranked by corals then pearls

### Visual Validation Tests
**File:** `integration_test/reef_royale_visual_validation_test.dart`

**Scenarios Covered:**
- [x] Coral card visual state after claim
- [x] Active player panel (avatar, pearl counter, coral counter)
- [x] Dart indicators update after throws
- [x] Buff banner displays when buff active
- [x] Opponent summary bar updates
- [x] Hint overlay when hints enabled
- [x] Cursed Tide badge and visual changes
- [x] No badges visible with default settings

**Key Test Cases:**
1. **Test 1: Coral Card** — Card state changes from unclaimed to claimed
2. **Test 2: Player Panel** — Avatar, pearl counter, coral counter visible; no option badges with defaults
3. **Test 3: Dart Indicators** — All 3 indicator slots exist, update on throw
4. **Test 4: Buff Banner** — Buffs badge in appbar + buff banner on activation
5. **Test 5: Opponent Bar** — Opponent tile appears with correct player stats
6. **Test 6: Hint Overlay** — Hint overlay visible when showHints enabled
7. **Test 7: Cursed Tide** — Cursed badge visible, pearl counter present

### Non-UI Game Logic Tests
**File:** `test/screens/games/reef_royale/reef_royale_game_test.dart`

**Key Test Groups:**

**DartboardLayout (18 tests)**
- Clockwise order validation (20 elements, all 1-20)
- Neighbor lookup for all standard targets (20→[5,1], 19→[3,7], 18→[1,4], etc.)
- isNeighbor validation (adjacent, non-adjacent, out-of-range)
- findNeighborTarget and findAllNeighborTargets for shared neighbors

**Game Creation (7 tests)**
- Playing state, unique creatures, standard vs random targets
- Zero initialization (marks, pearls), option storage

**Marking Mechanics (7 tests)**
- Single/double/triple multipliers, inner bull (2), outer bull (1), accumulation

**Claiming and Locking (7 tests)**
- Standard (3 marks) vs Easy Claim (2 marks), instant claim with triple/double
- Excess marks → pearl scoring, target locking when all players claim

**Pearl Scoring (5 tests)**
- Pearl value = target × multiplier, bull values (50/25), no scoring on locked

**Cursed Tide (3 tests)**
- Pearls to opponents, lowest-pearls ranking, recipient tracking

**Neighbor Numbers (18 tests)**
- Neighbor marks with multipliers, isNeighbor tracking, target resolution
- Shared neighbors add to both targets, target count tracking
- Target number never treated as neighbor of another target

**Bonus Buffs (8 tests)**
- Riptide Rush (2× marks), Pearl Fever (2× pearls), Ink Cloud (no logic effect)
- Buff cleared on turn advance, single buff at a time

**Win Conditions (5 tests)**
- All corals + pearl lead, all targets locked, speed play round limit
- Ranking by corals then pearls (standard), fewest pearls (Cursed Tide)

**Provider Logic (16 tests)**
- Start game, dart throw handling, bull/outer bull, takeout, skip turn
- Non-target/miss display, edit score replay, clear game, buff setting

### Non-UI Announcement Tests
**File:** `test/screens/games/reef_royale/reef_royale_announcement_test.dart`

**Key Test Groups:**

**Game Events (4 tests)** — Start, random reefs, turn, remove darts

**Dart Events (6 tests)** — Miss, non-target, single/double/triple mark, neighbor mark

**Claim and Lock (2 tests)** — Coral claimed, reef locked

**Scoring (3 tests)** — Standard scoring, big score (40+), Cursed Tide scoring

**Buffs (3 tests)** — Riptide Rush, Pearl Fever, Ink Cloud

**Completion (3 tests)** — Near victory, speed play end, victory

**Precedence (6 tests)** — Claim supersedes mark, score+claim both fire, lock after claim, miss standalone, remove darts independent

**State Integration (6 tests)** — Per-dart tracking, claim events, neighbor hits, pearl scoring, cursed pearls

## Running Tests

### Run All Game Tests (Non-UI)
```bash
flutter test test/screens/games/reef_royale/
```

### Run Specific Test File
```bash
# Game logic tests
flutter test test/screens/games/reef_royale/reef_royale_game_test.dart

# Announcement tests
flutter test test/screens/games/reef_royale/reef_royale_announcement_test.dart
```

### Run UI Automation Tests
```bash
# Start chromedriver first
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# In separate terminal, run Reef Royale UI tests
cd dart_games
./run_ui_tests.bat reef_royale
```

## Widget Keys Used

### Menu Screen Keys
**Class:** `ReefRoyaleMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `backButton` — Back navigation
- `gameModeDropdown` — Game mode selection (Standard / Cursed Tide)
- `easyClaimSwitch` — Easy Claim toggle
- `neighborNumbersSwitch` — Neighbor Numbers toggle
- `randomReefsSwitch` — Random Reefs toggle
- `bonusBuffsSwitch` — Bonus Buffs toggle
- `showHintsSwitch` — Show Hints toggle
- `speedPlaySwitch` — Speed Play toggle
- `roundLimitSlider` — Round Limit slider (1-50)
- `startGameButton` — Start game button
- `addPlayerButton` — Add player button
- `addPlayerButtonEmptyState` — Add player button (empty state)
- `playerListView` — Player list scrollview
- `playerTile(playerId)` — Player selection tile (dynamic)
- `removePlayerButton(playerId)` — Remove player button (dynamic)

### Game Screen Keys
**Class:** `ReefRoyaleGameKeys`
**File:** `lib/constants/test_keys.dart`

- `skipTurnButton` — Skip turn button
- `editScoreButton` — Edit score button
- `coralCard(target)` — Coral card display (dynamic, 7 targets)
- `playerAvatar` — Current player avatar
- `pearlCounter` — Pearl count display
- `coralCounter` — Coral claimed count display
- `dartIndicator(index)` — Dart indicator 0/1/2 (dynamic)
- `buffBanner` — Active buff banner
- `roundCounter` — Current round display
- `hintOverlay` — Target hints overlay
- `playerTile(playerId)` — Opponent tile (dynamic)
- `cursedBadge` — Cursed Tide appbar badge
- `neighborsBadge` — Neighbors appbar badge
- `buffsBadge` — Buffs appbar badge
- `dartBullseyeButton` — Bullseye (50) emulator button
- `dartOuterBullButton` — Outer bull (25) emulator button
- `dartMissButton` — Miss emulator button
- `getDartKey(multiplier, number)` — Dynamic dart button key helper

### Results Screen Keys
**Class:** `ReefRoyaleResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `winnerName` — Winner name display
- `winnerPhoto` — Winner creature image
- `pearlCount` — Final pearl count
- `coralCount` — Final coral count
- `playAgainButton` — Play again button
- `changeSettingsButton` — Change settings button
- `backToMenuButton` — Back to menu button
- `playerRanking(index)` — Player ranking entry (dynamic)

## Test Patterns

### Dart Throw via Mock
```dart
// Simulate dart throw through mock dartboard API
final mockApi = getMockApi(tester);
mockApi.simulateDartThrow(
  score: 20,
  multiplier: 'single',
  playerName: 'Player',
  baseScore: 20,
  widgetX: 125.0, widgetY: 125.0, widgetSize: 250.0,
);
await PumpSequences.simpleUpdate(tester);
```

### Dart Indicator Color Verification
```dart
// Verify dart indicator border color matches expected result type
verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF48D1CC); // green = hit
verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0x80FF6B6B); // pink = miss
verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0xFFF4D03F); // gold = claim
```

### Badge Visibility Verification
```dart
// Positive: badge visible when option enabled
await setupAndStartGame(tester, config, cursedTide: true);
expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsOneWidget);

// Negative: badge absent with default settings
await setupAndStartGame(tester, config);
expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsNothing);
```

### Buff Testing via Provider
```dart
// Set buff directly (bypasses random activation)
ProviderHelpers.setReefRoyaleActiveBuff(tester, ReefBuff.riptideRush);
await tester.pump();
```

## Known Test Quirks

### Buff Random Activation
**Issue:** Buffs activate with ~33% probability, making deterministic testing challenging
**Workaround:** Tests set buff directly via `ProviderHelpers.setReefRoyaleActiveBuff()` rather than relying on random activation

### Shared Neighbor Statistics
**Issue:** Shared neighbors (numbers adjacent to two targets) are rare in standard target sets
**Workaround:** Tests use specific number sequences (e.g., 1 is neighbor of both 20 and 18)

### pumpAndSettle() Prohibition
**Issue:** Splash screen `CircularProgressIndicator` prevents `pumpAndSettle()` from completing
**Workaround:** All tests use `PumpSequences.simpleUpdate(tester)` or manual `tester.pump()` calls

### Random Reefs Non-Determinism
**Issue:** Random target selection makes coral card verification unpredictable
**Workaround:** Test 25 verifies that non-standard targets appear on coral cards without asserting specific numbers
