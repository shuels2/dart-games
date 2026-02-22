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

## Test Driver Setup

**File:** `test_driver/integration_test.dart`

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

This file should already exist. Do not modify.

## Critical Rule: Continuous Animations

**NEVER use `pumpAndSettle()` on screens with continuous animations.**

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

## Common Issues

### ChromeDriver Not Running
**Error:** "Unable to start a WebDriver session"
**Solution:** Start chromedriver on port 4444

### Test Hangs
**Cause:** Using `pumpAndSettle()` on screen with continuous animations
**Solution:** Use explicit `pump()` sequences

### Widget Not Found
**Cause:** Not pumping enough frames after async operations
**Solution:** Add more `pump()` calls after async waits

## Related Documentation

- [Test Overview](test-overview.md)
- [Continuous Animations](continuous-animations.md)
- [Build Process](../deployment/build-process.md)
