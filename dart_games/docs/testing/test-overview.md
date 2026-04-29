# Test Overview

## Complete Test Suite

The Dart Games app has a comprehensive test suite with 1723 total tests:
- **1179 Flutter non-UI tests** (models, providers, services, widgets, game logic)
- **178 server tests** (database, models, routes, migrations)
- **366 UI automation tests** (end-to-end testing with Chrome)

## Non-UI Tests (1179 Flutter + 178 Server = 1357 tests)

### Flutter Tests (1179 tests)
**Run with:** `flutter test`
**Execution time:** Seconds
**MANDATORY:** Must pass 100% before every build

### Breakdown by Category

**Model Tests (98 tests)**
- GameHistoryEntry: 12 tests
- Player: 16 tests
- VictoryMusicFile: 12 tests
- Additional models (Dartboard, DartboardConnectionProfile, ApiLogEntry, SavedGameMetadata): 58 tests

**Model Serialization Tests (74 tests)**
- HorseRaceGame serialization: 10 tests
- TargetTagGame serialization: 13 tests
- MonsterMashGame serialization: 13 tests
- ReefRoyaleGame serialization: 19 tests
- ClockworkQuestGame serialization: 19 tests

**Provider Tests (74 tests)**
- PlayerProvider: 44 tests (CRUD, selection, stats, history, sorting)
- DartboardProvider: 30 tests (emulator mode, profiles, loadConfiguration, status checking)

**Provider Save/Restore Tests (35 tests)**
- HorseRaceProvider save/restore: 7 tests
- TargetTagProvider save/restore: 7 tests
- MonsterMashProvider save/restore: 7 tests
- ReefRoyaleProvider save/restore: 7 tests
- ClockworkQuestProvider save/restore: 7 tests

**Provider Game Mechanics Tests (233 tests)**
- HorseRaceProvider: 50 tests (startGame, processDartThrow, exact score/bust, skipTurn, editScore, getHorsePosition)
- ClockworkQuestProvider: 49 tests (normal + speed mode, target advancement, laps, bullseye, editScore, win conditions)
- MonsterMashProvider: 44 tests (health/damage/healing, elimination, processDartThrow, editScore, speed play)
- ReefRoyaleProvider: 45 tests (marks/claiming/locking, processDartThrow, editScore, pearl scoring)
- TargetTagProvider: 45 tests (solo/team modes, shield mechanics, tag-in/out, elimination, hero bonus)

**API Client Tests (49 tests)**
- ApiConfig: 5 tests
- ApiClient: 38 tests
- Voice settings (announcer style, system voice, responsive voice): 6 tests

**Service Tests (91 tests)**
- AppSettings: 20 tests
- VictoryMusicService: 22 tests
- StorageService: 24 tests
- ApiLoggerService: 25 tests

**Save Game Service Tests (13 tests)**
- SaveGameService CRUD: 13 tests

**Announcement Queue Model Tests (30 tests)**
- AudioPriority: 8 tests
- SoundEffectConfig: 7 tests
- QueuedAnnouncement: 7 tests
- Priority ordering logic: 8 tests

**Integration Tests (163 tests)**
- Carnival Derby User Management: 26 tests
- Carnival Derby Game Logic + Announcements: 17 tests
- Target Tag Game Logic + Announcements: 54 tests (includes precedence coverage)
- Target Tag User Management: 14 tests
- Monster Mash Game Logic + Announcements: 47 tests
- Monster Mash Announcements: 18 tests
- Reef Royale Game Logic + Announcements: ~154 tests
- Clockwork Quest Game Logic + Announcements: 84 tests (66 game logic + 18 announcements)

**Save/Resume Integration Tests (20 tests)**
- Save trigger conditions: 8 tests
- Full save-resume-complete cycles: 4 tests
- Resumed game save overwrites: 5 tests
- Multiple saves independence: 3 tests

**Utility Tests (34 tests)**
- DartboardLayout: 34 tests (clockwiseOrder, getNeighbors, isNeighbor, findNeighborTarget)

_Note: Some tests span multiple categories. The total (1179) is the authoritative count from `flutter test`._

**Shared Component Tests (24 tests)**
- SectorParser: 14 tests
- PlayerTestUtils: 10 tests

**Widget Tests (44 tests)**
- InteractiveDartboard: 23 tests
- SaveGameModal: 8 tests
- ResumeGameModal: 13 tests

### Server Tests (178 tests)
**Run with:** `cd server && dart test`
**Execution time:** Seconds
**MANDATORY:** Must pass 100% before every build

- Database & helpers: 25 tests
- Database registry & session middleware: 10 tests
- Model roundtrips: 32 tests
- Migration runner, V1 baseline & V2 failed_stats: 29 tests
- Settings routes: 9 tests
- Dartboard routes: 10 tests
- Player routes: 24 tests
- Saved game routes: 13 tests
- Victory music routes: 14 tests
- Failed stats routes: 6 tests
- Test routes: 6 tests

## UI Automation Tests (366 tests)

**Run with:** `./run_ui_tests.bat` (sequential) or `./run_ui_tests_parallel.bat` (parallel)
**Execution time:** ~588 minutes sequential, ~170 minutes parallel
**OPTIONAL:** Ask user before running

### Target Tag (69 tests, ~116 minutes)
- Menu and Mechanics: 24 tests
- Gameplay: 13 tests
- Add Player: 6 tests
- Results Screen: 6 tests
- Visual Validation: 4 tests
- Save & Resume: 16 tests

### Carnival Derby (40 tests, ~66 minutes)
- Complete UI test suite: 24 tests
- Save & Resume: 16 tests

### Monster Mash (67 tests, ~107 minutes)
- Add Player: 6 tests
- Menu and Settings: 8 tests
- Gameplay: 20 tests
- Edit Score: 5 tests
- Results Screen: 6 tests
- Visual Validation: 6 tests
- Save & Resume: 16 tests

### Reef Royale (83 tests, ~132 minutes)
- Add Player: 6 tests
- Menu and Settings: 10 tests
- Gameplay: 30 tests
- Edit Score: 6 tests
- Results Screen: 6 tests
- Visual Validation: 7 tests
- Showcase: 1 test
- Screenshot: 1 test
- Save & Resume: 16 tests

### Clockwork Quest (107 tests, ~168 minutes)
- Add Player: 10 tests
- Menu and Settings: 20 tests
- Gameplay: 38 tests
- Edit Score: 11 tests
- Results Screen: 11 tests
- Save & Resume: 16 tests
- Screenshot: 1 test

## Test Requirements

### Before Every Build
✅ Run `flutter test` (1179 tests)
✅ Run `cd server && dart test` (178 tests)
✅ 100% pass rate MANDATORY for both
✅ If ANY test fails, DO NOT proceed
✅ Fix failing tests, re-run, verify all pass

### UI Automation Tests
❓ Ask user: "Would you like me to run UI automation tests?"
✅ If yes: Run `./run_ui_tests.bat` (366 tests, ~588 minutes)
✅ If no: Proceed with build after non-UI tests pass

## Running Tests

### All Non-UI Tests
```bash
# Flutter tests (1179 tests)
flutter test

# Server tests (178 tests)
cd server && dart test
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
flutter test test/shared/
flutter test test/widgets/
```

### UI Automation Tests
```bash
# Sequential runner (all infrastructure managed automatically)
./run_ui_tests.bat                    # All tests (~620 min)
./run_ui_tests.bat target_tag         # Specific game

# Parallel runner (~3.5x faster, 5 games simultaneously)
./run_ui_tests_parallel.bat           # All tests (~174 min)
./run_ui_tests_parallel.bat target_tag monster_mash  # Specific games
```

## Test Expectations

### Non-UI Tests
- 100% pass rate required
- Execute in seconds
- Cover all critical functionality
- Validate data persistence
- Test cross-platform scenarios
- Ensure backward compatibility

### UI Automation Tests
- 100% pass rate when run
- Execute in ~588 minutes (~9h 48m)
- Test end-to-end user flows
- Validate visual elements
- Test player interactions
- Verify settings persistence

## Related Documentation

- [Non-UI Tests](non-ui-tests.md)
- [UI Automation](ui-automation.md)
- [Test Maintenance](test-maintenance.md)
- [Build Process](../deployment/build-process.md)
