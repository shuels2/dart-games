# Gladiator Arena - Testing Documentation

## Test Overview

### Test Suite Summary

- **Total Tests:** 99 UI + 190 non-UI = 289 total
- **UI Automation Tests:** 99 testWidgets across 10 subdirectories (~131 minutes estimated)
- **Non-UI Tests:** 190 tests across 6 files

### Flutter Test Counts (from `flutter test`, total suite 1801)

The 190 gladiator_arena non-UI tests are distributed as:

| File | Tests |
|---|---|
| `test/providers/gladiator_arena_provider_game_test.dart` | 81 |
| `test/screens/games/gladiator_arena/gladiator_arena_announcement_test.dart` | 33 |
| `test/providers/gladiator_arena_save_restore_test.dart` | 15 |
| `test/screens/games/gladiator_arena/gladiator_arena_game_test.dart` | 26 |
| `test/screens/games/gladiator_arena/gladiator_arena_game_with_announcements_test.dart` | 18 |
| `test/models/gladiator_arena_serialization_test.dart` | 17 |
| **Total** | **190** |

### UI Test Counts (per subdirectory)

| Subdirectory | Tests |
|---|---|
| `add_player/` | 6 |
| `edit_score/` | 7 |
| `gameplay/` | 19 |
| `menu_and_settings/` | 8 |
| `navigation/` | 4 |
| `pause_modal/` | 20 |
| `play_to_complete/` | 5 |
| `results_screen/` | 7 |
| `save_resume/` | 16 |
| `visual_validation/` | 7 |
| **Total** | **99** |

## Test Files

### UI Automation Tests
**Location:** `integration_test/gladiator_arena/`

1. **`add_player/`** (6 tests)
   - Navigate from home to Gladiator Arena menu
   - Add player with name
   - Photo UI elements present
   - Empty name validation
   - Whitespace name validation
   - Cancel closes without adding

2. **`edit_score/`** (7 tests)
   - Edit dialog opens from RemoveDartsModal
   - Change dart value and save
   - Cancel preserves original score
   - Edit re-evaluates knockoffs
   - Edit that creates a winner updates stats
   - Edit that removes winner leaves no stats
   - Miss dart pre-selected in edit dialog

3. **`gameplay/`** (19 tests)
   - Score updates after dart throw
   - Podium height changes with score
   - Turn advancement after 3 darts
   - Skip turn with partial darts
   - Skip turn with no darts
   - Knockoff animation and score reset
   - Shield Round blocks knockoff
   - Bust on overshoot (Double Finish ON)
   - Bust on non-double finish (Double Finish ON)
   - Double finish victory (Double Finish ON, last dart is a double on exact target)
   - Standard victory (Double Finish OFF, dart reaches or exceeds target)
   - Speed Play timer display in AppBar
   - Speed Play timer expiry
   - Turn advancement to next player
   - Min player count game (2 players)
   - Max player count game (8 players)
   - Opponent score display / podium layout
   - Target Score low (100) — podiums scale
   - Target Score high (500) — podiums scale

4. **`menu_and_settings/`** (8 tests)
   - Menu initial state (defaults: target 200, double finish ON, shield OFF, speed OFF)
   - Target score slider changes value display
   - Double Finish toggle
   - Shield Round toggle
   - Speed Play toggle
   - Start with defaults
   - Start with all options changed
   - Resume game button appears with saved games

5. **`navigation/`** (4 tests)
   - Menu back to home
   - Game back → settings persist on menu
   - Change Settings → back to home (catches `(route) => false` bug)
   - Change Settings → settings and players preserved

6. **`pause_modal/`** (20 tests)
   - Dartboard paused modal on menu screen
   - Dartboard paused modal on game screen
   - Dartboard paused modal on results screen

7. **`play_to_complete/`** (5 tests)
   - Game completes with default settings
   - Game completes from mid-game state
   - Game completes with target score low (100)
   - Game completes with Double Finish OFF
   - Game completes with Shield Round ON

8. **`results_screen/`** (7 tests)
   - Winner display is correct
   - Rankings ordered by score
   - Knockoff stats displayed
   - Fight Again preserves settings
   - Leave Arena goes to home
   - Winner stats updated (gamesPlayed, gamesWon, gameHistory)
   - Victory music initialized on results screen

9. **`save_resume/`** (16 tests)
   - Save game on back button (0 darts thrown)
   - Save game on back button (after darts thrown)
   - Don't save — leaves game without saving
   - Save button saves and returns to menu
   - Resume button disabled when no saves exist
   - Resume button enabled after save
   - Resume button color when enabled
   - Resume button shows modal
   - Resume game loads correct game state
   - Resume modal shows on game tap
   - Resume modal delete individual save
   - Resume modal delete all saves
   - Resume modal start new game
   - Resume re-save overwrites previous save
   - Auto-delete on game completion
   - Resume button hidden after resuming

10. **`visual_validation/`** (7 tests)
    - Screenshot test (all 12 screenshot states)
    - Active player glow visible on correct podium
    - Dart indicator states (empty/hit/bust/skipped)
    - Goal display shows correct target and 2x badge
    - Option badges (shield banner, double range indicator)

### Non-UI Tests

#### `test/providers/gladiator_arena_provider_game_test.dart` (81 tests)
Provider game mechanics: scoring, elimination check, bust detection (overshoot and no-double), double finish success, shield round blocking, speed play timer expiry, skip turn, knockoff count tracking, multiple simultaneous knockoffs, edit score, win conditions with both Double Finish ON and OFF.

#### `test/screens/games/gladiator_arena/gladiator_arena_announcement_test.dart` (33 tests)
All announcement events: game start, player turn, small/good/great/triple/bull/outer-bull hits, miss, knockoff, shield block, bust overshoot, bust no-double, victory (double finish and standard), near victory, double range, shield round start, speed timer warning, speed timer expired. Includes stacking precedence chain validation (12-level chain) and MAX 2 announcement rule enforcement.

#### `test/providers/gladiator_arena_save_restore_test.dart` (15 tests)
Save game metadata creation, full game state restore via SaveGameService, gameplay continuation after restore, knockoff history preservation, options preservation across save/restore, auto-delete on completion, overwrite existing save.

#### `test/screens/games/gladiator_arena/gladiator_arena_game_test.dart` (26 tests)
Core game logic without announcements: scoring (single/double/triple/bull), turn total accumulation, bust detection paths (overshoot, non-double at exact target), double finish success, knockoff trigger, shield round blocking, speed play timer expiry, player rotation, win condition detection.

#### `test/screens/games/gladiator_arena/gladiator_arena_game_with_announcements_test.dart` (18 tests)
Integration of game logic + announcements: verifies correct announcements fire for each game event including knockoff, bust variants, victory, and shield block; validates precedence resolution when multiple events compete.

#### `test/models/gladiator_arena_serialization_test.dart` (17 tests)
Model serialization: serialize/deserialize default state, mid-game state with scores, state with knockoff history, all options (target, doubleFinish, shieldRound, speedPlay), round-trip toJson→fromJson→toJson matches, speed play timer state, resumed game state.

## Running Tests

### Run All Game Non-UI Tests
```bash
flutter test test/screens/games/gladiator_arena/
flutter test test/models/gladiator_arena_serialization_test.dart
flutter test test/providers/gladiator_arena_provider_game_test.dart
flutter test test/providers/gladiator_arena_save_restore_test.dart
```

Or run all non-UI tests at once:
```bash
flutter test
```

### Run UI Automation Tests
```bash
./run_ui_tests.bat gladiator_arena

# Or run parallel (with other games)
./run_ui_tests_parallel.bat gladiator_arena
```

### Run Specific Subdirectory
```bash
./run_ui_tests.bat gladiator_arena/gameplay
./run_ui_tests.bat gladiator_arena/play_to_complete
```

## Play to Complete Tests
**Location:** `integration_test/gladiator_arena/play_to_complete/`

**Files:**
- `default_settings_test.dart` — Game completes with default settings (Target 200, Double Finish ON, Shield OFF, Speed OFF)
- `mid_game_test.dart` — Manual darts thrown first; Play to Complete finishes from mid-game state
- `target_score_low_test.dart` — Game completes with target = 100
- `double_finish_off_test.dart` — Game completes with Double Finish OFF (standard victory)
- `shield_round_test.dart` — Game completes with Shield Round ON (verifies Shield Round blocks don't prevent completion)

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

## Navigation Tests
**Location:** `integration_test/gladiator_arena/navigation/`

All 4 mandatory navigation tests are implemented:

1. **`menu_back_to_home_test.dart`** — Navigate to menu, tap back, verify ≥3 game cards visible on home screen
2. **`game_back_settings_persist_test.dart`** — Change non-default settings, start game, tap game back, verify settings preserved on menu
3. **`change_settings_back_to_home_test.dart`** — Complete game → Change Rules → verify menu → tap back → verify ≥3 game cards on home screen
4. **`change_settings_preserves_settings_test.dart`** — Complete game → Change Rules → verify settings and players preserved on menu

The `navigation/_helpers.dart` file delegates to the shared `GameUIConfig.gladiatorArena()` instance.

## Widget Keys Used

### Menu Screen Keys
**Class:** `GladiatorArenaMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `backButton` — AppBar back button
- `targetScoreSlider` — Target Score slider (100–500, step 25)
- `targetScoreValue` — Numeric label showing slider's current value
- `doubleFinishSwitch` — Double Finish toggle
- `shieldRoundSwitch` — Shield Round toggle
- `speedPlaySwitch` — Speed Play toggle
- `startGameButton` — "ENTER THE ARENA!" button
- `addPlayerButton` — "NEW PLAYER" button (header)
- `addPlayerButtonEmptyState` — "NEW PLAYER" button (empty state)
- `playerListView` — Player ListView
- `playerTile(id)` — Individual player tile
- `removePlayerButton(id)` — Player remove button

### Game Screen Keys
**Class:** `GladiatorArenaGameKeys`
**File:** `lib/constants/test_keys.dart`

- `backButton` — AppBar back button
- `skipTurnButton` — Skip Turn button in AppBar actions
- `editScoreButton` — Edit Score button (inside RemoveDartsModal)
- `podium(playerId)` — Individual player podium
- `activePlayerNameLabel` — Active player name rendered under their highlighted podium
- `goalDisplay` — Target score display in top bar below AppBar
- `doubleRangeIndicator` — "Double Range!" text above active player's podium
- `dartIndicator(index)` — Individual dart indicator (0–2) in AppBar
- `timerDisplay` — Speed Play countdown timer in AppBar
- `shieldBanner` — Shield Round banner
- `eliminationZone` — Elimination event display
- `doubleBadge` — "2x" badge next to goal display

### Results Screen Keys
**Class:** `GladiatorArenaResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `winnerCharacterImage` — Winner character image (left side of winner row)
- `winnerPlayerPhoto` — Winner player photo / fallback initial avatar (right side of winner row)
- `winnerName` — Winner name text
- `winnerScore` — Winner final score
- `rankingsList` — Rankings list container
- `rankRow(index)` — Individual rank row
- `knockoffStats` — Knockoff statistics section
- `playAgainButton` — "FIGHT AGAIN" button
- `changeSettingsButton` — "CHANGE RULES" button
- `backToMenuButton` — "LEAVE ARENA" button

## Test Patterns

### Delegate Pattern (`_helpers.dart`)
Each subdirectory has a `_helpers.dart` file that provides a `GameUIConfig.gladiatorArena()` instance. All test functions delegate to shared static helpers (`UITestHelpers`, `DartThrowHelpers`, `GameSetupHelpers`, `SaveResumeHelpers`, `PumpSequences`). This avoids code duplication across 99 test files.

```dart
// integration_test/gladiator_arena/_helpers.dart
import '../shared/game_ui_config.dart';
final config = GameUIConfig.gladiatorArena();
```

### Speed Play Timer in Tests
Speed Play UI tests interact with the timer display key (`GladiatorArenaGameKeys.timerDisplay`) and advance time using `tester.pump(const Duration(seconds: N))` to simulate timer countdown without real waiting.

### Knockoff Testing Pattern
Tests that verify knockoff behavior set up two players at the same score, throw a dart that brings the active player's total to exactly match the opponent, then verify the opponent's podium collapses to zero and the elimination zone text appears.

### Double Finish Testing Pattern
- **Overshoot bust:** Score active player's turn total so prospective exceeds target → verify score reverts, dart circles flash red
- **Non-double bust:** Score active player's prospective to exact target, ensure last dart is a single or triple → verify score reverts
- **Double finish win:** Score prospective to exact target, last dart is a double → verify results screen appears

## Known Test Quirks

### Podium Height Assertions
Podium height is rendered as an `AnimatedContainer` and takes ~200ms to animate. Tests that check podium height after a score change must pump at least 300ms (`tester.pump(const Duration(milliseconds: 300))`) to let the animation complete before asserting height.

### Speed Play Timer Tests
The `timerDisplay` key only exists in the widget tree when `speedPlayEnabled == true`. Tests that check for the absence of the timer must ensure the game was started with Speed Play OFF.

### Shield Banner Conditional Rendering
The shield banner only appears on rounds 5, 10, 15, etc. Tests verifying shield banner visibility must advance the game to at least round 5 by using Skip Turn repeatedly.
