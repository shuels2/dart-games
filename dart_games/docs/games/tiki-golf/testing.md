# Tiki Golf - Testing Documentation

## Test Overview

### Test Suite Summary

- **Non-UI Tests:** 234 tests (game logic, providers, models)
- **UI Automation Tests:** 110 test files (109 categorized + 1 screenshot file with 27 captures)
- **Total Tiki Golf-specific tests:** 344

## Non-UI Tests (234 tests)

### Test Files

#### Game Logic Tests
**Location:** `test/screens/games/tiki_golf/`

1. **`tiki_golf_game_test.dart`** (81 tests)
   - Core game model mechanics: hole progression, stroke counting, turn-end detection
   - Per-game randomization: holeTargets and holeImagePaths shuffle correctness
   - Variable darts per turn: Max Darts 3/4/5/6 interactions with stroke counting
   - Splash threshold scaling (maxDarts + 1 for each setting)
   - Win condition evaluation: lowest total wins. **Ties stand** — every player/team at the lowest total is recorded in `winnerIds` / `winnerTeamIds` and every tied player receives a Win.
   - Team mode mechanics: best-ball aggregation (MIN of team player scores per hole)
   - Team mode hole progression: team-grouped rotation within holes
   - Mulligan mechanics: per-player flag, single-use-per-game, replace Splash score, re-throw
   - Skip Turn: records Splash, triggers mulligan eligibility
   - Save/restore: holeTargets and holeImagePaths preserved across serialization

2. **`tiki_golf_announcement_test.dart`** (36 tests)
   - All 14 announcement events with correct text and sound effects
   - 11-rank precedence chain verification
   - MAX 2 announcements per dart enforcement
   - Mulligan reminder vs plain Splash announcement selection
   - announceRemoveDarts fires unconditionally and does not count against budget
   - Random-target note: New Hole announcement uses actual holeTargets value
   - Team mode player turn: includes team name prefix ("Sharks: Alice up to putt!")
   - Priority level assignments (turnTransition, hitConfirm, statusChange, victory)

3. **`tiki_golf_game_with_announcements_test.dart`** (18 tests)
   - Full dart processing triggering correct announcement sequences
   - Birdie fires hitConfirm, Splash fires hitConfirm, are correctly combined with statusChange events
   - Mulligan reminder fires with Splash when mulligan is available (suppresses plain Splash)
   - Victory fires on hole 9 completion, precedes all other simultaneous announcements
   - Remove Darts fires unconditionally alongside other announcements

#### Provider Tests
**Location:** `test/providers/`

4. **`tiki_golf_provider_game_test.dart`** (67 tests)
   - `startGame()` validation: player count ranges (Solo 2-4, Team 3-16)
   - `processDartThrow()`: hit detection, turn-end conditions (a/b), `currentTurnEnded` flag toggle
   - Variable darts per turn: Max Darts 3-6 all behave correctly
   - `currentTurnEnded` resets after `confirmTurnEnd()`
   - `shouldPromptTakeout = currentTurnEnded || hasWinner` (NOT dartsThrown >= 3)
   - Mulligan flow: `useMulligan()` clears score, resets darts, clears currentTurnEnded
   - `skipTurn()`: records Splash, sets currentTurnEnded, mulligan eligible
   - `advanceToNextPlayer()`: Solo sequential; Team grouped-then-handoff rotation
   - `totalTurns` increments exactly once on dart 1 regardless of Max Darts setting
   - Team best-ball aggregation: MIN of player scores per hole per team
   - Random team distribution: all 14 N-values (3-16) produce correct team count/sizes
   - Special cases: N=8 → [4,4] not [2,2,2,2]; N=12 → 4×3 not 3×4
   - Win condition detection after hole 9 completion
   - `editScore()` / `updateAllDartScores()`: replay, re-evaluate win/mulligan eligibility
   - `clearGame()` / `endGame()`

5. **`tiki_golf_save_restore_test.dart`** (13 tests)
   - Save game metadata creation and restoration
   - Full game state restore: scores, current hole, current player, `holeTargets`, `holeImagePaths`
   - Options preserved across save/restore (maxDarts, mulligan, team assignments)
   - Mulligan usage preserved (player that used mulligan still shows used after restore)
   - Gameplay continuation after restore (can throw darts, complete holes)
   - Auto-delete on game completion
   - Overwrite existing save (resume re-save)

#### Model Serialization Tests
**Location:** `test/models/`

6. **`tiki_golf_serialization_test.dart`** (15 tests)
   - `toJson()` / `fromJson()` roundtrip for all `TikiGolfGame` fields
   - `holeTargets` List serialized and deserialized correctly (List of ints, length 9)
   - `holeImagePaths` List serialized and deserialized correctly (List of strings, length 9)
   - `playerScores` Map (playerId → List of hole scores) roundtrip
   - `dartsThrown` and `currentTurnEnded` per-player maps preserved
   - `playerMulliganAvailable` and `playerMulliganUsedThisGame` maps preserved
   - Game options (maxDarts, mulliganEnabled, isTeamMode) preserved
   - Team assignments (teamAssignments, teamCrestPaths) preserved
   - `currentHole` (1-9) and `currentPlayerIndex` preserved
   - `winnerId` / `winnerTeamId` (nullable) roundtrip
   - Backward compatibility: missing optional fields default gracefully

## Running Tests

### Run All Tiki Golf Non-UI Tests
```bash
flutter test test/screens/games/tiki_golf/
flutter test test/providers/tiki_golf_provider_game_test.dart
flutter test test/providers/tiki_golf_save_restore_test.dart
flutter test test/models/tiki_golf_serialization_test.dart
```

### Run Specific Test File
```bash
flutter test test/screens/games/tiki_golf/tiki_golf_game_test.dart
flutter test test/screens/games/tiki_golf/tiki_golf_announcement_test.dart
flutter test test/screens/games/tiki_golf/tiki_golf_game_with_announcements_test.dart
```

### Run All Non-UI Tests (MANDATORY before builds)
```bash
flutter test
```

### Run UI Automation Tests
```bash
# All Tiki Golf UI tests (sequential)
./run_ui_tests.bat tiki_golf

# All Tiki Golf UI tests (parallel)
./run_ui_tests_parallel.bat tiki_golf

# Specific subdirectory
./run_ui_tests_parallel.bat tiki_golf/gameplay
./run_ui_tests_parallel.bat tiki_golf/team_mode_gameplay
./run_ui_tests_parallel.bat tiki_golf/randomization
```

## UI Automation Tests (110 files)

**Location:** `integration_test/tiki_golf/`

### visual_validation/ (1 file, 27 screenshot captures)
- `screenshot_test.dart` — 27 screenshots covering: menu (Solo + Team variants), game screen (Solo mid-game, Team mid-game, mulligan state, Max Darts 4/5/6 variants), results screen (Solo winner, Team winner), Mulligan modal variant

### menu_and_settings/ (11 files)
- Solo mode default state
- Team mode toggle activates team assignment
- Team Assignment = Random: no team boxes shown, team count hidden
- Team Assignment = Manual: team boxes + trailing icons + Team Count dropdown
- Team Assignment toggle grayed out in Solo mode
- Max Darts dropdown: 3/4/5/6 options
- Mulligan toggle ON/OFF
- TEE OFF disabled with < 2 players (Solo), < 3 players (Team)
- TEE OFF disabled when manual team has empty slot
- Settings persistence across navigation
- ResumeGameButton appears when saved games exist

### add_player/ (6 files)
- Add player dialog opens from player tile
- New player appears in available list
- Photo upload integration
- Player creation with name validation
- Cancel button does not add player
- Player persists across menu navigation

### navigation/ (4 files) — mandatory pack
- `menu_back_to_home_test.dart` — Back from menu returns to home with ≥3 game cards
- `game_back_settings_persist_test.dart` — Settings preserved when navigating game → menu
- `change_settings_back_to_home_test.dart` — Change Settings → Back → home with ≥3 game cards
- `change_settings_preserves_settings_test.dart` — Settings/players preserved after results → menu

### gameplay/ (13 files)
- First dart hits target: birdie (1 stroke), turn ends immediately, remaining darts not thrown
- Second dart hits target: par (2 strokes), turn ends
- Third dart hits target: bogey (3 strokes), turn ends
- All darts miss: Splash, turn ends, Remove Darts modal fires
- Skip Turn: records Splash, Remove Darts modal fires
- Mid-turn (dart 2 of 5): Remove Darts modal does NOT fire
- Max Darts 4: 4 slots, worst case 5 strokes
- Max Darts 5: 5 slots, worst case 6 strokes
- Max Darts 6: 6 slots, worst case 7 strokes
- Scorecard updates after each hole completion
- Hole advances after all players complete (9 holes total)
- Running total displayed correctly (sum of hole scores)
- Dart slot states: empty/hit/miss colors

### pause_modal/ (3 files, 20 testWidgets total)
- Pause modal opens when dartboard disconnects (7 tests)
- Pause modal dismisses on reconnect (8 tests)
- Pause modal persists game state (5 tests)

### results_screen/ (5 files)
- Solo: winner displayed with Golden Tiki trophy
- Solo: correct total stroke count shown
- Team: winning team crest displayed large
- Team: all winning team players listed as champions
- Exit button → home screen with ≥3 game cards visible (catches navigation bugs)

### save_resume/ (16 files, 1 testWidget each)
- Standard 16-test save/resume pack (same pattern as other games)
- Covers: basic save, resume from menu, gameplay continues, holeTargets preserved, holeImagePaths preserved, mulligan state preserved, team assignments preserved, auto-delete on completion, overwrite existing save

### edit_score/ (5 files)
- Edit score dialog opens from scorecard row
- Edit score updates hole score correctly
- Edit score re-evaluates win condition
- Max Darts dropdown count matches game settings
- Cancel preserves original score

### play_to_complete/ (5 files)
- `default_settings_test.dart` — Game completes with default settings (Max Darts 3, Mulligan OFF)
- `max_darts_4_test.dart` — Game completes with Max Darts 4
- `mulligan_on_test.dart` — Game completes with Mulligan ON (mulligan fires when available)
- `team_mode_test.dart` — Team mode game completes (all players on all teams play all 9 holes)
- `mid_game_test.dart` — Manual darts thrown for 2 holes, then Play to Complete finishes

### randomization/ (4 files) — Tiki Golf-specific
- `hole_targets_unique_test.dart` — holeTargets contains 9 distinct numbers from 1-20
- `hole_targets_vary_between_games_test.dart` — Two consecutive games produce different holeTargets lists
- `hole_images_shuffled_test.dart` — holeImagePaths contains all 9 theme images in varying order
- `hole_name_follows_image_test.dart` — Displayed hole name matches the shuffled image for that slot

### team_setup/ (10 files) — Tiki Golf-specific
- Solo max 4 players: header shows `(N/4 selected)`, 5th player not selectable
- Team max 16 players: header shows `(N/16 selected)`
- Random assignment: N=3 → 2 teams [2,1]; N=4 → 2 teams [2,2]
- Random assignment: N=8 special case → 2 teams [4,4] not 4 teams [2,2,2,2]
- Random assignment: N=12 special case → 4 teams [3,3,3,3]
- Manual assignment: Team Count dropdown 2/3/4
- Manual assignment: players assignable to teams via trailing icon
- Manual assignment: TEE OFF disabled until all teams have ≥1 player
- Team crests randomly selected from pool of 6 (4 chosen per game)
- Team Assignment toggle grayed out and non-interactive in Solo mode

### team_mode_gameplay/ (10 files) — Tiki Golf-specific
- Team grouped turn order: team A finishes all players before team B starts
- Best-ball score: team hole score = min of member scores
- Active player panel shows team logo + team name + current player in Team mode
- Scorecard rows per team with best-ball score + contributor name
- Mulligan per-player in team mode: each player tracks own mulligan
- Multiple players on same team can each use mulligan on same hole if all splashed
- All players on winning team receive Win stat
- Team total = sum of best-ball hole scores
- Near Win (last hole) uses team name in announcement
- Victory announcement uses team name

## Widget Keys Used

### Menu Screen Keys
**Class:** `TikiGolfMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `startButton` — TEE OFF button
- `addPlayerButton` — Add player button
- `gameModeToggle` — Solo/Team segmented toggle
- `teamAssignmentToggle` — Manual/Random segmented toggle
- `maxDartsDropdown` — Max Darts dropdown
- `mulliganToggle` — Mulligan ON/OFF toggle
- `teamCountDropdown` — Team Count dropdown (Manual mode only)
- `playerTile(playerId)` — Player selection tile

### Game Screen Keys
**Class:** `TikiGolfGameKeys`
**File:** `lib/constants/test_keys.dart`

- `skipTurnButton` — Skip Turn button
- `mulliganButton` — Mulligan button (when Mulligan ON)
- `dartsRemovedButton` — DARTS REMOVED button (standard takeout)
- `useMulliganButton` — USE MULLIGAN button (mulligan variant modal)
- `nextPlayerButton` — NEXT PLAYER button (mulligan variant modal, decline option)
- `dartSlot(n)` — Dart indicator slot n (1-indexed)
- `holeImage` — Themed hole image widget
- `currentHoleLabel` — Hole number display
- `targetNumberLabel` — Target number display
- `dartSingle(N)` — Dartboard single N button
- `dartDouble(N)` — Dartboard double N button
- `dartTriple(N)` — Dartboard triple N button

### Results Screen Keys
**Class:** `TikiGolfResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `playAgainButton` — PLAY AGAIN button
- `changeSettingsButton` — CHANGE SETTINGS button
- `leaveButton` — LEAVE button (returns to home screen)
- `winnerDisplay` — Winner name / team name display
- `goldenTikiImage` — Golden Tiki trophy image (Solo winner)
- `winningTeamCrest` — Winning team crest image (Team winner)

## Test Patterns

### Variable Max Darts Pattern
Tests that exercise different Max Darts values must configure the setting before starting the game and then assert that:
- The correct number of dart slots renders (3-6)
- The Splash threshold is `maxDarts + 1` strokes
- The Remove Darts modal only fires on actual turn-end (not after dart 2 of 4, etc.)

### Randomization Verification Pattern
To verify randomization tests are meaningful (not accidentally passing because the lists happen to match):
```dart
// Run two games; assert holeTargets are different (with high probability)
final game1 = ...; // start and capture holeTargets
await UITestHelpers.resetServerState();
final game2 = ...; // start and capture holeTargets
expect(game1.holeTargets, isNot(equals(game2.holeTargets)));
```
Since targets are random from 1-20 choosing 9, the probability of two identical shuffles is astronomically low (~1 in 60 billion).

### Team Grouped Play Pattern
To assert team-grouped turn order:
1. Start a 3-team game with 2-2-2 players
2. Assert first 2 throws go to Team A players
3. Assert third throw goes to Team B (not team-cycled)
4. Verify team cursor advances only after all team members complete the hole

## Play to Complete Tests
**Location:** `integration_test/tiki_golf/play_to_complete/`

Each test follows the standard pattern:
```dart
await UITestHelpers.resetServerState();
await UITestHelpers.navigateToGameMenu(tester, config);
// Configure settings if needed
await UITestHelpers.addPlayer(tester, 'Player A', config);
await UITestHelpers.addPlayer(tester, 'Player B', config);
await UITestHelpers.startGame(tester, config);
await PlayToCompleteHelpers.tapPlayToComplete(tester);
await PlayToCompleteHelpers.waitForGameCompletion(
  tester, isComplete: () => provider.hasWinner);
expect(provider.hasWinner, isTrue);
expect(config.getPlayAgainButton(), findsOneWidget);
```

## Navigation Tests
**Location:** `integration_test/tiki_golf/navigation/`

All 4 mandatory navigation tests are present. See [Game Integration Requirements](../../development/game-integration.md) for the `Navigator.popUntil(context, (route) => route.isFirst)` rule that these tests enforce.

## Known Test Quirks

### RemoveDartsModal Timing (Variable Darts)
Unlike all other games where the modal fires after exactly 3 darts, Tiki Golf's modal fires on `currentTurnEnded`. Tests that expect the modal must first verify a turn-end condition has been met (hit, all-missed, or skip). Mid-turn modal assertions must use `findsNothing`.

### Randomization Tests are Probabilistic
The `hole_targets_vary_between_games_test.dart` asserts two consecutive games produce different target lists. This has a ~1-in-60-billion probability of false failure. If it fails, re-run.

### Mulligan Button State
The Mulligan button appears only when Mulligan is ON AND a Splash just occurred AND the player hasn't used their mulligan. Tests that click USE MULLIGAN must first deliberately cause a Splash.
