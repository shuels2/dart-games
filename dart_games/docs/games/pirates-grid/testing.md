# Pirate's Grid - Testing Documentation

## Test Overview

### Test Suite Summary
- **Total Tests:** 63 UI + 132 non-UI = 195 total for Pirate's Grid
- **UI Automation Tests:** 63 tests across 47 test files
- **Non-UI Tests:** 132 tests across 6 files

### Captured Test Counts (from running actual test commands)
- `flutter test` total: **1438 tests** (all passing)
- `cd server && dart test` total: **190 tests** (all passing)
- Pirate's Grid UI test files: **47 files** across 10 subdirectories

## Non-UI Tests

**Location:** `test/screens/games/pirates_grid/` + `test/models/` + `test/providers/`

### Game Logic Tests (31 tests)
**File:** `test/screens/games/pirates_grid/pirates_grid_game_test.dart`

- Grid setup: 3x3 generates 9 cells with correct targets for each difficulty
- Easy difficulty: all cells accept any multiplier (single, double, triple)
- Medium difficulty: cells only accept double or triple
- Hard difficulty: corners=triple, edges=double, center=Bull
- Flag placement on empty cell (Easy, Medium, Hard)
- Hit on already-owned cell has no effect
- Hit on opponent cell with Steal Mode OFF has no effect
- Hit on opponent cell with Steal Mode ON replaces opponent flag (mutiny)
- Horizontal, vertical, and both diagonal 3-in-a-row detections
- Full grid with no 3-in-a-row = round draw
- Turn advancement after 3 darts
- Skip turn with and without darts thrown
- Players alternate turns correctly
- Win ends round immediately
- Best Of 1/3/5 round win requirements
- Grid resets between rounds
- Starting player alternates between rounds
- Speed Play timer starts, expires, and resets

### Three-In-A-Row Checker Tests (14 tests)
**File:** `test/screens/games/pirates_grid/three_in_a_row_checker_test.dart`

- Empty grid returns null (no winner)
- Horizontal win detection for all 3 rows
- Vertical win detection for all 3 columns
- Diagonal win (top-left to bottom-right)
- Diagonal win (top-right to bottom-left)
- 2-in-a-row (not 3) returns null
- Mixed grid with no winner returns null
- Returns correct winning line positions (3 GridPosition objects)

### Announcement Tests (27 tests)
**File:** `test/screens/games/pirates_grid/pirates_grid_announcement_test.dart`

- Game start announcement text and sound
- Player turn announcement text and sound
- Flag planted announcement text and sound (with target label)
- Square stolen (Mutiny!) announcement text and sound
- Miss announcement text and sound
- Already claimed (own) announcement text and sound
- Already claimed (opponent, no steal) announcement text and sound
- Two in a row announcement text and sound
- Round victory announcement text and sound
- Round draw announcement text and sound
- Match victory announcement text and sound (Best Of 3/5)
- Match draw announcement text and sound
- Round transition announcement text and sound
- Speed Play timer expired announcement text and sound
- Priority ordering: Match Victory > Round Victory > Two in a Row > Flag Planted
- MAX 2 announcements per dart enforcement
- Remove Darts always fires unconditionally

### Game With Announcements Integration Tests (24 tests)
**File:** `test/screens/games/pirates_grid/pirates_grid_game_with_announcements_test.dart`

- Full dart processing triggering correct announcements
- Steal Mode + 3-in-a-row stacking (Match Victory fires, Square Stolen suppressed)
- Steal Mode + Round Win stacking
- Two in a Row correctly detected and announced after steal
- Miss: no cell claimed, miss announcement fires
- Already claimed own: announcement fires, no grid change
- Already claimed opponent (steal OFF): announcement fires, no grid change
- Best Of 3 round transition with correct announcement
- Speed Play expiry: timer fires, turn ends, darts forfeited

### Serialization Tests (24 tests)
**File:** `test/models/pirates_grid_serialization_test.dart`

- Full `toJson/fromJson` roundtrip for all `PiratesGridGame` fields
- Grid serialization: 3x3 `List<List<GridCell>>` preserved exactly
- Cell owner IDs serialize/deserialize correctly (null, P1 id, P2 id)
- `winningLine` (nullable `List<GridPosition>`) serializes and deserializes
- `matchWinnerId` and `isMatchDraw` booleans preserved
- `roundsWon` Map per player preserved
- `currentRound` and `currentRoundStartingPlayerIndex` preserved
- Target difficulty enum roundtrip (Easy/Medium/Hard)
- Best Of setting roundtrip (1/3/5)
- Steal Mode and Speed Play booleans preserved
- Player IDs list preserved
- Backward compatibility (missing optional fields default gracefully)

### Save/Restore Tests (12 tests)
**File:** `test/providers/pirates_grid_save_restore_test.dart`

- Save game metadata creation with correct game name and progress info
- Full `PiratesGridGame` state restored via `SaveGameService`
- Gameplay can continue after restore (darts processed correctly)
- `resumedSavedGameId` is set after restore and cleared after match completion
- Best Of mid-match state restores correctly (round wins, current round, grid)
- Steal Mode state preserved through save/restore
- Speed Play state preserved through save/restore

## UI Automation Tests

**Location:** `integration_test/pirates_grid/`
**Total:** 63 tests across 47 files

### add_player/ (1 file, 6 tests)
**File:** `add_player/add_player_test.dart`
- Navigate from home to Pirate's Grid menu
- Add player with name
- Photo UI elements present
- Empty name validation
- Whitespace-only name validation
- Cancel closes without adding

### edit_score/ (5 files, 5 tests)
- `edit_dart_save_test.dart` — Edit dialog opens from RemoveDartsModal; change dart and save updates grid
- `edit_dart_cancel_test.dart` — Cancel in edit dialog preserves original dart
- `miss_dart_preselected_in_edit_test.dart` — Miss dart is pre-selected when editing a miss
- `edit_creates_winner_stats_test.dart` — Editing a dart to create a win updates winner stats
- `edit_removes_winner_no_stats_test.dart` — Editing a dart that undoes a win removes the winner state

**Score display pattern (Pattern B):** Segments display as raw dart notation ("S20", "D17", "Bull") with no transform. Tests verify that the edit dialog pre-populates the correct raw segment.

### gameplay/ (14 files, 14 tests)
- `plant_flag_easy_test.dart` — Single hit on Easy cell plants flag
- `plant_flag_medium_test.dart` — Double hit on Medium cell plants flag; single hit does not
- `miss_wrong_target_test.dart` — Hit on number not in grid = miss, no flag planted
- `steal_opponent_square_test.dart` — Steal Mode ON: hitting opponent cell replaces their flag
- `steal_mode_off_no_effect_test.dart` — Steal Mode OFF: hitting opponent cell has no effect
- `turn_advance_after_3_darts_test.dart` — Turn ends and advances after 3 darts
- `skip_turn_with_darts_test.dart` — Skip Turn button works mid-turn
- `skip_turn_no_darts_test.dart` — Skip Turn button works with 0 darts thrown
- `three_in_a_row_wins_round_test.dart` — 3-in-a-row detected and round ends immediately
- `draw_when_grid_full_test.dart` — Full grid with no winner = draw, results screen shows draw
- `bestof3_round_transition_test.dart` — Best Of 3 round transitions correctly with round tracker
- `min_player_count_test.dart` — Start button disabled with 1 player; enabled at exactly 2
- `max_player_count_test.dart` — Cannot add a 3rd player; max is 2
- `opponent_display_test.dart` — Opponent player info visible on game screen

### menu_and_settings/ (1 file, 7 tests)
**File:** `menu_and_settings/menu_settings_test.dart`
- Menu initial state (Easy, Best Of 1, Steal OFF, Speed OFF)
- Target Difficulty dropdown works (Easy/Medium/Hard)
- Best Of dropdown works (1/3/5)
- Steal Mode toggle works
- Speed Play toggle works
- Start with default settings navigates to game screen
- Start requires exactly 2 players selected

### navigation/ (4 files, 4 tests)
- `menu_back_to_home_test.dart` — Back from menu returns to home with 3+ game cards visible
- `game_back_settings_persist_test.dart` — Settings persist when returning from game to menu
- `change_settings_back_to_home_test.dart` — Change Settings from results → menu → back → home (catches `(route) => false` bug)
- `change_settings_preserves_settings_test.dart` — Change Settings from results preserves settings and players on menu

### pause_modal/ (3 files, 3 tests)
- `menu_pause_test.dart` — Dartboard paused modal appears on menu screen when dartboard disconnects
- `gameplay_pause_test.dart` — Dartboard paused modal appears on game screen when dartboard disconnects
- `results_pause_test.dart` — Dartboard paused modal appears on results screen when dartboard disconnects

### play_to_complete/ (6 files, 6 tests)
- `default_settings_test.dart` — Game completes with default settings (Easy, Bo1, Steal OFF, Speed OFF)
- `hard_difficulty_test.dart` — Game completes with Hard difficulty (strategy generates correct segment throws)
- `steal_mode_test.dart` — Game completes with Steal Mode ON (strategy handles opponent-owned cells)
- `bestof3_test.dart` — Game completes a full Best Of 3 match (strategy wins 2 rounds)
- `speed_play_test.dart` — Game completes with Speed Play ON (timer fires but strategy throws fast enough)
- `mid_game_test.dart` — Manual darts planted first, then Play to Complete finishes the round

### results_screen/ (7 files, 7 tests)
- `winner_display_single_round_test.dart` — Winner name, "TREASURE FOUND!" title, winner avatar visible
- `match_winner_display_test.dart` — Best Of match winner shows "CAPTAIN OF THE SEAS!" title
- `draw_display_test.dart` — Draw game shows "STALEMATE!" title and no winner crown
- `set_sail_again_test.dart` — Set Sail Again returns to game screen with same settings and players
- `port_home_button_test.dart` — Port Home navigates to home screen; at least 3 game cards visible (tests `popUntil isFirst`)
- `winner_stats_updated_test.dart` — After results load, winner has `gamesPlayed==1, gamesWon==1`; loser has `gamesWon==0`; gameHistory entry with gameName "Pirate's Grid" exists
- `victory_music_initialized_test.dart` — After results load, `VictoryMusicService().isInitialized == true`

### save_resume/ (1 file, 6 tests)
**File:** `save_resume/save_resume_test.dart`
- Save game modal appears when pressing back with darts thrown
- Save creates saved game entry and navigates back to menu
- Resume modal appears on menu screen when saved game exists
- Resume game restores full game state (grid, flags, round wins)
- Resumed game auto-deletes saved game on match completion
- Resume game button enable/disable state

### visual_validation/ (5 files, 5 tests)
- `pirates_grid_screenshot_test.dart` — **Screenshot test** (uses `screenshot_test.dart` driver): captures 15 game states as PNG files to `temp_screenshots/`
- `active_player_highlight_test.dart` — **Programmatic**: active player panel has correct border color (Compass Rose Bronze), opponent panel does not
- `conditional_ui_test.dart` — **Programmatic**: Steal Mode badge visible when ON, hidden when OFF; round tracker visible when Best Of > 1, hidden when Bo1
- `dart_indicators_state_test.dart` — **Programmatic**: dart indicator slots update correctly (empty → filled) as darts are thrown; miss indicator shows Blood Red color
- `flags_planted_state_test.dart` — **Programmatic**: flags counter increments correctly; grid cell content changes when flag is planted

## Mandatory Test Categories

### 4 Navigation Tests (all present)
Per `docs/development/navigation-ui-tests-plan.md`:
1. `menu_back_to_home_test.dart` — Back from menu → home with 3+ game cards
2. `game_back_settings_persist_test.dart` — Game → menu, settings persist
3. `change_settings_back_to_home_test.dart` — Results → Change Settings → menu → back → home
4. `change_settings_preserves_settings_test.dart` — Results → Change Settings, settings/players preserved

### 3 Results Screen Mandatory Tests (all present)
1. `port_home_button_test.dart` — Exit button uses `popUntil(isFirst)`, at least 3 game cards visible
2. `winner_stats_updated_test.dart` — Player stats updated after results screen loads
3. `victory_music_initialized_test.dart` — Victory music initialized in results screen `initState`

### 2 Edit Score Winner Stats Tests (all present)
1. `edit_creates_winner_stats_test.dart` — Edit creates a win → winner stats updated
2. `edit_removes_winner_no_stats_test.dart` — Edit removes a win → winner stats NOT updated

### 2 Player Count Tests (min + max — both at 2 since Pirate's Grid is strictly 2P)
1. `min_player_count_test.dart` — Start button disabled at 1 player; enabled at exactly 2
2. `max_player_count_test.dart` — Cannot select a 3rd player; max is 2

### 1 Opponent Display Test
- `opponent_display_test.dart` — Opponent player info visible on game screen

### 3 Pause Modal Tests (all present)
1. `menu_pause_test.dart`
2. `gameplay_pause_test.dart`
3. `results_pause_test.dart`

### Play-to-Complete Tests (6 total)
Default + 4 game-critical settings (Hard difficulty, Steal Mode, Best Of 3, Speed Play) + mid-game

### Visual Validation
- 1 screenshot test (`pirates_grid_screenshot_test.dart`) — 15 states captured
- 4 programmatic tests

## Widget Keys

### Menu Screen Keys
**Class:** `PiratesGridMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `PiratesGridMenuKeys.backButton` — AppBar back button
- `PiratesGridMenuKeys.difficultyDropdown` — Target Difficulty dropdown
- `PiratesGridMenuKeys.bestOfDropdown` — Best Of dropdown
- `PiratesGridMenuKeys.stealModeSwitch` — Steal Mode toggle
- `PiratesGridMenuKeys.speedPlaySwitch` — Speed Play toggle
- `PiratesGridMenuKeys.startGameButton` — "SET SAIL!" button
- `PiratesGridMenuKeys.addPlayerButton` — "NEW PLAYER" button (header)
- `PiratesGridMenuKeys.addPlayerButtonEmptyState` — "NEW PLAYER" button (empty state)
- `PiratesGridMenuKeys.playerListView` — Player ListView
- `PiratesGridMenuKeys.playerTile(id)` — Individual player tile
- `PiratesGridMenuKeys.removePlayerButton(id)` — Player remove button

### Game Screen Keys
**Class:** `PiratesGridGameKeys`
**File:** `lib/constants/test_keys.dart`

- `PiratesGridGameKeys.skipTurnButton` — Skip Turn button in active player panel
- `PiratesGridGameKeys.editScoreButton` — Edit Score button (inside RemoveDartsModal)
- `PiratesGridGameKeys.gridCell(row, col)` — Individual grid cell by row and column (0-indexed)
- `PiratesGridGameKeys.playerAvatar` — Active player avatar
- `PiratesGridGameKeys.flagsCounter` — Active player flags planted count
- `PiratesGridGameKeys.dartIndicator(index)` — Dart indicator slot (0, 1, 2)
- `PiratesGridGameKeys.stealModeBadge` — "STEAL MODE" badge (only visible when Steal Mode ON)
- `PiratesGridGameKeys.speedPlayTimer` — Countdown timer display (only visible when Speed Play ON)
- `PiratesGridGameKeys.roundTracker` — Round score tracker (only visible when Best Of > 1)
- `PiratesGridGameKeys.playerPanel` — Active player panel container

### Results Screen Keys
**Class:** `PiratesGridResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `PiratesGridResultsKeys.playAgainButton` — "SET SAIL AGAIN" button
- `PiratesGridResultsKeys.changeSettingsButton` — "NEW VOYAGE" button
- `PiratesGridResultsKeys.backToMenuButton` — "PORT HOME" button (required for navigation test)
- `PiratesGridResultsKeys.winnerName` — Winner name text
- `PiratesGridResultsKeys.winnerAvatar` — Winner character image
- `PiratesGridResultsKeys.rankingsList` — Rankings list

## Test Patterns

### Score Display Pattern B (No Transform)
**Used In:** All edit_score/ tests
**Purpose:** Pirate's Grid shows raw dart notation, not a transformed score.

Edit dialog shows segment labels like "S20" (single 20), "D17" (double 17), "Bull" (bullseye). Tests verify the pre-populated value matches the raw segment thrown, not a point value.

```dart
// Pattern B — no scoreDisplayTransform, raw segments shown
expect(find.text('S20'), findsOneWidget);
expect(find.text('D17'), findsOneWidget);
```

### Grid Cell Finder Pattern
**Used In:** gameplay/ tests, visual_validation/ tests
**Purpose:** Find grid cells by row and column

```dart
final cell = find.byKey(PiratesGridGameKeys.gridCell(row, col));
await tester.tap(cell);
```

### Steal Mode Test Pattern
**Used In:** `steal_opponent_square_test.dart`, `steal_mode_off_no_effect_test.dart`

1. Enable Steal Mode in menu settings
2. Start game
3. Player 1 plants a flag in a cell
4. Advance to Player 2's turn
5. Player 2 hits the same cell's target
6. Assert (Steal ON): Player 2's flag now occupies the cell; Player 1's count decreased
7. Assert (Steal OFF): Cell still shows Player 1's flag; no change

### Best Of 3 Round Transition Pattern
**Used In:** `bestof3_round_transition_test.dart`, `play_to_complete/bestof3_test.dart`

After winning round 1, the round tracker updates to show "Round 2/3". The grid resets to empty. Tests verify both the tracker text and the grid state (all cells empty after transition).

## Known Test Quirks

### Speed Play Timer in Tests
**Issue:** The Speed Play timer is a `Timer.periodic` in the screen state. During tests, `pump(Duration(seconds: 16))` advances the timer to expiration.
**Workaround:** Use `await tester.pump(const Duration(seconds: 16))` after starting a turn to trigger timer expiration in speed play tests.
**Tests Affected:** `play_to_complete/speed_play_test.dart`, any tests checking timer behavior.

## Play to Complete Tests
**Location:** `integration_test/pirates_grid/play_to_complete/`

**6 required tests:**
- `default_settings_test.dart` — Game completes with default settings
- `hard_difficulty_test.dart` — Hard difficulty: strategy generates triples for corner cells, doubles for edges, inner bull for center
- `steal_mode_test.dart` — Steal Mode ON: strategy still wins (may need to re-steal opponent cells)
- `bestof3_test.dart` — Best Of 3: strategy wins 2 rounds, match completes, results screen shows match winner
- `speed_play_test.dart` — Speed Play ON: strategy throws fast enough that timer doesn't expire; game completes normally
- `mid_game_test.dart` — Manual darts planted first (a few cells claimed), then Play to Complete finishes

**Standard pattern:**
```dart
await UITestHelpers.resetServerState();
await UITestHelpers.navigateToGameMenu(tester, config);
// Configure settings if needed
await UITestHelpers.addPlayer(tester, 'Captain A', config);
await UITestHelpers.addPlayer(tester, 'Captain B', config);
await UITestHelpers.startGame(tester, config);
await PlayToCompleteHelpers.tapPlayToComplete(tester);
await PlayToCompleteHelpers.waitForGameCompletion(tester, isComplete: () => provider.hasWinner);
expect(provider.hasWinner, isTrue);
expect(find.byKey(PiratesGridResultsKeys.playAgainButton), findsOneWidget);
```

## Navigation Tests
**Location:** `integration_test/pirates_grid/navigation/`

All 4 required navigation tests are present. Each test uses the `GameUIConfig.piratesGrid()` config from `integration_test/shared/game_ui_config.dart`.

**Helper file:** `integration_test/pirates_grid/navigation/_helpers.dart`

## Visual Validation Tests

### Screenshot Test
**File:** `integration_test/pirates_grid/visual_validation/pirates_grid_screenshot_test.dart`
**Driver:** `test_driver/screenshot_test.dart` (REQUIRED — uses `binding.takeScreenshot()`)
**States captured:** 15 screenshots covering menu, game (Easy/Medium/Hard/StealMode/SpeedPlay/Best Of/RemoveDartsModal/2-in-a-row), and results (single-round/match/draw)

### active_player_highlight_test.dart
**Validates:** Active player panel has Compass Rose Bronze border (`#CD7F32`); inactive player is not highlighted

### conditional_ui_test.dart
**Validates:** 
- `PiratesGridGameKeys.stealModeBadge` is visible with Steal Mode ON, not rendered when OFF
- `PiratesGridGameKeys.roundTracker` is visible with Best Of 3 or 5, not rendered with Best Of 1

### dart_indicators_state_test.dart
**Validates:** Dart indicator slots update as darts are thrown (0 thrown → empty circles, 1-2 thrown → mixed, miss dart shows Blood Red color)

### flags_planted_state_test.dart
**Validates:** `PiratesGridGameKeys.flagsCounter` increments from 0 to 1 after a successful flag plant; grid cell widget changes from empty state to flag state

## Future Test Needs
- [ ] Visual validation of difficulty badge rendering (D badge color = Sea Foam Teal, T badge color = Compass Rose Bronze)
- [ ] Test for Best Of 5 match completion (3 rounds won)
- [ ] Test for match draw (all rounds end in draw)
