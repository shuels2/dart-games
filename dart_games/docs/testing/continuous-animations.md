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

**Only on screens with NO continuous animations:**

```dart
// ✅ Safe - On splash/home before navigating
app.main();
await tester.pumpAndSettle();
await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for splash

// ❌ UNSAFE - After navigating to game screen
await tester.tap(find.text('Target Tag'));
await tester.pumpAndSettle(); // ← WILL HANG if pulse animation
```

**General rule:** Once you navigate to any game screen, assume it might have continuous animations and **stop using `pumpAndSettle()`**.

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
