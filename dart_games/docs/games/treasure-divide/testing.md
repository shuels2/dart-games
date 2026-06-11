# Treasure Divide - Testing Documentation

## Test Overview

### Test Suite Summary

- **Non-UI Tests (Flutter):** ~352 tests
  - 89 game logic (`treasure_divide_game_test.dart`)
  - 55 provider game mechanics (`treasure_divide_provider_game_test.dart`)
  - 27 model serialization (`treasure_divide_serialization_test.dart`)
  - 15 save/restore (`treasure_divide_save_restore_test.dart`)
  - 60 announcement direct (`treasure_divide_announcement_test.dart`)
  - 89 game-with-announcements (`treasure_divide_game_with_announcements_test.dart`)
  - 17 PirateAvatarWidget (`pirate_avatar_widget_test.dart`)
- **Non-UI Tests (Server):** 35 tests added in Phase 6
  - V5 migration + face landmarks routes + FaceLandmarkService + model roundtrips
- **UI Automation Tests:** 98 testWidgets across 83 test files
- **Visual Validation Screenshots:** 22 captured states

## Non-UI Tests (~352 Flutter)

### Test Files

#### Game Logic Tests
**Location:** `test/screens/games/treasure_divide/`

1. **`treasure_divide_game_test.dart`** (89 tests)
   - Scoring basics: Single/Double/Triple hits, miss, Bull round, Any Double/Triple
   - Halving logic: all-3-miss halves, flooring, Quarter It (÷4), multiple halvings
   - Round progression: 9/7/12-round sequences correct, all players throw before round advances
   - Custom Targets: unique numbers, Bull always last, Any Double/Triple at correct positions
   - Scoring accumulation: cross-round totals, sum of all hits this round
   - Win conditions: highest score wins, fewer halvings tiebreaker
   - Turn management: 3-dart advance, Skip Turn as miss-all
   - Edit Score: recalculates round total, can prevent or cause halving
   - Save/Restore: all player scores, target sequence, round state, options
   - Team mode — crew rotation: paired crew order (A_P1 → A_P2 → B_P1 → B_P2), solo crew 6 darts in single turn
   - Team mode — SUM aggregation + crew-wide halving: SUM of members' hauls, crew safe if any hit, halved only on whole-crew miss
   - Team mode — win condition + stats: highest crew treasure, all winning-crew players get `won: true`
   - Team mode — solo crew dart budget: `dartsThisTurn == 6` when crew size == 1
   - Team mode — assignment + distribution: `randomDistribution(N)` for all N in 3..10, doubles invariant
   - Pirate theme assignment: shuffle at SET SAIL, unique for ≤8 players, persisted on save/restore

2. **`treasure_divide_announcement_test.dart`** (60 tests)
   - All 22 announcement events with correct text and sound effects
   - Per-dart precedence chain: Bull Hit > Big Hit > Hit Target > Miss
   - Solo turn-end precedence: Quartered > Halved > Safe
   - Team crew precedence: Crew Wipeout > Crew Plunder
   - Round-transition precedence: Last Round > Bull Round > Triple Round > Double Round > Custom Reveal > Standard New Round
   - MAX 2 announcements per event enforcement
   - Victory fires only from `_handleGameWon()`
   - Crew turn announcement names the crew ("The Krakens are up...")
   - Crew wipeout fires ONLY on whole-crew miss (not when one member hits)

3. **`treasure_divide_game_with_announcements_test.dart`** (89 tests)
   - Full dart processing triggering correct announcement sequences
   - Bull Hit / Big Hit / Hit Target / Miss per-dart stacking
   - Halved/Safe/Quartered combined correctly with dart-level announcements
   - Team crew wipeout fires, crew plunder suppressed (cannot coexist)
   - Victory fires on final round completion, precedes all others
   - Remove Darts fires unconditionally alongside other announcements

#### Provider Tests
**Location:** `test/providers/`

4. **`treasure_divide_provider_game_test.dart`** (55 tests)
   - `startGame()` validation (Solo 2-8, Team 3-10 players)
   - `processDartThrow()`: hit detection, score accumulation, turn-end detection
   - `shouldPromptTakeout = turnEnded || hasWinner`
   - Solo halving/quartering after all-miss turns
   - Team SUM aggregation + crew-wide halving (whole crew miss = halve)
   - Solo crew: `dartsThisTurn == 6`, dart budget not advanced at dart 3
   - `randomDistribution(N)`: all N values 3..10 produce correct crew count + sorted sizes
   - Doubles invariant: no crew ever exceeds 2 players in Random mode
   - Solo-crew-at-end invariant: odd player forms last crew
   - Skip Turn at any dart index forfeits remaining darts; counts as miss-all if no hits
   - Edit Score recalculates hauls, re-evaluates halving
   - `advanceToNextPlayer()`: Solo sequential; Team crew-grouped rotation
   - Win condition detection after final round
   - Pirate theme assignment shuffled at start, persisted

5. **`treasure_divide_save_restore_test.dart`** (15 tests)
   - Save game metadata creation and restoration
   - Full game state restore: scores, current round, current player/crew, target sequence
   - Options preserved (quarterIt, customTargets, rounds, game mode, team assignment)
   - Crew rotation state preserved (teamWithinRoundRotationPointer, currentTeamIndex)
   - `playerPirateThemes` map preserved across save/restore
   - Gameplay continuation after restore (can throw darts, complete rounds)
   - Auto-delete on game completion (`resumedSavedGameId` tracking)
   - Overwrite existing save (resume re-save)

#### Model Serialization Tests
**Location:** `test/models/`

6. **`treasure_divide_serialization_test.dart`** (27 tests)
   - `toJson()` / `fromJson()` roundtrip for all `TreasureDivideGame` fields
   - `playerRoundScores` Map (playerId → List of nullable ints) preserved
   - `playerPirateThemes` Map (playerId → themeIndex) preserved
   - Team fields: `gameMode`, `teamAssignment`, `teamCount`, `teamPlayers`, `playerTeamAssignments`, `teamCrestPaths`, `teamWithinRoundRotationPointer` all roundtrip
   - Sentinel target constants in `targetSequence` (kTargetAnyDouble, kTargetAnyTriple, kTargetBull) preserved
   - Options (quarterItEnabled, customTargetsEnabled, totalRounds) preserved
   - `currentRound`, `currentPlayerIndex`, `winnerIds` / `winnerTeamIds` preserved
   - Backward compatibility: missing optional fields default gracefully
   - Max config (5 crews × 2 = 10 players) roundtrips correctly
   - Mid-round with one crew partway through its roster preserved

#### Widget Tests
**Location:** `test/widgets/treasure_divide/`

7. **`pirate_avatar_widget_test.dart`** (17 tests)
   - Renders player avatar at requested size (circular crop)
   - With `faceLandmarks`: hat anchor above boundingBox.y (head-top region)
   - With `faceLandmarks`: eyepatch anchor over leftEye coordinates
   - With `faceLandmarks`: parrot anchored in upper-right frame region (Theme 0)
   - With `faceLandmarks == null`: heuristic hat position at `(0.5, 0.05)` proportional
   - With `faceLandmarks == null`: theme effect still applies (sprites still render)
   - All 8 theme accessory sprite counts: Theme 0 (3), Theme 1 (2), Theme 2 (3), Theme 3 (3), Theme 4 (2), Theme 5 (3), Theme 6 (2), Theme 7 (3)
   - `widthFactor` honored: hat at 1.6× faceScale renders proportionally larger
   - Sprite z-order: face-anchored sprites above avatar; frame-corner sprites at corners but below face-anchored
   - Multiple sizes (24, 40, 48, 80, 120) render proportionally
   - Default-silhouette avatar falls back to heuristic anchors

## Running Tests

### Run All Treasure Divide Non-UI Tests

```bash
flutter test test/screens/games/treasure_divide/
flutter test test/providers/treasure_divide_provider_game_test.dart
flutter test test/providers/treasure_divide_save_restore_test.dart
flutter test test/models/treasure_divide_serialization_test.dart
flutter test test/widgets/treasure_divide/pirate_avatar_widget_test.dart
```

### Run Specific Test File

```bash
flutter test test/screens/games/treasure_divide/treasure_divide_game_test.dart
flutter test test/screens/games/treasure_divide/treasure_divide_announcement_test.dart
```

### Run All Non-UI Tests (MANDATORY before builds)

```bash
flutter test
```

### Run UI Automation Tests

```bash
# All Treasure Divide UI tests (sequential)
./run_ui_tests.bat treasure_divide

# All Treasure Divide UI tests (parallel)
./run_ui_tests_parallel.bat treasure_divide

# Specific subdirectory
./run_ui_tests_parallel.bat treasure_divide/gameplay
./run_ui_tests_parallel.bat treasure_divide/team_mode_gameplay
```

## UI Automation Tests (98 testWidgets, 83 files)

**Location:** `integration_test/treasure_divide/`

### add_player/ (3 files)
- Add player dialog opens, new player appears in available list
- Player creation with name validation (empty name, whitespace)
- Cancel button does not add player; photo UI elements present

### edit_score/ (5 files)
- Edit dialog opens from RemoveDartsModal
- Change dart and save — score updates
- Cancel preserves original score
- Edit can prevent halving (adding a hit)
- Edit can cause halving (removing only hit)

### gameplay/ (12 files)
- Hit target scores points; miss shows miss indicator
- All 3 misses halves score; Quarter It quartering
- Round advances after all players throw; different target each round
- Any Double round accepts any double; Any Triple round accepts any triple
- Bull round (final round)
- Turn advancement; Skip Turn
- Game ends after final round, winner determined
- `PirateAvatarWidget` renders in Active Player Panel, per-player tiles, Results screen but NOT in menu player lists

### menu_and_settings/ (11 files)
- Menu initial state: Game Mode Solo, Team Assignment Random (disabled in Solo), Rounds 9, Quarter It OFF, Custom Targets OFF
- Number of Rounds dropdown (7/9/12)
- Quarter It toggle; Custom Targets toggle
- Start with defaults (Solo, 2 players); start with custom settings (7 rounds, Quarter It ON)
- Game Mode SOLO→TEAM enables Team Assignment toggle
- Team Assignment toggle inactive (50% opacity + IgnorePointer) when Game Mode = SOLO
- Team Assignment Manual↔Random flips `isManualTeamAssignment`
- SET SAIL disabled rules: Solo <2, Team+Random <3, Team+Manual incomplete crew config

### navigation/ (4 files) — mandatory pack
- `menu_back_to_home_test.dart` — Back from menu returns to home with ≥3 game cards
- `game_back_settings_persist_test.dart` — Settings preserved when navigating game → menu
- `change_settings_back_to_home_test.dart` — Change Settings → Back → home with ≥3 game cards
- `change_settings_preserves_settings_test.dart` — Settings/players preserved after results → menu

### pause_modal/ (3 files, 20 testWidgets total)
- Pause modal opens when dartboard disconnects (7 tests)
- Pause modal dismisses on reconnect (8 tests)
- Pause modal persists game state (5 tests)

### play_to_complete/ (5 files)
- `default_settings_test.dart` — Game completes with default settings (9 rounds, Solo)
- `mid_game_test.dart` — Manual darts thrown first, then Play to Complete finishes
- `rounds_7_test.dart` — Game completes with 7 rounds
- `quarter_it_on_test.dart` — Game completes with Quarter It ON (strategy avoids miss-all rounds)
- `team_mode_test.dart` — Team mode game completes (all players on all crews play all rounds)

### results_screen/ (7 files: 5 base + 2 added gap-closure)
- Solo: winner displayed with correct name, treasure score, and times-halved count
- Solo: rankings ordered by highest gold (tiebreaker: fewer halvings)
- Solo tie (`solo_tie_test.dart`) — two players finish with equal gold; both listed as Pirate Captain
- Team: winning crew crest displayed + all crew members celebrated
- Team tie (`team_tie_test.dart`) — two crews finish with equal treasure; both listed as Captain's Crew
- "Sail Again" preserves settings; "Change Course" returns to menu; "Dock Home" goes to home
- Player stats (gamesWon, gamesPlayed) updated on results screen load; victory music triggered

### save_resume/ (16 files)
- Basic save from back button; resume from menu; resumed state matches saved state (Solo)
- Auto-delete on resume (save no longer appears in ResumeGameModal)
- Team mode: save mid-round then resume — crew rotation, per-member hauls, crew totals, crest assignments all restored
- Team mode: save + resume preserves a crew's "halved this game" count correctly
- Standard 16-test pack covering all major save/restore scenarios

### team_setup/ (7 files: 4 base + 3 added gap-closure)
- Random distribution full-table coverage: for every N from 3 to 10 verifies crew count + sizes
- Manual assignment: team-assign trailing icon opens TeamAssignmentDialog; picking a crew updates assignments
- Team + Manual renders crew boxes + trailing icons + Crews dropdown (all 3 found)
- Team + Random renders NONE of those (identical to Solo)
- `solo_to_team_test.dart` — toggling Solo → Team keeps panel mounted, players stay selected
- `team_to_solo_test.dart` — toggling Team → Solo keeps panel mounted, crew boxes disappear
- `team_random_no_ui_test.dart` — Random mode shows no crew boxes/trailing icons/Crews dropdown

### team_mode_gameplay/ (4 files: 3 base + 1 added gap-closure)
- Team 2v2: round 1 throw order A_P1 → A_P2 → B_P1 → B_P2 (crew A plays through, then crew B)
- Team safe: crew A hauls {60, 0} → banks +60, NOT halved; Team wipeout: crew A hauls {0, 0} → halved
- Solo crew badge + 6 dart indicators: "Solo Crew: 6 darts" badge visible + Active Panel shows 6 slots
- `team_results_all_winning_players_test.dart` — all players on winning crew get Win stat; losing crew does not

### visual_validation/ (6 files: 4 programmatic + 2 screenshot files capturing 22 states)

#### Programmatic tests (4 files)
- Current target badge renders correctly (kTargetAnyDouble, kTargetAnyTriple, kTargetBull sentinel constants)
- Quarter It badge visible when enabled, absent when disabled
- Custom badge visible + "???" on future islands when Custom Targets ON
- Solo Crew 6-dart badge and 6 indicator slots render for 1-player crew (Team mode)

#### Screenshot files (2 files)

**File 1: `treasure_divide_screenshot_test.dart`** — menu and game screens (11 captures)
1. Menu — default settings, no players (Solo)
2. Menu — Solo with players ready to start
3. Menu — 7 rounds, Quarter It ON
4. Menu — Custom Targets ON
5. Menu — Team + Random (Team Assignment toggle enabled; no Crews dropdown/boxes/trailing icons)
6. Menu — Team + Manual + 8 players (crew boxes, trailing icons, Crews dropdown all visible)
7. Menu — Solo mode, Team Assignment toggle visibly grayed out
8. Game — start of game, Round 1 (target: 20), map-dominant layout
9. Game — after darts thrown (hit + miss indicators, +XX floater, round status on tile)
10. Game — treasure map showing progress (several rounds completed)
11. Game — QUARTER IT badge visible

**File 2: `treasure_divide_screenshot_results_test.dart`** — game variants and results (11 captures)
12. Game — CUSTOM badge with "???" on future islands
13. Game — player score halved (HALVED! status, chest tipping)
14. Game — Any Double special round
15. Game — RemoveDartsModal visible (during takeout)
16. Game (Team) — per-crew tiles in bottom strip, active crew highlighted, shared chest on map
17. Game (Team) — whole-crew wipeout ("ALL HANDS LOST!" status)
18. Game (Team, solo crew turn) — "Solo Crew: 6 darts" badge + 6 dart indicator slots
19. Game — PirateAvatarWidget: 4+ players with distinct pirate theme overlays
20. Game — heuristic fallback: player with no landmarks still shows themed accessories
21. Results (Solo) — winner display, rankings, buttons; PirateAvatarWidget in winner + every ranking row
22. Results (Team) — winning crew crest + all crew members celebrated, crew rankings

## Widget Keys Used

### Menu Screen Keys
**Class:** `TreasureDivideMenuKeys`
**File:** `lib/constants/test_keys.dart`

- `backButton` — AppBar back button
- `gameModeToggle` — Game Mode segmented toggle (Row 1 Left)
- `gameModeSolo` — "SOLO" segment
- `gameModeTeam` — "TEAM" segment
- `teamCountDropdown` — Inline Crews dropdown (TEAM + MANUAL only)
- `assignmentModeToggle` — Team Assignment segmented toggle (Row 1 Right)
- `assignmentModeManual` — "MANUAL" segment
- `assignmentModeRandom` — "RANDOM" segment
- `teamBox(teamIndex)` — Individual crew-assignment box (Manual only)
- `teamPlayerChip(teamIndex, playerId)` — Player chip inside crew box (Manual only)
- `teamAssignDropdown(playerId)` — Per-player team-assign trailing icon (Manual only)
- `roundsDropdown` — Number of Rounds dropdown
- `quarterItSwitch` — Quarter It toggle
- `customTargetsSwitch` — Custom Targets toggle
- `startGameButton` — "SET SAIL!" button
- `addPlayerButton` — "NEW PIRATE" button (header)
- `addPlayerButtonEmptyState` — "NEW PIRATE" button (empty state)
- `playerListView` — Player ListView
- `playerTile(id)` — Individual player tile
- `removePlayerButton(id)` — Player remove button
- `resumeGameButton` — Resume game button

### Game Screen Keys
**Class:** `TreasureDivideGameKeys`
**File:** `lib/constants/test_keys.dart`

- `backButton` — AppBar back button
- `skipTurnButton` — Skip Turn button
- `editScoreButton` — Edit Score (inside RemoveDartsModal)
- `treasureMap` — Treasure map container (center dominant)
- `mapIsland(round)` — Individual island on map
- `currentTarget` — Current target display (beside current island)
- `roundIndicator` — "Island X/Y" scroll graphic
- `mapChestImage` — Large treasure chest on map (animates on halve/quarter)
- `playerTreasureStrip` — Bottom strip container
- `playerTile(playerId)` — Per-player compact tile (Solo mode)
- `playerAvatar` — Active player avatar (Active Player Panel)
- `treasureScore` — Active player / active crew treasure total (Active Player Panel)
- `roundScore` — Active player round score (Active Player Panel)
- `dartIndicator(index)` — Dart indicator slot (0..2 normally; 0..5 for solo crew)
- `quarterItBadge` — "QUARTER IT" badge
- `customBadge` — "CUSTOM" badge
- `soloCrewBadge` — "Solo Crew: 6 darts" badge
- `roundStatus(playerId)` — HIT/SAFE/HALVED status per player (Solo)
- `crewTile(teamId)` — Per-crew compact tile (Team mode)
- `crewCrest(teamId)` — Crew crest image
- `crewTreasureScore(teamId)` — Crew shared treasure total on tile
- `crewRoundStatus(teamId)` — Crew PLUNDER/HALVED status pill
- `crewMemberHaul(teamId, playerId)` — Per-member haul entry inside crew tile
- `activeCrewCrest` — Active crew crest in Active Player Panel (Team mode)

### Results Screen Keys
**Class:** `TreasureDivideResultsKeys`
**File:** `lib/constants/test_keys.dart`

- `winnerName` — Winner name text (Solo: player; Team: crew name)
- `winnerPhoto` — Winner PirateAvatarWidget (Solo)
- `winnerCrewCrest` — Winning crew crest (Team)
- `winnerCrewPlayer(playerId)` — Each winning-crew player avatar + name (Team)
- `treasureScore` — Winner treasure score
- `timesHalved` — Winner times halved count
- `playAgainButton` — "SAIL AGAIN" button
- `changeSettingsButton` — "CHANGE COURSE" button
- `backToMenuButton` — "DOCK HOME" button
- `playerRanking(index)` — Individual ranking row (Solo)
- `crewRanking(index)` — Crew ranking row (Team)

## Test Patterns

### Sentinel Target Pattern

Tests that exercise Any Double, Any Triple, or Bull rounds must use the sentinel constants (not arbitrary ints):
```dart
// From the provider test
expect(provider.currentTarget, equals(kTargetAnyDouble));
// To throw a hit on Any Double:
provider.processDartThrow(DartThrow.double(20));  // D20 = 40, counts as "any double" hit
```

### Solo Crew 6-Dart Pattern

Tests that exercise the solo crew fairness rule must verify:
1. `dartsThisTurn == 6` when active crew has `members.length == 1`
2. Rotation pointer does NOT advance after dart 3
3. Halving fires only when all 6 miss (not when 3 miss out of 6)

```dart
// Verify 6-dart budget
expect(provider.dartsThisTurn, equals(6));
// Throw 3 misses — should NOT trigger halving yet
for (int i = 0; i < 3; i++) provider.processDartThrow(DartThrow.miss());
expect(provider.currentTurnEnded, isFalse);
// Throw 3 more misses — now all 6 missed, should trigger halving
for (int i = 0; i < 3; i++) provider.processDartThrow(DartThrow.miss());
expect(provider.currentTurnEnded, isTrue);
```

### PirateAvatarWidget Render Verification

To verify PirateAvatarWidget is used (not plain PlayerAvatarWidget) at the game screen and results:
```dart
// Confirm PirateAvatarWidget exists on game screen
expect(find.byType(PirateAvatarWidget), findsWidgets);
// Confirm NOT present on menu screen player list
// (menu uses plain PlayerAvatarWidget)
```

## Play to Complete Tests

**Location:** `integration_test/treasure_divide/play_to_complete/`

| File | Settings | Description |
|---|---|---|
| `default_settings_test.dart` | Default (9 rounds, Solo) | Baseline game completes |
| `mid_game_test.dart` | Default (9 rounds) | 2 rounds of manual darts first, then P2C |
| `rounds_7_test.dart` | 7 rounds | Short game completes |
| `quarter_it_on_test.dart` | Quarter It ON | Strategy ensures hits to avoid 75% penalty |
| `team_mode_test.dart` | Team mode, 2 crews | All crew members play all rounds, crew wins |

## Navigation Tests

**Location:** `integration_test/treasure_divide/navigation/`

All 4 mandatory navigation tests are present. Uses `Navigator.popUntil(context, (route) => route.isFirst)` (NOT `pushNamedAndRemoveUntil`) to return to home screen — enforced by the change_settings_back_to_home test.

## Visual Validation Tests

### Programmatic Visual Tests

**File:** `integration_test/treasure_divide/visual_validation/`

Tests check widget presence and key rendering properties (badge visibility, dart indicator count, team vs solo rendering) without requiring screenshots.

### Screenshot Tests

**Files:** `treasure_divide_screenshot_test.dart` and `treasure_divide_screenshot_results_test.dart`

22 states captured total (split across two files to stay under the 600s parallel-runner budget).

## Known Gaps (Acceptable)

The following scenarios have reduced or indirect coverage — reviewed and accepted after Phase 10 spec coverage audit:

- **add_player edge cases** (empty/whitespace/cancel/photo validation) — covered by shared AddPlayerDialog tests in other games; TD's 3-file pack covers the TD-specific flow
- **team_setup/random_post_shuffle_varies** — RNG variability spot-check; not blocking since `randomDistribution(N)` is exhaustively tested in provider non-UI tests for all N in 3..10
- **team_setup/manual_to_random_toggle** — covered indirectly by the `solo_to_team` and `team_to_solo` toggle tests and the Manual/Random direct toggle tests
- **team_mode_gameplay/teams_panel_active_highlight** — visual nuance; covered by screenshot test captures 16–18 which show active crew highlighting
- **Provider tests -12 from Tiki Golf** — TD has 55 provider game mechanics tests vs Tiki Golf's 67. The difference reflects TD's simpler gameplay (Halve It has no variable-darts mechanic, no mulligan, no birdie/par/bogey stroke count) — a direct comparison is not appropriate

## Known Test Quirks

### RemoveDartsModal fires on turn-end

Unlike a fixed 3-dart-count trigger, the RemoveDartsModal fires when `shouldPromptTakeout` is true (which is `turnEnded || hasWinner`). For the solo crew case, `turnEnded` fires after dart 6 (not dart 3). Tests that expect the modal must verify a turn-end condition has been met.

### Solo crew turn-end timing

For a 1-player crew, `dartIndicator(3)` through `dartIndicator(5)` are only visible during that crew's turn. Tests that check dart slots 0..5 must run during the solo crew player's active turn.
