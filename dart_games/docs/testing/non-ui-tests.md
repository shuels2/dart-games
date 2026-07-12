# Non-UI Tests

## Overview

2653 non-UI tests (2428 Flutter + 225 server) validate models, providers, services, widgets, game logic, API client, and server routes.

**Run with:** `flutter test` and `cd server && dart test`
**Execution time:** Seconds
**MANDATORY:** 100% pass rate required before every build

## Test Categories

### Model Tests (98 tests)

**GameHistoryEntry (12 tests)** - `test/models/game_history_entry_test.dart`
- Factory constructor, JSON serialization
- Duration format handling
- New stats fields (dartThrows, turns, playerCount)
- Backward compatibility

**Player (16 tests)** - `test/models/player_test.dart`
- Player creation with/without photos
- Game history serialization
- copyWith() functionality
- Equality operators

**VictoryMusicFile (12 tests)** - `test/models/victory_music_file_test.dart`
- Instance creation and validation
- JSON serialization
- File extensions and formats
- Data URL sources

**Additional Models (58 tests)** - `test/models/additional_model_tests.dart`
- Dartboard: 13 tests (creation, JSON serialization, emulator flag)
- DartboardConnectionProfile: 8 tests (creation, JSON roundtrip, lastUsed sorting)
- ApiLogEntry: 17 tests (creation, formatting, duration tracking)
- SavedGameMetadata: 20 tests (creation, JSON serialization, progress info)

### Model Serialization Tests (169 tests)

**HorseRaceGame (10 tests)** - `test/models/horse_race_game_serialization_test.dart`
**TargetTagGame (13 tests)** - `test/models/target_tag_game_serialization_test.dart`
**MonsterMashGame (13 tests)** - `test/models/monster_mash_game_serialization_test.dart`
**ReefRoyaleGame (19 tests)** - `test/models/reef_royale_game_serialization_test.dart`
**ClockworkQuestGame (19 tests)** - `test/models/clockwork_quest_game_serialization_test.dart`
**LunarLanderGame (12 tests)** - `test/models/lunar_lander_game_serialization_test.dart`
- toJson/fromJson roundtrip for all game fields
- Enum serialization (game states, inventor assignments, character assignments)
- Per-player altitude maps, dart tracking arrays, turn start altitude state
- Hard landing mode, all game states, character assignments

**PiratesGridGame (24 tests)** - `test/models/pirates_grid_serialization_test.dart`
**GladiatorArenaGame (17 tests)** - `test/models/gladiator_arena_serialization_test.dart`
**TikiGolfGame (15 tests)** - `test/models/tiki_golf_serialization_test.dart`
**TreasureDivideGame (27 tests)** - `test/models/treasure_divide_game_serialization_test.dart`
- toJson/fromJson roundtrip for all TreasureDivideGame fields
- targetSequence List with sentinel constants (kTargetAnyDouble=-1, kTargetAnyTriple=-2, kTargetBull=-3) preserved
- playerScores, playerHauls, playerDartResults maps preserved (including null hauls for missed turns)
- Team fields: teamAssignments, teamCrests, playerPirateThemes maps preserved
- Game options (roundCount, isQuarterIt, isTeamMode, isManualTeamAssignment, isCustomTargets) preserved
- currentRound, currentPlayerIndex, currentTeamIndex preserved
- winnerId / winnerTeamId (nullable) roundtrip
- Backward compatibility: missing optional fields (pirate themes, face landmarks) default gracefully
- toJson/fromJson roundtrip for all TikiGolfGame fields
- holeTargets List (length 9, distinct ints) serialized and deserialized correctly
- holeImagePaths List (length 9) serialized and deserialized correctly
- playerHoleScores Map (playerId → List of nullable ints) preserved
- playerMulliganAvailable and playerMulliganUsedThisGame maps preserved
- Game options (maxDarts, mulliganEnabled, isTeamMode) preserved
- Team assignments and teamCrestPaths preserved
- winnerId/winnerTeamId (nullable) roundtrip
- Backward compatibility: missing optional fields default gracefully
- toJson/fromJson roundtrip for all GladiatorArenaGame fields
- playerScores Map (playerId → int) serialized and deserialized correctly
- playerCharacters Map (playerId → character name string) roundtrip
- knockoffsDealt and knockoffsReceived Maps preserved
- All game options (targetScore, doubleFinishEnabled, shieldRoundEnabled, speedPlayEnabled)
- currentRound and currentPlayerIndex preserved
- winnerId (nullable) roundtrip
- Backward compatibility: missing optional fields default gracefully
- toJson/fromJson roundtrip for all PiratesGridGame fields
- Grid serialization: 3x3 List<List<GridCell>> preserved exactly
- Cell owner IDs (null/P1/P2) serialize and deserialize correctly
- winningLine (nullable List<GridPosition>) roundtrip
- matchWinnerId, isMatchDraw, roundsWon Map, currentRound preserved
- TargetDifficulty enum roundtrip (Easy/Medium/Hard)
- Best Of setting (1/3/5), Steal Mode, Speed Play booleans preserved
- Backward compatibility: missing optional fields default gracefully

### Provider Tests (74 tests)

**PlayerProvider (44 tests)** - `test/providers/player_provider_test.dart`
- Player CRUD operations
- Player selection (up to max players)
- Game stats tracking
- Game history methods
- Total play time calculations
- Alphabetical sorting

**DartboardProvider (30 tests)** - `test/providers/dartboard_provider_test.dart`
- Initial state, emulator mode activation
- Connection profile CRUD (save, load, delete, upsert by serial)
- loadConfiguration with emulator config
- Status checking, clear dartboard/error
- Change notification verification

### Provider Save/Restore Tests (85 tests)

**HorseRaceProvider (7 tests)** - `test/providers/horse_race_provider_save_restore_test.dart`
**TargetTagProvider (7 tests)** - `test/providers/target_tag_provider_save_restore_test.dart`
**MonsterMashProvider (7 tests)** - `test/providers/monster_mash_provider_save_restore_test.dart`
**ReefRoyaleProvider (7 tests)** - `test/providers/reef_royale_provider_save_restore_test.dart`
**ClockworkQuestProvider (7 tests)** - `test/providers/clockwork_quest_provider_save_restore_test.dart`
**LunarLanderProvider (7 tests)** - `test/providers/lunar_lander_save_restore_test.dart`
**PiratesGridProvider (12 tests)** - `test/providers/pirates_grid_save_restore_test.dart`
**GladiatorArenaProvider (15 tests)** - `test/providers/gladiator_arena_save_restore_test.dart`
**TikiGolfProvider (13 tests)** - `test/providers/tiki_golf_save_restore_test.dart`
**TreasureDivideProvider (15 tests)** - `test/providers/treasure_divide_save_restore_test.dart`
- Save game metadata creation and restoration
- Full game state restore (scores, round, player index, knockoff history)
- Options preserved across save/restore (targetScore, doubleFinish, shieldRound, speedPlay)
- Character assignments preserved
- Gameplay continuation after restore
- Auto-delete on game completion
- Overwrite existing save (resume re-save)
- Save game metadata creation
- Full game state restore via SaveGameService
- Gameplay continuation after restore
- resumedSavedGameId lifecycle

### Provider Game Mechanics Tests (436 tests)

**HorseRaceProvider (50 tests)** - `test/providers/horse_race_provider_game_test.dart`
- startGame validation (player count, target score range)
- processDartThrow (scoring, accumulation, takeout trigger)
- Exact score mode (bust behavior, exact win)
- skipTurn (visual markers, takeout trigger)
- handleTakeoutFinished (player advancement, winner detection)
- Turn cycling (order, wrap-around, dart reset)
- editScore / updateAllDartScores (replay, validation)
- getHorsePosition (fractional progress, clamping)
- clearGame / endGame / getFinalStandings

**ClockworkQuestProvider (49 tests)** - `test/providers/clockwork_quest_provider_game_test.dart`
- startGame (player count, inventor assignment, maxTarget)
- processDartThrow normal mode (hit/miss, wrong target, parsing)
- processDartThrow speed mode (any uncompleted target, already-completed)
- Target advancement and laps (bullseye, multi-lap win)
- Turn management (totalTurns, next player, wrap-around, takeout)
- skipTurn and editScore
- Win conditions (single-lap, speed mode)
- Dart tracking arrays (hitTarget, advanced, completedLap)

**MonsterMashProvider (44 tests)** - `test/providers/monster_mash_provider_game_test.dart`
- startGame (player count, healthMax validation, unique targets/monsters)
- processDartThrow (miss, sector parsing, damage calculation)
- Health mechanics (self-heal, heal cap, opponent damage, bull/bullseye)
- Elimination (health reaching 0, skip in rotation)
- handleTakeoutFinished, turn cycling, skipTurn
- Win detection (last standing, speed play round-limit)
- editScore (replay, validation)
- Dart throw tracking (heal amounts, damage dealt)

**ReefRoyaleProvider (45 tests)** - `test/providers/reef_royale_provider_game_test.dart`
- startGame (player count, zero-initialized marks, game mode)
- processDartThrow (miss, non-target, takeout, Bull/OuterBull, multipliers)
- Marks system (single/double/triple, easyClaim, riptideRush buff)
- Claiming and locking (threshold, easyClaim, all-claimed lock)
- handleTakeoutFinished, turn cycling, skipTurn
- editScore (updateDartScore, updateAllDartScores)
- clearGame / endGame
- Getters (pearl values, claimed count, ranked players, active buff)

**TargetTagProvider (45 tests)** - `test/providers/target_tag_provider_game_test.dart`

**GladiatorArenaProvider (81 tests)** - `test/providers/gladiator_arena_provider_game_test.dart`

**TikiGolfProvider (67 tests)** - `test/providers/tiki_golf_provider_game_test.dart`
- startGame validation (Solo 2-4 players, Team 3-16 players)
- processDartThrow: hit detection, turn-end conditions, currentTurnEnded flag toggle
- Variable darts per turn: Max Darts 3/4/5/6 all behave correctly
- shouldPromptTakeout = currentTurnEnded || hasWinner (NOT dartsThrown >= fixedN)
- Mulligan flow: useMulligan() clears score, resets darts, clears currentTurnEnded
- skipTurn(): records Splash, sets currentTurnEnded, mulligan eligible
- advanceToNextPlayer(): Solo sequential; Team grouped-then-handoff rotation
- totalTurns increments exactly once on dart 1 (unchanged by Max Darts setting)
- Team best-ball aggregation: MIN of team player scores per hole
- Random team distribution: all 14 N-values (3-16) produce correct team count/sizes
- Special cases: N=8 → [4,4] not [2,2,2,2]; N=12 → 4×3 not 3×4
- Win condition detection after hole 9 completion (Solo + Team)
- editScore / updateAllDartScores: replay, re-evaluate win/mulligan eligibility
- clearGame / endGame

**TreasureDivideProvider (55 tests)** - `test/providers/treasure_divide_provider_game_test.dart`
- startGame validation (Solo 2-8 players, Team 3-10 players), pirate theme shuffle (distinct for ≤8)
- processDartThrow: hit/miss per target type (number, Any Double, Any Triple, Bull)
- Halving / quartering at turn end: `floor(score / 2)`, `floor(score / 4)`, edge cases (0 gold, accumulation)
- Quarter It variant: quartering fires in place of halving when option ON
- Solo crew fairness: 1-member crew throws 6 darts; dartsThisTurn getter returns 6 not 3
- advanceToNextPlayer(): Solo sequential; Team grouped-then-handoff rotation (pointer advances on `dartsThisTurn`)
- Team SUM aggregation: crew round gain = sum of all members' hauls per dart
- Crew-wide halving: fires only when ALL crew darts miss (every member has zero haul)
- randomDistribution(N) for all N in 3..10: pairs = N÷2, hasOdd = (N%2==1), result = [2]*pairs + ([1] if hasOdd)
- Special cases: N=3 → [2,1]; N=4 → [2,2]; N=6 → [2,2,2]; N=9 → [2,2,2,2,1]
- Round progression: 7/9/12-round sequences; sentinel constants kTargetAnyDouble/kTargetAnyTriple/kTargetBull
- Custom targets: when isCustomTargets=true, targetSequence rebuilt from customTargetList
- Win condition detection (Solo + Team): last round completion; tiebreakers (total darts hit > fewer rounds played)
- editScore / updateAllDartScores: replay, re-evaluate halving/win
- clearGame / endGame; resumedSavedGameId auto-delete on results screen load
- startGame (player count, character assignment, options initialization)
- processDartThrow (scoring accumulation, turn total, shouldPromptTakeout)
- Bust detection (overshoot, non-double at exact target, both are Double Finish ON only)
- Double finish victory (exact target on a double)
- Standard victory (Double Finish OFF: score at or above target)
- Knockoff check (score-match reset, self-match ignored, multiple simultaneous knockoffs)
- Shield round blocking (every 5th round, shieldRoundEnabled required)
- Speed play timer expiry (only throws-already-made count)
- Skip turn (0 darts, partial darts, still runs knockoff check)
- Edit score (updateAllDartScores, re-evaluate bust/knockoff/victory)
- Turn cycling and player rotation
- Knockoff count tracking (knockoffsDealt, knockoffsReceived)
- startSoloGame / startTeamGame (player count, shieldMax validation)
- processDartThrow (miss, Bull parsing, takeout trigger)
- Shield mechanics (single/double/triple, cap, taggedIn, attack)
- handleTakeoutFinished, turn cycling, skipTurn
- Elimination (0 shields, last standing wins)
- editScore (replay, validation, single dart edit)
- clearGame / endGame
- Getters (activePlayers, targetNumber, dart tracking)
- Hero bonus (buff numbers, distinct from targets)

### API Client Tests (49 tests)

**ApiConfig (5 tests)** - `test/services/api/api_config_test.dart`
- URL configuration and construction
- Default and custom base URLs

**ApiClient (38 tests)** - `test/services/api/api_client_test.dart`
- All endpoint methods (settings, dartboard, players, games, music)
- Error handling and status codes
- Request/response serialization

### Service Tests (91 tests)

**AppSettings (20 tests)** - `test/services/app_settings_test.dart`
- Google API key storage
- Voice engine preference
- Voice selection
- Settings persistence via API

**VictoryMusicService (22 tests)** - `test/services/victory_music_service_test.dart`
- Singleton pattern
- Music file management via API
- Random selection
- Server URL playback

**StorageService (24 tests)** - `test/services/storage_service_test.dart`
- Singleton pattern
- Bearer token and serial number management
- Setup complete flag
- clearAll, hasAuth, hasDartboard

**ApiLoggerService (25 tests)** - `test/services/api_logger_service_test.dart`
- Start/stop logging
- addLogEntry, updateNote, clearLogs
- Log stream
- Static logApiCall helper

### Save Game Service Tests (13 tests)

**SaveGameService (13 tests)** - `test/services/save_game_service_test.dart`
- Save/load/delete CRUD operations

### Announcement Queue Model Tests (30 tests)

**GameAnnouncementQueueService models (30 tests)** - `test/services/game_announcement_queue_service_test.dart`
- AudioPriority: 8 tests (enum values, ordering)
- SoundEffectConfig: 7 tests (construction, defaults, const)
- QueuedAnnouncement: 7 tests (construction, defaults, priority levels)
- Priority ordering logic: 8 tests (sort comparator, FIFO, mixed priorities)

### Integration Tests (163 tests)

**Carnival Derby User Management (26 tests)**
- Winner/loser stat tracking with duration
- Stats persistence
- Skip turn handling
- Edit score functionality

**Carnival Derby Game Logic (17 tests)**
- Normal mode scoring
- Perfect Finish mode with busts
- Announcement validation
- Precedence coverage (bust on 3rd dart, skip with 0 darts, all misses, win scenarios)

**Target Tag Game Logic + Announcements (54 tests)**
- Solo mode mechanics with announcement precedence
- Team mode mechanics with announcement precedence
- Hero bonus behavior
- Edit score functionality
- Precedence coverage (Tagged Out suppression, hero bonus edge cases, bullseye, multiple eliminations/tagged outs, winner timing)

**Target Tag User Management (14 tests)**
- Winner/loser stats with duration
- Team mode stats
- Stats persistence

**Monster Mash Game Logic + Announcements (47 tests)**
- Basic game mechanics (healing, damage, elimination)
- Dart outcomes (own target, opponent target, bullseye, outer bull, miss)
- Bonus buff mechanics (Blood Moon, Ancient Bandages, Shadow Walk, Laboratory Spark)
- Speed Play and round limit behavior
- Hat Trick and Clutch Heal detection
- Edit score with state snapshots
- Multiple winner tiebreak logic

**Monster Mash Announcements (18 tests)**
- Announcement message text verification
- Precedence rule validation (10 rules)
- All health warning tier crossings (weaken, critical, barely clinging)
- Buff-modified announcements (Shadow Walk, Blood Moon, Ancient Bandages, Lab Spark)
- Edge cases (eliminated opponent hit, bullseye at full health, Max Health text)
- Combined elimination and hat trick + elimination merged announcements

**Clockwork Quest Game Logic (66 tests)**
- Basic game mechanics (target advancement, gear activation)
- Sequential and speed mode progression
- Bullseye mode (gear 21)
- Multi-lap completion
- Multi-player games (2-8 players)
- Inventor character assignments
- Edit score with speed mode and bullseye
- Full game completion with all option permutations
- Edge cases (serialization, clearGame, ignored inputs)

**Clockwork Quest Announcements (18 tests)**
- All 14 announcement events
- Sound effect assignments
- MAX 2 announcements rule
- Announcement priority ordering
- Text generation with player names

**Lunar Lander Game Logic (33 tests)** - `test/screens/games/lunar_lander/lunar_lander_game_test.dart`
- Basic scoring: single, double, triple, outer bull, inner bull subtraction
- Starting altitude initialization (100, 200, 300, 500) and proportional rocket position
- Hard Landing ON: bust behavior, revert altitude, remaining darts forfeited
- Hard Landing OFF: negative altitude allowed, win from negative
- Turn advancement, skip turn, multi-player cycling
- Win condition detection (exact 0, below 0 with HL OFF)
- Edit score updates altitude and re-evaluates win/bust

**Lunar Lander Announcements (33 tests)** - `test/screens/games/lunar_lander/lunar_lander_announcement_test.dart`
- All 10 announcement events (game start, player turn, standard/big descent, miss, near landing, crash landing, negative altitude, climbing back, touchdown)
- Sound effect assignments per event
- Stacking precedence chain (8 levels, Touchdown highest)
- MAX 2 announcements per dart enforcement
- "Remove your darts" unconditional behavior
- Priority level assignments (turnTransition, hitConfirm, statusChange, victory)

**Pirate's Grid Game Logic (31 tests)** - `test/screens/games/pirates_grid/pirates_grid_game_test.dart`
- Grid setup for Easy/Medium/Hard difficulty with correct 3x3 target layouts
- Flag placement: empty cell (Easy/Medium/Hard), already-owned, opponent (Steal OFF), opponent (Steal ON)
- Win detection: horizontal/vertical/diagonal 3-in-a-row; full grid draw; win ends round immediately
- Best Of 1/3/5 round win requirements; grid resets between rounds; starting player alternates
- Speed Play timer: starts, expires, resets per turn

**Pirate's Grid Three-In-A-Row Checker (14 tests)** - `test/screens/games/pirates_grid/three_in_a_row_checker_test.dart`
- Empty grid returns null; 2-in-a-row returns null; mixed grid with no winner returns null
- Horizontal win (all 3 rows); vertical win (all 3 columns); both diagonal wins
- Returns correct GridPosition list (3 positions) for the winning line

**Pirate's Grid Announcements (27 tests)** - `test/screens/games/pirates_grid/pirates_grid_announcement_test.dart`
- All 14 announcement events with correct text and sound effects
- Priority ordering: Match Victory > Round Victory > Two in a Row > Flag Planted
- MAX 2 announcements per dart enforcement
- Remove Darts fires unconditionally

**Pirate's Grid Game With Announcements (24 tests)** - `test/screens/games/pirates_grid/pirates_grid_game_with_announcements_test.dart`
- Full dart processing triggering correct announcements
- Steal Mode + 3-in-a-row stacking (Match Victory fires, Square Stolen suppressed)
- Steal Mode + Round Win; Two in a Row after steal; miss announcement
- Best Of 3 round transition announcement; Speed Play expiry turn end

**Gladiator Arena Game Logic (26 tests)** - `test/screens/games/gladiator_arena/gladiator_arena_game_test.dart`
- Basic scoring: single, double, triple, outer bull, inner bull accumulation
- Turn total and score update after 3 darts
- Hard bust path (overshoot) and non-double bust at exact target
- Double finish success: exact target with a double as last dart
- Standard victory (Double Finish OFF): score reaching or exceeding target
- Knockoff trigger: score-match resets opponent; self-match ignored
- Multiple simultaneous knockoffs in one turn
- Shield round blocking knockoff (every 5th round)
- Speed play timer expiry: only thrown darts counted
- Skip turn: zero-dart and partial-dart scenarios

**Gladiator Arena Announcements (33 tests)** - `test/screens/games/gladiator_arena/gladiator_arena_announcement_test.dart`
- All 16 announcement events (game start, player turn, small/good/great/triple/bull/outer-bull, miss, knockoff, shield block, bust overshoot, bust no-double, victory both variants, near victory, double range, shield round start, speed timer warning, speed timer expired)
- Sound effect assignments per event
- Stacking precedence chain (12-level, Victory highest)
- MAX 2 announcements per dart enforcement
- announceRemoveDarts fires unconditionally

**Gladiator Arena Game With Announcements (18 tests)** - `test/screens/games/gladiator_arena/gladiator_arena_game_with_announcements_test.dart`
- Full dart processing triggering correct announcements per event type
- Knockoff + scoring stacking (knockoff fires, scoring suppressed)
- Bust variants + precedence; Victory precedence over all others
- Shield block fires instead of knockoff during shield round
- Remove Darts fires unconditionally alongside other announcements

**Tiki Golf Game Logic (72 tests)** - `test/screens/games/tiki_golf/tiki_golf_game_test.dart`
- Per-game randomization: holeTargets (9 distinct from 1-20) and holeImagePaths shuffle correctness
- Variable darts per turn: Max Darts 3/4/5/6 all behave correctly
- Turn-end detection: target hit ends turn immediately; all-darts-missed → Splash; Skip Turn → Splash
- Splash threshold: maxDarts + 1 for each Max Darts setting
- Mulligan mechanics: per-player, single-use, replace Splash score, re-throw full Max Darts
- Team best-ball aggregation: MIN of team player scores per hole
- Team grouped rotation: each team plays through before next team
- Win conditions: Solo (lowest total) and Team (lowest team total) with tiebreakers
- Save/restore: holeTargets and holeImagePaths preserved across serialization

**Tiki Golf Announcements (36 tests)** - `test/screens/games/tiki_golf/tiki_golf_announcement_test.dart`
- All 14 announcement events with correct text and sound effects
- 11-rank precedence chain verification
- MAX 2 announcements per dart enforcement
- Mulligan reminder vs plain Splash announcement selection (conditionally suppresses)
- announceRemoveDarts fires unconditionally and does not count against budget
- Team mode player turn includes team name prefix ("Sharks: Alice up to putt!")

**Tiki Golf Game With Announcements (18 tests)** - `test/screens/games/tiki_golf/tiki_golf_game_with_announcements_test.dart`
- Full dart processing triggering correct announcement sequences
- Birdie/Par/Bogey/Splash fire hitConfirm correctly combined with statusChange events
- Mulligan reminder fires with Splash when mulligan is available
- Victory fires on hole 9 completion, precedes all other simultaneous announcements
- Remove Darts fires unconditionally alongside other announcements

**Treasure Divide Game Logic (89 tests)** - `test/screens/games/treasure_divide/treasure_divide_game_test.dart`
- Solo scoring: hit/miss per target type (number, Any Double, Any Triple, Bull), value accumulation
- Halving logic with edge cases (floor, 0-score, accumulation across rounds)
- Quarter It variant: floor(score/4) replaces halving when option ON
- Round progression: 7/9/12-round sequences, custom targets, sentinel constants
- Team SUM aggregation + crew-wide halving; solo crew 6-dart fairness rule
- randomDistribution(N) for all N in 3..10; doubles invariant
- Pirate theme assignment (shuffle, distinct indices for ≤8 players, persistence across serialization)
- Win condition: last round completion; Solo tiebreaker (most darts hit > fewer rounds played); Team tiebreaker

**Treasure Divide Announcements (60 tests)** - `test/screens/games/treasure_divide/treasure_divide_announcement_test.dart`
- All 22 announcement events with correct text and sound effects
- Per-dart precedence chain: Bull Hit > Big Hit > Hit Target > Miss
- Solo turn-end precedence: Quartered > Halved > Safe
- Team crew precedence: Crew Wipeout > Crew Plunder
- Round-transition precedence: Last Round > Bull Round > Triple Round > Double Round > Custom Reveal > Standard New Round
- Victory fires only from `_handleGameWon()` and takes precedence over all others
- MAX 2 announcements per event; Remove Darts fires unconditionally outside budget

**Treasure Divide Game With Announcements (89 tests)** - `test/screens/games/treasure_divide/treasure_divide_game_with_announcements_test.dart`
- Full dart processing triggering correct announcement sequences end-to-end
- Halved/Safe/Quartered combined with per-dart-level announcements
- Crew wipeout and crew plunder mutual exclusion in combined flow
- Victory fires on final round completion, precedes all other simultaneous announcements
- Remove Darts fires unconditionally alongside other announcements

### Utility Tests (34 tests)

**DartboardLayout (34 tests)** - `test/utils/dartboard_layout_test.dart`
- clockwiseOrder validation
- getNeighbors for all segments
- isNeighbor relationship testing
- findNeighborTarget and findAllNeighborTargets

### Shared Component Tests (24 tests)

**SectorParser (14 tests)** - `test/shared/sector_parser_test.dart`
- Dart notation parsing
- Score calculation
- Game-specific formats

**PlayerTestUtils (10 tests)** - `test/shared/player_test_utils_test.dart`
- Test player creation helpers

### Widget Tests (61 tests)

**InteractiveDartboard (23 tests)** - `test/widgets/interactive_dartboard_test.dart`
- Dartboard rendering
- Bulls detection
- Ring detection
- Segment scoring accuracy
- Dart position persistence

**SaveGameModal (8 tests)** - `test/widgets/save_game_modal_test.dart`
- Modal rendering and actions

**ResumeGameModal (13 tests)** - `test/widgets/resume_game_modal_test.dart`
- Saved game listing and selection
- Game-specific theming

**PirateAvatarWidget (17 tests)** - `test/widgets/treasure_divide/pirate_avatar_widget_test.dart`
- Widget renders all 8 pirate themes without overflow
- PirateAvatarWidget uses face landmarks when present (landmark-derived anchor points)
- PirateAvatarWidget falls back to heuristic anchors when face_landmarks is null
- Each accessory sprite renders at correct anchor and width factor per theme
- Heuristic fallback values produce visually acceptable layout for all 8 themes
- Widget does not throw when avatar image is null or missing
- Theme 0 (Captain) renders hat + eyepatch + parrot at correct positions
- Theme 3 (Navigator) monocle anchors to rightEye landmark
- Solo Crew badge renders correctly in ActivePlayerPanel when crew has 1 member

### Save/Resume Integration Tests (20 tests)

**Save/Resume Integration (20 tests)** - `test/integration/save_resume_integration_test.dart`
- Save trigger conditions: 8 tests
- Full save-resume-complete cycles: 4 tests
- Resumed game save overwrites: 5 tests
- Multiple saves independence: 3 tests

### Server Tests (225 tests)

**Database & Helpers (25 tests)** - `server/test/database_test.dart`
- Table creation and schema validation
- CRUD operations for all 7 tables
- Helper functions (rowToMap, resultSetToList, rowExists, insertRow, executeUpdate)
- WAL mode and foreign key enforcement

**Database Registry & Session Middleware (10 tests)** - `server/test/database_registry_test.dart`
- DatabaseRegistry: default DB handle, current getter (default vs session), session isolation, session identity, closeAll cleanup, session file creation
- dbSessionMiddleware: no header uses default DB, X-DB-Session header routes to session DB, empty header uses default DB

**Model Roundtrips (32 tests)** - `server/test/models_test.dart`
- ServerPlayer, ServerGameHistoryEntry, ServerDartboard, ServerDartboardProfile
- ServerSavedGame, ServerVictoryMusic
- fromDbRow, fromJson, toJson for all models

**Migration Runner, V1 Baseline & V2 Failed Stats (29 tests)** - `server/test/migration_test.dart`
- MigrationRunner: schema_version table creation, version tracking, idempotent re-runs
- Migration execution: runs all on fresh DB, skips applied, runs pending only, order verification
- Transaction safety: rollback on failure, partial schema rollback, exception rethrow
- Edge cases: empty migrations list, currentVersion reflects highest version
- MigrationV1Baseline: creates all 7 application tables, default dartboard row, column defaults, FK cascades
- MigrationV2FailedStats: creates failed_stats table, full row insert, nullable optional fields

**Settings Routes (9 tests)** - `server/test/routes/settings_routes_test.dart`
- GET/PUT/DELETE individual settings
- Bulk PUT settings
- 404 for missing keys

**Dartboard Routes (10 tests)** - `server/test/routes/dartboard_routes_test.dart`
- Singleton dartboard config CRUD
- Connection profiles CRUD
- Profile upsert behavior

**Player Routes (24 tests)** - `server/test/routes/player_routes_test.dart`
- Full player CRUD with game history
- Photo upload/download (base64)
- Stats updates and game history recording
- Cascade delete (player → game_history)

**Saved Game Routes (13 tests)** - `server/test/routes/saved_game_routes_test.dart`
- Save/load/delete by ID and game type
- Upsert behavior (same ID overwrites)
- JSON state serialization

**Victory Music Routes (14 tests)** - `server/test/routes/victory_music_routes_test.dart`
- Upload/download music (base64 roundtrip)
- Set/clear current music
- Delete individual and all music

**Failed Stats Routes (6 tests)** - `server/test/routes/failed_stats_routes_test.dart`
- GET returns empty list initially
- POST creates entry with full and minimal fields
- Entries appear in GET after creation
- DELETE all clears entries (204)
- DELETE by ID removes single entry, 404 for unknown ID

**Test Routes (6 tests)** - `server/test/routes/test_routes_test.dart`
- Atomic reset of all user data (players, games, history, music, failed stats)
- Correct deletion counts returned
- Idempotency (second reset returns zeros)
- Combined reset of all tables simultaneously

**Additional Routes — Pirate's Grid (12 tests)** - `server/test/routes/pirates_grid_routes_test.dart`
- Pirate's Grid-specific server routes (added in Phase 6 for Pirate's Grid)

**Face Landmarks Routes + V5 Migration + Service — Treasure Divide (35 tests)** - `server/test/routes/face_landmarks_routes_test.dart`, `server/test/migration_v5_test.dart`, `server/test/face_landmark_service_test.dart`
- V5 migration (`add_face_landmarks`): adds nullable `face_landmarks TEXT` column to `players` table; idempotent re-run; backward compatible (existing players get null)
- Face landmark model: `FaceLandmarksData` JSON roundtrip (boundingBox, leftEye, rightEye, noseTip, mouthCenter, confidence)
- Face landmarks routes: GET `/players/:id/face-landmarks` (null before detection, data after), PUT (set), DELETE (clear)
- FaceLandmarkService: Python sidecar invocation, JSON parse, null-on-failure path
- Player routes: face_landmarks field preserved in player CRUD after V5 migration

## Running Tests

### All Non-UI Tests
```bash
# Flutter tests (2428 tests)
flutter test

# Server tests (225 tests)
cd server && dart test
```

### Specific Test Files
```bash
flutter test test/models/player_test.dart
flutter test test/providers/player_provider_test.dart
flutter test test/providers/horse_race_provider_game_test.dart
```

### Specific Categories
```bash
flutter test test/models/
flutter test test/providers/
flutter test test/services/
flutter test test/utils/
flutter test test/screens/games/target_tag/
flutter test test/screens/games/monster_mash/
flutter test test/screens/games/reef_royale/
flutter test test/screens/games/clockwork_quest/
flutter test test/screens/games/lunar_lander/
flutter test test/screens/games/pirates_grid/
flutter test test/screens/games/gladiator_arena/
flutter test test/screens/games/tiki_golf/
flutter test test/providers/tiki_golf_provider_game_test.dart
flutter test test/providers/tiki_golf_save_restore_test.dart
flutter test test/models/tiki_golf_serialization_test.dart
flutter test test/screens/games/treasure_divide/
flutter test test/providers/treasure_divide_provider_game_test.dart
flutter test test/providers/treasure_divide_save_restore_test.dart
flutter test test/models/treasure_divide_game_serialization_test.dart
flutter test test/widgets/treasure_divide/
```

## Test Patterns

### Model Tests
- Serialization/deserialization
- Equality and hashCode
- copyWith() methods
- Backward compatibility

### Provider Tests
- State management
- Data persistence
- Business logic
- Event handling

### Integration Tests
- Game logic validation
- Announcement verification
- User stat tracking
- Cross-feature integration

## Related Documentation

- [Test Overview](test-overview.md)
- [Test Maintenance](test-maintenance.md)
- [Build Process](../deployment/build-process.md)
