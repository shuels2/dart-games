# Test Overview

## Complete Test Suite

The Dart Games app has a comprehensive test suite with 3285 total tests:
- **2428 Flutter non-UI tests** (models, providers, services, widgets, game logic)
- **225 server tests** (database, models, routes, migrations)
- **820 UI automation tests** (end-to-end testing with Chrome) — optional (+ 98 Treasure Divide UI)

## Non-UI Tests (2428 Flutter + 225 Server = 2653 tests)

### Flutter Tests (2428 tests)
**Run with:** `flutter test`
**Execution time:** Seconds
**MANDATORY:** Must pass 100% before every build

### Breakdown by Category

**Model Tests (98 tests)**
- GameHistoryEntry: 12 tests
- Player: 16 tests
- VictoryMusicFile: 12 tests
- Additional models (Dartboard, DartboardConnectionProfile, ApiLogEntry, SavedGameMetadata): 58 tests

**Model Serialization Tests (169 tests)**
- HorseRaceGame serialization: 10 tests
- TargetTagGame serialization: 13 tests
- MonsterMashGame serialization: 13 tests
- ReefRoyaleGame serialization: 19 tests
- ClockworkQuestGame serialization: 19 tests
- LunarLanderGame serialization: 12 tests
- PiratesGridGame serialization: 24 tests
- GladiatorArenaGame serialization: 17 tests
- TikiGolfGame serialization: 15 tests
- TreasureDivideGame serialization: 27 tests

**Provider Tests (74 tests)**
- PlayerProvider: 44 tests (CRUD, selection, stats, history, sorting)
- DartboardProvider: 30 tests (emulator mode, profiles, loadConfiguration, status checking)

**Provider Save/Restore Tests (85 tests)**
- HorseRaceProvider save/restore: 7 tests
- TargetTagProvider save/restore: 7 tests
- MonsterMashProvider save/restore: 7 tests
- ReefRoyaleProvider save/restore: 7 tests
- ClockworkQuestProvider save/restore: 7 tests
- LunarLanderProvider save/restore: 7 tests
- PiratesGridProvider save/restore: 12 tests
- GladiatorArenaProvider save/restore: 15 tests
- TikiGolfProvider save/restore: 13 tests
- TreasureDivideProvider save/restore: 15 tests

**Provider Game Mechanics Tests (436 tests)**
- HorseRaceProvider: 50 tests (startGame, processDartThrow, exact score/bust, skipTurn, editScore, getHorsePosition)
- ClockworkQuestProvider: 49 tests (normal + speed mode, target advancement, laps, bullseye, editScore, win conditions)
- MonsterMashProvider: 44 tests (health/damage/healing, elimination, processDartThrow, editScore, speed play)
- ReefRoyaleProvider: 45 tests (marks/claiming/locking, processDartThrow, editScore, pearl scoring)
- TargetTagProvider: 45 tests (solo/team modes, shield mechanics, tag-in/out, elimination, hero bonus)
- GladiatorArenaProvider: 81 tests (scoring, knockoff, bust detection, double finish, shield round, speed play, edit score, win conditions)
- TikiGolfProvider: 67 tests (startGame, processDartThrow with variable maxDarts, currentTurnEnded flag, mulligan flow, team grouped rotation, best-ball aggregation, random distribution N=3-16, win conditions)
- TreasureDivideProvider: 55 tests (startGame, processDartThrow, halving/quartering, crew-grouped rotation, solo crew 6-dart rule, SUM aggregation, crew-wide halving, randomDistribution N=3-10, pirate theme assignment)

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
- Lunar Lander Game Logic + Announcements: 66 tests (33 game logic + 33 announcements)
- Pirate's Grid Game Logic + Announcements: 132 tests (31 game logic + 14 three-in-a-row checker + 27 announcements + 24 game-with-announcements + 24 serialization + 12 save-restore)
- Gladiator Arena Game Logic + Announcements: 77 tests (26 game logic + 33 announcements + 18 game-with-announcements)
- Tiki Golf Game Logic + Announcements: 126 tests (72 game logic + 36 announcements + 18 game-with-announcements)
- Treasure Divide Game Logic + Announcements: ~238 tests (89 game logic + 60 announcements direct + 89 game-with-announcements)

**Save/Resume Integration Tests (20 tests)**
- Save trigger conditions: 8 tests
- Full save-resume-complete cycles: 4 tests
- Resumed game save overwrites: 5 tests
- Multiple saves independence: 3 tests

**Utility Tests (34 tests)**
- DartboardLayout: 34 tests (clockwiseOrder, getNeighbors, isNeighbor, findNeighborTarget)

_Note: Some tests span multiple categories. The total (2428) is the authoritative count from `flutter test`._

**Shared Component Tests (24 tests)**
- SectorParser: 14 tests
- PlayerTestUtils: 10 tests

**Widget Tests (61 tests)**
- InteractiveDartboard: 23 tests
- SaveGameModal: 8 tests
- ResumeGameModal: 13 tests
- PirateAvatarWidget (Treasure Divide): 17 tests

### Server Tests (225 tests)
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
- Additional routes (Pirate's Grid): 12 tests
- Face landmarks routes + V5 migration + service (Treasure Divide): 35 tests

## UI Automation Tests (820 tests + 98 Treasure Divide)

**Run with:** `./run_ui_tests.bat` (sequential) or `./run_ui_tests_parallel.bat` (parallel)
**Sequential time:** ~988+ minutes — interactive Chrome sessions visible
**Parallel time:** ~356+ minutes — fully headless, no visible Chrome sessions
**OPTIONAL:** Ask user before running

### Target Tag (73 tests, ~107 minutes)
- Menu and Mechanics: 24 tests
- Gameplay: 13 tests
- Add Player: 6 tests
- Results Screen: 6 tests
- Navigation: 4 tests
- Visual Validation: 4 tests
- Save & Resume: 16 tests

### Carnival Derby (44 tests, ~62 minutes)
- Complete UI test suite: 24 tests
- Navigation: 4 tests
- Save & Resume: 16 tests

### Monster Mash (71 tests, ~99 minutes)
- Add Player: 6 tests
- Menu and Settings: 8 tests
- Gameplay: 20 tests
- Edit Score: 5 tests
- Results Screen: 6 tests
- Navigation: 4 tests
- Visual Validation: 6 tests
- Save & Resume: 16 tests

### Reef Royale (87 tests, ~120 minutes)
- Add Player: 6 tests
- Menu and Settings: 10 tests
- Gameplay: 30 tests
- Edit Score: 6 tests
- Results Screen: 6 tests
- Navigation: 4 tests
- Visual Validation: 7 tests
- Showcase: 1 test
- Screenshot: 1 test
- Save & Resume: 16 tests

### Clockwork Quest (110 tests, ~147 minutes)
- Add Player: 10 tests
- Menu and Settings: 20 tests
- Gameplay: 38 tests
- Edit Score: 11 tests
- Results Screen: 11 tests
- Navigation: 3 tests
- Save & Resume: 16 tests
- Screenshot: 1 test

### Lunar Lander (46 tests, ~61 minutes)
- Add Player: 3 tests
- Edit Score: 4 tests
- Gameplay: 10 tests
- Menu and Settings: 5 tests
- Navigation: 4 tests
- Play to Complete: 5 tests
- Results Screen: 8 tests
- Save & Resume: 6 tests
- Visual Validation: 1 test (11 screenshots)

### Pirate's Grid (63 tests, ~82 minutes)
- Add Player: 6 tests
- Edit Score: 5 tests
- Gameplay: 14 tests
- Menu and Settings: 7 tests
- Navigation: 4 tests
- Pause Modal: 3 tests
- Play to Complete: 6 tests
- Results Screen: 7 tests
- Save & Resume: 6 tests
- Visual Validation: 5 tests (1 screenshot + 4 programmatic)

### Gladiator Arena (99 tests, ~131 minutes)
- Add Player: 6 tests
- Edit Score: 7 tests
- Gameplay: 19 tests
- Menu and Settings: 8 tests
- Navigation: 4 tests
- Pause Modal: 20 tests
- Play to Complete: 5 tests
- Results Screen: 7 tests
- Save & Resume: 16 tests
- Visual Validation: 7 tests (1 screenshot + 4 programmatic + 2 additional)

### Tiki Golf (110 files)
- Visual Validation: 1 file (27 screenshot captures)
- Menu and Settings: 11 files
- Add Player: 6 files
- Navigation: 4 files (mandatory pack)
- Gameplay: 13 files
- Pause Modal: 3 files (20 testWidgets)
- Results Screen: 5 files
- Save & Resume: 16 files (1 testWidget each)
- Edit Score: 5 files
- Play to Complete: 5 files
- Randomization: 4 files (Tiki Golf-specific)
- Team Setup: 10 files (Tiki Golf-specific)
- Team Mode Gameplay: 10 files (Tiki Golf-specific)

### Treasure Divide (98 testWidgets across 83 files, ~145 minutes)
- Add Player: 3 files
- Edit Score: 5 files
- Gameplay: 12 files
- Menu and Settings: 11 files
- Navigation: 4 files
- Pause Modal: 3 files (20 testWidgets: 7+8+5)
- Play to Complete: 5 files
- Results Screen: 7 files (5 base + solo_tie + team_tie)
- Save & Resume: 16 files
- Team Setup: 7 files (4 base + solo_to_team + team_to_solo + team_random_no_ui)
- Team Mode Gameplay: 4 files (3 base + team_results_all_winning_players)
- Visual Validation: 6 files (4 programmatic + 2 screenshot files — 22 total captures)

## Test Requirements

### Before Every Build
✅ Run `flutter test` (2428 tests)
✅ Run `cd server && dart test` (225 tests)
✅ 100% pass rate MANDATORY for both
✅ If ANY test fails, DO NOT proceed
✅ Fix failing tests, re-run, verify all pass

### UI Automation Tests
❓ Ask user: "Would you like me to run UI automation tests?"
✅ If yes: Run `./run_ui_tests_parallel.bat` (~211 min) or `./run_ui_tests.bat` (~843 min)
✅ If no: Proceed with build after non-UI tests pass

## Running Tests

### All Non-UI Tests
```bash
# Flutter tests (2428 tests)
flutter test

# Server tests (225 tests)
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
flutter test test/screens/games/lunar_lander/
flutter test test/screens/games/pirates_grid/
flutter test test/screens/games/gladiator_arena/
flutter test test/screens/games/tiki_golf/
flutter test test/shared/
flutter test test/widgets/
```

### UI Automation Tests
```bash
# Sequential runner — interactive Chrome, one game at a time
./run_ui_tests.bat                    # All tests (~843 min)
./run_ui_tests.bat target_tag         # Specific game
./run_ui_tests.bat lunar_lander       # Specific game
./run_ui_tests.bat gladiator_arena    # Specific game
./run_ui_tests.bat tiki_golf          # Specific game

# Parallel runner — fully headless, all games simultaneously (~3.5x faster)
./run_ui_tests_parallel.bat           # All tests (~211+ min)
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
- Sequential: ~622 minutes (~10h 22m) with interactive Chrome; Parallel: ~153 minutes (~2h 33m) headless
- Test end-to-end user flows
- Validate visual elements
- Test player interactions
- Verify settings persistence

## Related Documentation

- [Non-UI Tests](non-ui-tests.md)
- [UI Automation](ui-automation.md)
- [Test Maintenance](test-maintenance.md)
- [Build Process](../deployment/build-process.md)
