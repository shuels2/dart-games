# Continuous Animations in UI Tests

## Critical Rule

**NEVER use `pumpAndSettle()` on screens with infinite/repeating animations.**

This is the #1 cause of UI automation test hangs.

## The Problem

Screens with continuous animations will cause `pumpAndSettle()` to hang forever waiting for animations to complete.

### Identifying Continuous Animations

Look for this pattern in screen code:

```dart
// This creates an infinite animation:
_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);  // ← INFINITE - never settles
```

**Examples:**
- Target Tag menu screen (pulse animation)
- Any screen with repeating/looping animations
- Screens with animated backgrounds

## Wrong Approach

```dart
// ❌ WRONG - Will hang forever
await tester.tap(find.text('Target Tag'));
await tester.pumpAndSettle(); // ← HANGS FOREVER
```

Test will freeze. No error message, just infinite waiting.

## Correct Approach

Use explicit `pump()` sequences:

```dart
// ✅ CORRECT - Use explicit pump() calls
await tester.tap(find.text('Target Tag'));
await tester.pump(); // Process the tap
await tester.pump(const Duration(seconds: 1)); // Let navigation complete
await tester.pump(); // Process navigation
await tester.pump(const Duration(seconds: 5)); // Wait for async loading
await tester.pump(); // Process data loaded
await tester.pump(); // Rebuild widget tree
await tester.pump(); // Layout widgets
await tester.pump(); // Paint widgets
```

## Frame Pumping Patterns

### Navigation to New Screen
```dart
await tester.tap(find.text('Screen Name'));
await tester.pump(); // Process the tap
await tester.pump(const Duration(seconds: 1)); // Let navigation complete
await tester.pump(); // Process navigation
await tester.pump(); // Build widget tree
```

### After Async Operations
```dart
// Wait for async data to load
await tester.pump(const Duration(seconds: 5)); // Wait for async
await tester.pump(); // Process data loaded
await tester.pump(); // Rebuild widget tree
await tester.pump(); // Layout widgets
await tester.pump(); // Paint widgets
```

### Opening a Dialog
```dart
await tester.tap(buttonFinder);
await tester.pump(); // Process tap
await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
await tester.pump(); // Build dialog
await tester.pump(); // Layout dialog
await tester.pump(); // Paint dialog
```

### Entering Text
```dart
await tester.enterText(textFieldFinder, 'Text');
await tester.pump(); // Process text entry
await tester.pump(); // Update text field
```

## When pumpAndSettle() is Safe

**ALMOST NEVER in integration tests.** The splash screen has a `CircularProgressIndicator` which is a continuous indeterminate animation. This means `pumpAndSettle()` will hang even before reaching the home screen.

```dart
// ❌ WRONG - Splash screen has CircularProgressIndicator
app.main();
await tester.pumpAndSettle(); // ← HANGS FOREVER on splash screen

// ✅ CORRECT - Use manual pumps after app launch
app.main();
await tester.pump(); // Process initial frame
await tester.pump(const Duration(seconds: 2)); // Wait for splash delay
await tester.pump(); // Process navigation to home
await tester.pump(const Duration(seconds: 2)); // Wait for home screen
await tester.pump(); // Rebuild
await tester.pump(); // Layout
await tester.pump(); // Paint

// ❌ UNSAFE - After navigating to game screen
await tester.tap(find.text('Target Tag'));
await tester.pumpAndSettle(); // ← WILL HANG if pulse animation
```

**General rule:** NEVER use `pumpAndSettle()` in integration tests. The splash screen's `CircularProgressIndicator` and game screens' pulse animations will both cause hangs. Always use explicit `pump()` sequences.

## Applies ONLY to UI Automation Tests

**IMPORTANT:** This rule ONLY applies to UI automation tests in `integration_test/` directory.

**Does NOT apply to:**
- Unit tests (`test/models/`)
- Provider tests (`test/providers/`)
- Service tests (`test/services/`)
- Widget tests (`test/widgets/`)
- Game logic tests (`test/screens/games/`)

Those tests run with `flutter test` and can use `pumpAndSettle()` normally.

## Related Documentation

- [UI Automation](ui-automation.md)
- [Test Overview](test-overview.md)
