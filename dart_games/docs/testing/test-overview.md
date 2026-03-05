# Test Overview

## Complete Test Suite

The Dart Games app has a comprehensive test suite with 878 total tests:
- **643 non-UI tests** (models, providers, services, widgets, game logic)
- **235 UI automation tests** (end-to-end testing with Chrome)

## Non-UI Tests (643 tests)

**Run with:** `flutter test`
**Execution time:** Seconds
**MANDATORY:** Must pass 100% before every build

### Breakdown by Category

**Model Tests (40 tests)**
- GameHistoryEntry: 12 tests
- Player: 16 tests
- VictoryMusicFile: 12 tests

**Model Serialization Tests (55 tests)**
- HorseRaceGame serialization: 10 tests
- TargetTagGame serialization: 13 tests
- MonsterMashGame serialization: 13 tests
- ReefRoyaleGame serialization: 19 tests

**Provider Tests (44 tests)**
- PlayerProvider: 44 tests (CRUD, selection, stats, history, sorting)

**Provider Save/Restore Tests (28 tests)**
- HorseRaceProvider save/restore: 7 tests
- TargetTagProvider save/restore: 7 tests
- MonsterMashProvider save/restore: 7 tests
- ReefRoyaleProvider save/restore: 7 tests

**Service Tests (42 tests)**
- AppSettings: 20 tests
- VictoryMusicService: 22 tests

**Save Game Service Tests (13 tests)**
- SaveGameService CRUD: 13 tests

**Integration Tests (163 tests)**
- Carnival Derby User Management: 26 tests
- Carnival Derby Game Logic + Announcements: 17 tests
- Target Tag Game Logic + Announcements: 54 tests (includes precedence coverage)
- Target Tag User Management: 14 tests
- Monster Mash Game Logic + Announcements: 47 tests
- Monster Mash Announcements: 18 tests
- Reef Royale Game Logic + Announcements: ~154 tests

**Save/Resume Integration Tests (20 tests)**
- Save trigger conditions: 8 tests
- Full save-resume-complete cycles: 4 tests
- Resumed game save overwrites: 5 tests
- Multiple saves independence: 3 tests

_Note: Some tests span multiple categories. The total (643) is the authoritative count from `flutter test`._

**Shared Component Tests (24 tests)**
- SectorParser: 14 tests
- PlayerTestUtils: 10 tests

**Widget Tests (44 tests)**
- InteractiveDartboard: 23 tests
- SaveGameModal: 8 tests
- ResumeGameModal: 13 tests

## UI Automation Tests (235 tests)

**Run with:** `./run_ui_tests.bat` or `flutter drive`
**Execution time:** ~167 minutes
**OPTIONAL:** Ask user before running

### Target Tag (63 tests, ~49 minutes)
- Menu and Mechanics: 24 tests (~12 min)
- Visual Validation: 4 tests (~2 min)
- Gameplay: 13 tests (~10 min)
- Add Player: 6 tests (~3 min)
- Results Screen: 6 tests (~5.5 min)
- Save & Resume: 10 tests (~9 min)

### Carnival Derby (34 tests, ~23 minutes)
- Complete UI test suite: 24 tests (~14 min)
- Save & Resume: 10 tests (~9 min)

### Monster Mash (61 tests, ~41 minutes)
- Menu: ~5 min
- Gameplay: ~7 min
- Buffs: ~5 min
- Edit Score: ~4 min
- Add Player: ~4 min
- Results: ~7 min
- Save & Resume: 10 tests (~9 min)

### Reef Royale (77 tests, ~54 minutes)
- Add Player: 6 tests (~2 min)
- Menu and Settings: 10 tests (~3 min)
- Gameplay: 30 tests (~15 min)
- Edit Score: 6 tests (~4 min)
- Results Screen: 6 tests (~4 min)
- Visual Validation: 7 tests (~3 min)
- Screenshot: 1 test (~10 min)
- Showcase: 1 test (~4 min)
- Save & Resume: 10 tests (~9 min)

## Test Requirements

### Before Every Build
✅ Run `flutter test` (643 tests)
✅ 100% pass rate MANDATORY
✅ If ANY test fails, DO NOT proceed
✅ Fix failing tests, re-run, verify all pass

### UI Automation Tests
❓ Ask user: "Would you like me to run UI automation tests?"
✅ If yes: Run `./run_ui_tests.bat`
✅ If no: Proceed with build after non-UI tests pass

## Running Tests

### All Non-UI Tests
```bash
flutter test
```

### Specific Categories
```bash
flutter test test/models/
flutter test test/providers/
flutter test test/services/
flutter test test/screens/games/target_tag/
flutter test test/screens/games/monster_mash/
flutter test test/screens/games/reef_royale/
flutter test test/shared/
flutter test test/widgets/
```

### UI Automation Tests
```bash
# Terminal 1: Start chromedriver
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run all UI tests
./run_ui_tests.bat

# Or run specific game
./run_ui_tests.bat target_tag
./run_ui_tests.bat carnival
./run_ui_tests.bat monster_mash
./run_ui_tests.bat reef_royale
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
- Execute in ~163 minutes
- Test end-to-end user flows
- Validate visual elements
- Test player interactions
- Verify settings persistence

## Related Documentation

- [Non-UI Tests](non-ui-tests.md)
- [UI Automation](ui-automation.md)
- [Test Maintenance](test-maintenance.md)
- [Build Process](../deployment/build-process.md)
