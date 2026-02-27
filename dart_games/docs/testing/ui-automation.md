# UI Automation Testing

## Overview

128 UI automation tests validate end-to-end user flows in Chrome browser.

**Run with:** `flutter drive` with chromedriver
**Execution time:** ~86 minutes
**OPTIONAL:** Ask user before running

## Test Suite

### Target Tag (53 tests, ~40 minutes)
1. Menu and Mechanics: 24 tests (~12 min)
2. Visual Validation: 4 tests (~2 min)
3. Gameplay: 13 tests (~10 min)
4. Add Player: 6 tests (~3 min)
5. Results Screen: 6 tests (~5.5 min)

### Carnival Derby (24 tests, ~14 minutes)
- Complete UI test coverage

### Monster Mash (51 tests, ~32 minutes)
1. Menu: ~5 min (player selection, settings, start button logic)
2. Gameplay: ~7 min (dart throws, health bars, monster images, skip turn)
3. Buffs: ~5 min (buff activation, shield indicators, buff effects)
4. Edit Score: ~4 min (dialog behavior, recalculation, border colors)
5. Add Player: ~4 min (stone button styling, name validation, cancel)
6. Results: ~7 min (winner display, victory music, play again, settings preservation)

## Running UI Automation Tests

### Step 1: Start ChromeDriver

**CRITICAL:** ChromeDriver must be running BEFORE tests.

```bash
cd chromedriver/chromedriver-win64
./chromedriver.exe --port=4444
```

Leave this terminal running.

### Step 2: Run Tests

```bash
# All tests
./run_ui_tests.bat

# Specific game
./run_ui_tests.bat target_tag
./run_ui_tests.bat carnival
./run_ui_tests.bat monster_mash

# Specific test file
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_menu_and_mechanics_test.dart \
  -d chrome
```

### Step 3: Stop ChromeDriver

```bash
taskkill /F /IM chromedriver.exe
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

## Related Documentation

- [Test Overview](test-overview.md)
- [Continuous Animations](continuous-animations.md)
- [Build Process](../deployment/build-process.md)
