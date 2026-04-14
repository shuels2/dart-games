# Non-UI Tests

## Overview

923 non-UI tests (796 Flutter + 127 server) validate models, providers, services, widgets, game logic, API client, and server routes.

**Run with:** `flutter test` and `cd server && dart test`
**Execution time:** Seconds
**MANDATORY:** 100% pass rate required before every build

## Test Categories

### Model Tests (40 tests)

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

### Provider Tests (44 tests)

**PlayerProvider (44 tests)** - `test/providers/player_provider_test.dart`
- Player CRUD operations
- Player selection (up to max players)
- Game stats tracking
- Game history methods
- Total play time calculations
- Alphabetical sorting

### API Client Tests (49 tests)

**ApiConfig (5 tests)** - `test/services/api/api_config_test.dart`
- URL configuration and construction
- Default and custom base URLs

**ApiClient (38 tests)** - `test/services/api/api_client_test.dart`
- All endpoint methods (settings, dartboard, players, games, music)
- Error handling and status codes
- Request/response serialization

### Service Tests (61 tests)

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

**MigrationRunner (15 tests)** - `test/services/migration_runner_test.dart`
- Fresh install detection and version stamping
- Pre-migration data upgrade path
- Partial upgrade (only pending migrations)
- Failure handling and retry behavior
- Version written per migration

**MigrationV1 (4 tests)** - `test/services/migration_v1_test.dart`
- Version and description validation
- No-op verification (existing data untouched)
- Empty prefs handling

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

### Shared Component Tests (24 tests)

**SectorParser (14 tests)** - `test/shared/sector_parser_test.dart`
- Dart notation parsing
- Score calculation
- Game-specific formats

**PlayerTestUtils (10 tests)** - `test/shared/player_test_utils.dart`
- Test player creation helpers

### Widget Tests (23 tests)

**InteractiveDartboard (23 tests)** - `test/widgets/interactive_dartboard_test.dart`
- Dartboard rendering
- Bulls detection
- Ring detection
- Segment scoring accuracy
- Dart position persistence

### Server Tests (127 tests)

**Database & Helpers (25 tests)** - `server/test/database_test.dart`
- Table creation and schema validation
- CRUD operations for all 7 tables
- Helper functions (rowToMap, resultSetToList, rowExists, insertRow, executeUpdate)
- WAL mode and foreign key enforcement

**Model Roundtrips (32 tests)** - `server/test/models_test.dart`
- ServerPlayer, ServerGameHistoryEntry, ServerDartboard, ServerDartboardProfile
- ServerSavedGame, ServerVictoryMusic
- fromDbRow, fromJson, toJson for all models

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

## Running Tests

### All Non-UI Tests
```bash
# Flutter tests
flutter test

# Server tests
cd server && dart test
```

### Specific Test Files
```bash
flutter test test/models/player_test.dart
flutter test test/providers/player_provider_test.dart
```

### Specific Categories
```bash
flutter test test/models/
flutter test test/screens/games/target_tag/
flutter test test/screens/games/monster_mash/
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
