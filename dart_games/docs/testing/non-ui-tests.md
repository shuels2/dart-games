# Non-UI Tests

## Overview

1347 non-UI tests (1179 Flutter + 168 server) validate models, providers, services, widgets, game logic, API client, and server routes.

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

### Model Serialization Tests (74 tests)

**HorseRaceGame (10 tests)** - `test/models/horse_race_game_serialization_test.dart`
**TargetTagGame (13 tests)** - `test/models/target_tag_game_serialization_test.dart`
**MonsterMashGame (13 tests)** - `test/models/monster_mash_game_serialization_test.dart`
**ReefRoyaleGame (19 tests)** - `test/models/reef_royale_game_serialization_test.dart`
**ClockworkQuestGame (19 tests)** - `test/models/clockwork_quest_game_serialization_test.dart`
- toJson/fromJson roundtrip for all game fields
- Enum serialization (game states, inventor assignments)
- Per-player progress maps, dart tracking arrays, turn start state
- Speed mode, bullseye mode, all game states

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

### Provider Save/Restore Tests (35 tests)

**HorseRaceProvider (7 tests)** - `test/providers/horse_race_provider_save_restore_test.dart`
**TargetTagProvider (7 tests)** - `test/providers/target_tag_provider_save_restore_test.dart`
**MonsterMashProvider (7 tests)** - `test/providers/monster_mash_provider_save_restore_test.dart`
**ReefRoyaleProvider (7 tests)** - `test/providers/reef_royale_provider_save_restore_test.dart`
**ClockworkQuestProvider (7 tests)** - `test/providers/clockwork_quest_provider_save_restore_test.dart`
- Save game metadata creation
- Full game state restore via SaveGameService
- Gameplay continuation after restore
- resumedSavedGameId lifecycle

### Provider Game Mechanics Tests (233 tests)

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

### Widget Tests (44 tests)

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

### Save/Resume Integration Tests (20 tests)

**Save/Resume Integration (20 tests)** - `test/integration/save_resume_integration_test.dart`
- Save trigger conditions: 8 tests
- Full save-resume-complete cycles: 4 tests
- Resumed game save overwrites: 5 tests
- Multiple saves independence: 3 tests

### Server Tests (168 tests)

**Database & Helpers (25 tests)** - `server/test/database_test.dart`
- Table creation and schema validation
- CRUD operations for all 7 tables
- Helper functions (rowToMap, resultSetToList, rowExists, insertRow, executeUpdate)
- WAL mode and foreign key enforcement

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

## Running Tests

### All Non-UI Tests
```bash
# Flutter tests (1179 tests)
flutter test

# Server tests (168 tests)
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
