# Non-UI Tests

## Overview

637 non-UI tests validate models, providers, services, widgets, and game logic.

**Run with:** `flutter test`
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

### Service Tests (42 tests)

**AppSettings (20 tests)** - `test/services/app_settings_test.dart`
- Google API key storage
- Voice engine preference
- Voice selection
- Settings persistence

**VictoryMusicService (22 tests)** - `test/services/victory_music_service_test.dart`
- Singleton pattern
- Music file management
- Random selection
- Cross-platform file handling

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

## Running Tests

### All Non-UI Tests
```bash
flutter test
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
