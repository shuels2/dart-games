# Test Overview

## Complete Test Suite

The Dart Games app has a comprehensive test suite with 465 total tests:
- **337 non-UI tests** (models, providers, services, widgets, game logic)
- **128 UI automation tests** (end-to-end testing with Chrome)

## Non-UI Tests (337 tests)

**Run with:** `flutter test`
**Execution time:** Seconds
**MANDATORY:** Must pass 100% before every build

### Breakdown by Category

**Model Tests (40 tests)**
- GameHistoryEntry: 12 tests
- Player: 16 tests
- VictoryMusicFile: 12 tests

**Provider Tests (44 tests)**
- PlayerProvider: 44 tests (CRUD, selection, stats, history, sorting)

**Service Tests (42 tests)**
- AppSettings: 20 tests
- VictoryMusicService: 22 tests

**Integration Tests (148 tests)**
- Carnival Derby User Management: 26 tests
- Carnival Derby Game Logic + Announcements: 11 tests
- Target Tag Game Logic + Announcements: 32 tests
- Target Tag User Management: 14 tests
- Monster Mash Game Logic + Announcements: 47 tests
- Monster Mash Announcements: 18 tests

**Shared Component Tests (24 tests)**
- SectorParser: 14 tests
- PlayerTestUtils: 10 tests

**Widget Tests (23 tests)**
- InteractiveDartboard: 23 tests

## UI Automation Tests (128 tests)

**Run with:** `./run_ui_tests.bat` or `flutter drive`
**Execution time:** ~86 minutes
**OPTIONAL:** Ask user before running

### Target Tag (53 tests, ~40 minutes)
- Menu and Mechanics: 24 tests (~12 min)
- Visual Validation: 4 tests (~2 min)
- Gameplay: 13 tests (~10 min)
- Add Player: 6 tests (~3 min)
- Results Screen: 6 tests (~5.5 min)

### Carnival Derby (24 tests, ~14 minutes)
- Complete UI test suite

### Monster Mash (51 tests, ~32 minutes)
- Menu: ~5 min
- Gameplay: ~7 min
- Buffs: ~5 min
- Edit Score: ~4 min
- Add Player: ~4 min
- Results: ~7 min

## Test Requirements

### Before Every Build
✅ Run `flutter test` (337 tests)
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
- Execute in ~86 minutes
- Test end-to-end user flows
- Validate visual elements
- Test player interactions
- Verify settings persistence

## Related Documentation

- [Non-UI Tests](non-ui-tests.md)
- [UI Automation](ui-automation.md)
- [Test Maintenance](test-maintenance.md)
- [Build Process](../deployment/build-process.md)
