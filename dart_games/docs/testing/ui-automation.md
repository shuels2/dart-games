# UI Automation Testing

## Overview

366 UI automation tests validate end-to-end user flows in Chrome browser.

**Run with:** `flutter drive` with chromedriver
**Sequential time:** ~507 minutes (~8h 27m) — `run_ui_tests.bat`, interactive Chrome sessions visible
**Parallel time:** ~143 minutes (~2h 23m) — `run_ui_tests_parallel.bat`, fully headless (no visible Chrome)
**OPTIONAL:** Ask user before running

## Test Suite

### Target Tag (69 tests, ~101 minutes)
1. Menu and Mechanics: 24 tests
2. Gameplay: 13 tests
3. Add Player: 6 tests
4. Results Screen: 6 tests
5. Visual Validation: 4 tests
6. Save & Resume: 16 tests

### Carnival Derby (40 tests, ~56 minutes)
1. Complete UI test coverage: 24 tests
2. Save & Resume: 16 tests

### Monster Mash (67 tests, ~93 minutes)
1. Add Player: 6 tests
2. Menu and Settings: 8 tests
3. Gameplay: 20 tests
4. Edit Score: 5 tests
5. Results Screen: 6 tests
6. Visual Validation: 6 tests
7. Save & Resume: 16 tests

### Reef Royale (83 tests, ~114 minutes)
1. Add Player: 6 tests
2. Menu and Settings: 10 tests
3. Gameplay: 30 tests
4. Edit Score: 6 tests
5. Results Screen: 6 tests
6. Visual Validation: 7 tests
7. Showcase: 1 test
8. Screenshot: 1 test
9. Save & Resume: 16 tests

### Clockwork Quest (107 tests, ~143 minutes)
1. Add Player: 10 tests
2. Menu and Settings: 20 tests
3. Gameplay: 38 tests
4. Edit Score: 11 tests
5. Results Screen: 11 tests
6. Save & Resume: 16 tests
7. Screenshot: 1 test

## Mandatory Results Screen Coverage

Every game's Results Screen UI tests MUST include these three tests. They catch bugs that unit tests cannot, because unit tests call functions directly without validating whether the results screen actually calls them.

### 1. Exit Button Navigation (`*_back_to_home_test.dart` or similar)
- Complete a game → click the exit/leave button
- Assert **at least three** game card keys are visible (e.g. `getCarnivalDerbyCard()`, `getTargetTagCard()`, `getMonsterMashCard()`)
- A single-card assertion is a false positive: `pushNamedAndRemoveUntil('/')` also satisfies it in the test environment but routes to the dartboard registration page in real use
- Implementation must use `Navigator.popUntil(context, (route) => route.isFirst)`, not `pushNamedAndRemoveUntil('/')`

### 2. Player Stats Updated (`winner_stats_updated_test.dart`)
- Complete a game → land on results screen → pump extra time for async calls
- Read `PlayerProvider` via `ProviderHelpers.findPlayerByName`
- Assert winner: `gamesPlayed == 1`, `gamesWon == 1`, `gameHistory.first.gameName == '<GameName>'`
- Assert each loser: `gamesPlayed == 1`, `gamesWon == 0`
- If `_updatePlayerStats()` is missing from results screen `initState`, stats stay at 0 and this test fails

### 3. Victory Music Triggered (`winner_stats_updated_test.dart` — same file as #2)
- `resetServerState()` resets `VictoryMusicService._initialized` to `false`
- After results screen loads, assert `VictoryMusicService().isInitialized == true`
- Proves `_playVictoryMusic()` called `getRandomMusicSource()` → `initialize()`
- If `_playVictoryMusic()` is missing from results screen `initState`, `isInitialized` stays `false`

See `integration_test/clockwork_quest/results/winner_stats_updated_test.dart` for the reference implementation of tests 2 and 3.

## ChromeDriver Version Sync

ChromeDriver must match the installed Chrome major version. The `update_chromedriver.bat` script handles this automatically:

```bash
# Check and update ChromeDriver if needed
./update_chromedriver.bat

# Force re-download even if versions match
./update_chromedriver.bat --force
```

**This runs automatically** at the start of `run_ui_tests.bat` and `run_ui_tests_stub.bat` — no manual intervention needed. If Chrome updates and the ChromeDriver version no longer matches, the script downloads the correct version before tests begin.

## Running UI Automation Tests

### Step 1: Start Backend Server

**CRITICAL:** The backend server must be running BEFORE tests. All providers read from the API. (When running via `run_ui_tests.bat`, the server is started automatically per game category.)

```bash
cd server
dart run bin/server.dart --data-dir ../ui_test_data
```

Leave this terminal running.

### Step 2: Start ChromeDriver

**CRITICAL:** ChromeDriver must be running BEFORE tests. (When running via `run_ui_tests.bat`, ChromeDriver is started automatically per game category.)

```bash
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444
```

Leave this terminal running.

### Step 3: Run Tests

```bash
# All tests
./run_ui_tests.bat

# Specific game
./run_ui_tests.bat target_tag
./run_ui_tests.bat carnival
./run_ui_tests.bat monster_mash
./run_ui_tests.bat clockwork_quest

# Specific test file
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag/target_tag_menu_and_mechanics_test.dart \
  -d chrome
```

### Step 5: Stop ChromeDriver and Server

```bash
taskkill /F /IM chromedriver.exe
# Stop the server with Ctrl+C in its terminal, or:
taskkill /F /FI "WINDOWTITLE eq dart*server*" 2>nul
```

## Test Drivers

There are TWO test drivers — using the wrong one is a common mistake:

### Standard Driver (for UI automation tests)
**File:** `test_driver/integration_test.dart`

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

Use with: `flutter drive --driver=test_driver/integration_test.dart`

### Screenshot Driver (for screenshot/visual validation tests)
**File:** `test_driver/screenshot_test.dart`

```dart
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart' as driver;

Future<void> main() async {
  final dir = Directory('temp_screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  await driver.integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      final File image = File('temp_screenshots/$screenshotName.png');
      image.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
```

Use with: `flutter drive --driver=test_driver/screenshot_test.dart`

**CRITICAL:** Any test that calls `binding.takeScreenshot()` MUST use the screenshot driver. Using `integration_test.dart` instead will cause the test to hang on the first `takeScreenshot()` call because the standard driver has no `onScreenshot` callback.

### How to Tell Which Driver to Use

| Test calls `takeScreenshot()`? | Driver to use |
|-------------------------------|---------------|
| No | `test_driver/integration_test.dart` |
| Yes | `test_driver/screenshot_test.dart` |

## Running UI Tests in Parallel

The parallel runner executes all 5 game categories simultaneously, reducing wall-clock time from ~507 minutes to ~143 minutes (~3.5x speedup). Each game gets its own ChromeDriver and backend server instance. All Chrome sessions run **fully headless** — no interactive browser windows are launched.

### Quick Start

```bash
# Run all tests in parallel (~143 minutes, fully headless)
./run_ui_tests_parallel.bat

# Run specific game(s)
./run_ui_tests_parallel.bat target_tag
./run_ui_tests_parallel.bat target_tag monster_mash

# Filter by test type across all games
./run_ui_tests_parallel.bat save_resume

# Game + subfolder filter
./run_ui_tests_parallel.bat reef_royale/gameplay
```

### Port Assignments

Ports are auto-assigned by position in the `GAMES` list in `run_ui_tests_parallel.bat` (Server = 9000+N, ChromeDriver = 4443+N):

| Game | Server Port | ChromeDriver Port |
|------|------------|-------------------|
| target_tag | 9001 | 4444 |
| carnival_derby | 9002 | 4445 |
| monster_mash | 9003 | 4446 |
| reef_royale | 9004 | 4447 |
| clockwork_quest | 9005 | 4448 |

### Infrastructure Isolation

- Each game runs in its own worker process with a dedicated ChromeDriver and backend server
- PID-scoped Chrome killing ensures one worker's cleanup doesn't affect others
- Per-session database isolation (`X-DB-Session`) prevents cross-test data pollution
- Workers handle their own retry logic (restart ChromeDriver/server on infrastructure failures)

### Output

Results are saved to `integration_test_output/parallel/`:
- Per-test log files: `<test_name>.log`
- Per-game result summaries: `<game>_results.txt`
- Combined summary: `summary.txt`

### System Requirements

- 16GB+ RAM recommended for all games simultaneously
- Use filters to run fewer games if resources are limited

### When to Use Parallel vs Sequential

| Scenario | Runner |
|----------|--------|
| Full test suite run | `run_ui_tests_parallel.bat` |
| Debugging a single test | `run_ui_tests.bat <test>` |
| CI/CD pipeline | `run_ui_tests_parallel.bat` |
| Investigating flaky test | `run_ui_tests.bat <test>` |

### Stub Testing

Test the parallel orchestration without real infrastructure:

```bash
# All games (simulated)
./run_ui_tests_parallel_stub.bat

# With filters
./run_ui_tests_parallel_stub.bat target_tag

# Simulate failures
set STUB_FAIL=1
./run_ui_tests_parallel_stub.bat
```

### Adding a New Game to Parallel Tests

When adding a new game to Dart Games, include it in the parallel test runner:

1. Add the game name to the `GAMES` variable in `run_ui_tests_parallel.bat` (near the top of the file)
2. Ensure `integration_test/<game_name>/` exists with `*_test.dart` files
3. Update the port assignments table above with the next sequential ports

Ports are auto-assigned by position: Server = 9000+N, ChromeDriver = 4443+N. The help text and cleanup routines are fully dynamic — no other script changes needed.

## Critical Rule: Continuous Animations

**NEVER use `pumpAndSettle()` in integration tests.**

The splash screen has a `CircularProgressIndicator` (continuous animation) that prevents settling. Game screens also have pulse animations. Always use explicit `pump()` sequences instead.

See [Continuous Animations](continuous-animations.md) for details.

## Frame Pumping Patterns

### After Navigation
```dart
await tester.tap(find.text('Screen'));
await tester.pump(); // Process tap
await tester.pump(const Duration(seconds: 1)); // Navigation
await tester.pump(); // Process navigation
await tester.pump(const Duration(seconds: 5)); // Async loading
await tester.pump(); // Process data
```

### After Async Operations
```dart
await tester.pump(const Duration(seconds: 5)); // Wait for async
await tester.pump(); // Process data
await tester.pump(); // Rebuild
await tester.pump(); // Layout
await tester.pump(); // Paint
```

## Widget Finder Best Practices

### Use Widget Keys
```dart
// CORRECT
final button = find.byKey(YourGameKeys.startButton);

// AVOID
final button = find.text('Start Game');
```

### Scrollable Content
```dart
await tester.ensureVisible(find.byKey(someKey));
await tester.pump();
await tester.tap(find.byKey(someKey));
```

## Running Screenshot Tests

Screenshot tests use `binding.takeScreenshot()` to capture game states for visual validation. Follow these steps exactly:

### Step 1: Start ChromeDriver Fresh

```bash
# Kill any existing chromedriver (ONLY chromedriver, never kill all chrome.exe)
taskkill /F /IM chromedriver.exe

# Wait a few seconds, then start fresh
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444
```

**CRITICAL:** Only kill `chromedriver.exe`. NEVER kill all `chrome.exe` processes — this kills the user's browser sessions and can leave Chrome in a crash recovery state that causes `AppConnectionException` on subsequent test runs.

### Step 2: Run With Screenshot Driver

```bash
# CORRECT — uses screenshot driver
flutter drive --driver=test_driver/screenshot_test.dart \
  --target=integration_test/<game>_screenshot_test.dart \
  -d chrome

# WRONG — standard driver has no onScreenshot callback, test will HANG
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/<game>_screenshot_test.dart \
  -d chrome
```

**Do NOT use `--no-headless`** — follow the same pattern as `run_ui_tests.bat`.

### Step 3: Evaluate Screenshots

Screenshots are saved to `temp_screenshots/`. Read each one and evaluate against the spec's visual checklist.

### Troubleshooting Screenshot Tests

| Symptom | Cause | Fix |
|---------|-------|-----|
| Test hangs on `takeScreenshot()` | Wrong driver (`integration_test.dart`) | Use `screenshot_test.dart` driver |
| Test hangs on "App launched, pumping..." | `pumpAndSettle()` after `app.main()` | Use manual `pump()` sequences |
| `AppConnectionException` | Chrome in crash recovery state | Open Chrome manually, dismiss recovery dialog, close Chrome, retry |
| `AppConnectionException` (persistent) | Stale chromedriver | Kill chromedriver, wait 3s, restart, wait 5s, then run test |
| Chrome launches then closes | ChromeDriver/Chrome version mismatch or stale session | Restart chromedriver fresh before each test run |

## Common Issues

### ChromeDriver Not Running
**Error:** "Unable to start a WebDriver session"
**Solution:** Start chromedriver on port 4444

### AppConnectionException
**Error:** `Instance of 'AppConnectionException'` during "Waiting for connection"
**Causes and solutions:**
1. **Chrome crash recovery dialog** — Open Chrome manually, dismiss the "Restore pages?" dialog, close Chrome, then retry the test
2. **Stale chromedriver** — Kill chromedriver, wait 3 seconds, restart it, wait 5 seconds, then run the test
3. **Previous test didn't clean up** — Kill only `chromedriver.exe` (NOT all Chrome processes), restart it

### Test Hangs
**Cause:** Using `pumpAndSettle()` on screen with continuous animations (including splash screen)
**Solution:** Use explicit `pump()` sequences — see [Continuous Animations](continuous-animations.md)

### Widget Not Found
**Cause:** Not pumping enough frames after async operations
**Solution:** Add more `pump()` calls after async waits

### Phantom Behavior (Duplicate Saves, Duplicate Data, Unexplained Test Pollution)

**First thing to check:** Flutter bug [#67090](https://github.com/flutter/flutter/issues/67090) causes `flutter drive -d chrome` to spawn **two browser instances** in headless mode. Both execute the test code and hit the same server. Chrome's `--headless=new` mode makes the two instances indistinguishable at the client level.

**Symptoms:**
- Duplicate game saves appearing in the database
- Player data created twice
- Tests failing due to unexpected extra records
- Flaky assertions on record counts or list lengths
- "Phantom" players or games that no test explicitly created

**Current mitigation:** Per-session database isolation (`X-DB-Session` header). Each browser instance generates a unique session ID in `resetServerState()`, and the server's `DatabaseRegistry` routes each session to its own isolated SQLite database. This prevents the duplicate browser from interfering with test data.

**If phantom behavior returns:**
1. Verify `resetServerState()` is called at the start of every `testWidgets` block
2. Check that `ApiConfig.dbSession` is being set (inspect the `X-DB-Session` header in server logs)
3. Confirm the server's `dbSessionMiddleware` is active and routing to session databases
4. Check server logs for requests without `X-DB-Session` — these hit the default database and could be from the phantom browser instance
5. As a last resort, check if Flutter has changed headless Chrome launch behavior in the current Flutter version

**History:** This bug was the root cause of extensive debugging during the server-side updates branch. Initial investigation incorrectly suspected test cleanup issues, leading to per-test-file server isolation. The actual fix was per-session database isolation, which allowed safely sharing one server per game category.

## Shared Test Helpers

UI automation tests use shared helpers from `integration_test/shared/` to avoid code duplication across games. Each game's `_helpers.dart` files delegate to these shared static methods rather than duplicating function bodies.

Key shared helpers:
- **`DartThrowHelpers`** — All dart simulation (throw, miss, bullseye, remove darts)
- **`GameSetupHelpers`** — Per-game setup with settings configuration
- **`SaveResumeHelpers`** — Save/resume test patterns and `GameSaveConfig` factories
- **`UITestHelpers`** — Navigation and player management
- **`PumpSequences`** — Standardized frame pumping patterns

When adding a new game, extend the shared helpers and create game-specific `_helpers.dart` files using the delegate pattern. See [Shared Helpers Reference](shared-helpers-reference.md) for templates and the full helper list.

## Related Documentation

- [Test Overview](test-overview.md)
- [Continuous Animations](continuous-animations.md)
- [Shared Helpers Reference](shared-helpers-reference.md)
- [Build Process](../deployment/build-process.md)
