# Target Tag Menu Test Debug Session Progress

## Date: 2026-02-18

## Problem Summary
Target Tag menu and mechanics integration tests (23 tests) are failing. Trying to isolate and debug Test 1.

## Key Files
- **Working test:** `integration_test/target_tag_gameplay_test.dart` (13 tests - ALL PASSING)
- **Failing test:** `integration_test/target_tag_menu_and_mechanics_test.dart` (23 tests - ALL FAILING)
- **Isolated test:** `integration_test/temp_test_1_isolated.dart` (created for debugging)

## What We've Tried

### 1. Initial Investigation
- **Problem:** Original menu test file shows blank white page, no widgets found
- **Observation:** Gameplay tests work perfectly and show splash screen → home screen → menu

### 2. Created Isolated Test File
- Copied Test 1 from menu test into isolated file with same structure as gameplay test
- **Result:** Still failed with blank white page initially

### 3. Copied Test 1 from Gameplay File
- Replaced Test 1 content with EXACT test from working gameplay file
- **Result:** Still failed initially with blank white page

### 4. Flutter Cache Clean (BREAKTHROUGH!)
- Ran `flutter clean` to clear build cache
- **Result:** Massive improvement! Test now finds home screen and game card

### 5. Current Status After Cache Clean
```
✓ App launches successfully
✓ Splash screen appears
✓ Home screen renders
✓ Game card found and tapped
✗ Chrome CRASHES during navigation to Target Tag menu
```

**Debug output shows:**
```
UITestHelpers.navigateToGameMenu: Home screen found: 1
UITestHelpers.navigateToGameMenu: Found 1 game cards
UITestHelpers.navigateToGameMenu: Game card found, tapping...
[CRASH - never prints "COMPLETE"]
```

**Crash location:** Line 76 in `ui_test_helpers.dart` during `PumpSequences.navigation(tester)` after tapping game card.

**User observation:** Chrome stays on home screen showing game selection menu, never transitions to Target Tag menu screen before crash.

## Code Changes Made

### 1. Fixed Compilation Error in Gameplay Test
**File:** `integration_test/target_tag_gameplay_test.dart`
**Lines:** 147, 149
**Change:** Added null assertion operator (`!`) to fix null-safety errors in `verifyDartIndicatorColor()` function
```dart
// Before:
expect(decoration.border, isNotNull);
final border = decoration.border as Border;

// After:
expect(decoration!.border, isNotNull);
final border = decoration!.border as Border;
```

### 2. Created Isolated Test File
**File:** `integration_test/temp_test_1_isolated.dart`
**Purpose:** Isolate Test 1 for debugging
**Content:**
- All imports from gameplay test
- All helper functions (getMockApi, throwDartViaMock, enableHeroBonus, navigateBackToMenu, getHeroBuffFromActivePanel, etc.)
- Test 1 from gameplay test (Hero Bonus Toggle and Display)
- Identical structure to working gameplay test

### 3. Deleted Temp Files
**Removed:**
- `integration_test/temp_test_1_only.dart`
- `integration_test/temp_minimal_test.dart`

**Kept:**
- `integration_test/temp_test_1_isolated.dart` (for continued debugging)

## Key Findings

### Why Gameplay Test Works vs Isolated Test Fails
**Unknown.** Both files now have IDENTICAL:
- Import statements
- Helper functions
- setUp() initialization
- Test structure
- Navigation code

**Cache cleaning made a huge difference** - suggests Flutter was caching corrupted build artifacts specific to the isolated test filename.

### Current Mystery
**The crash happens in `PumpSequences.navigation()` after tapping the game card.**

The same `PumpSequences.navigation()` code works perfectly in the gameplay test but crashes in the isolated test ONLY when navigating from Home → Target Tag menu.

**Pump sequence that crashes (line 76 of ui_test_helpers.dart):**
```dart
await PumpSequences.navigation(tester);
```

**PumpSequences.navigation() implementation:**
```dart
static Future<void> navigation(WidgetTester tester) async {
  await tester.pump(); // Process the tap
  await tester.pump(const Duration(seconds: 1)); // Let navigation complete
  await tester.pump(); // Process navigation
  await tester.pump(); // Build widget tree
  // Wait for async data loading (e.g., PlayerProvider.loadPlayers())
  await tester.pump(const Duration(seconds: 5)); // Wait for async operation
  await tester.pump(); // Process data loaded
  await tester.pump(); // Rebuild widget tree with data
  await tester.pump(); // Layout widgets
  await tester.pump(); // Paint widgets
}
```

The crash likely happens during one of these pump() calls while trying to render the Target Tag menu screen.

## Next Steps for Debugging

1. **After system reboot, try:**
   - Run isolated test again to see if crash is consistent
   - Add try-catch around `PumpSequences.navigation()` to catch crash details
   - Add debug output between each `pump()` call in navigation sequence to see exactly which pump crashes
   - Check Chrome DevTools console for errors before crash
   - Try reducing pump sequence to see if specific pump causes crash

2. **Alternative approaches:**
   - Copy entire gameplay test file and replace Test 1 with menu Test 1
   - Try renaming isolated test to match gameplay test naming pattern exactly
   - Check if there's a SharedPreferences state issue between tests
   - Compare Target Tag menu screen code vs gameplay screen code for differences

## Test Infrastructure

**Working:**
- ChromeDriver on port 4444 ✓
- Flutter drive command ✓
- Splash screen rendering ✓
- Home screen rendering ✓
- Game card interaction ✓

**Failing:**
- Navigation to Target Tag menu screen (crashes Chrome)

## Commands to Run Tests

```bash
# Clean Flutter cache (if needed)
cd C:\Users\shuels\Claude-code Projects\dart_games\dart_games
flutter clean

# Terminal 1: Start ChromeDriver
cd C:\Users\shuels\Claude-code Projects\dart_games\dart_games\chromedriver\chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run isolated test
cd C:\Users\shuels\Claude-code Projects\dart_games\dart_games
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/temp_test_1_isolated.dart \
  -d chrome

# Run working gameplay test (for comparison)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_gameplay_test.dart \
  -d chrome
```

## Environment
- Platform: Windows 11 Enterprise
- Flutter: Latest version
- Chrome: Latest version with ChromeDriver
- Shell: bash (Unix syntax)
