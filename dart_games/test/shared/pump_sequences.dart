import 'package:flutter_test/flutter_test.dart';

/// Shared pump sequence patterns for UI tests
///
/// These handle continuous animations that prevent pumpAndSettle() from working.
/// Use these instead of raw pump() calls for consistency.
class PumpSequences {
  /// Standard navigation pump sequence
  ///
  /// Use after tapping a navigation element (button, card, etc.)
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(HomeKeys.targetTagCard));
  /// await PumpSequences.navigation(tester);
  /// ```
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

  /// Async data loading pump sequence
  ///
  /// Use after operations that load data from the server or other async sources
  ///
  /// Example:
  /// ```dart
  /// // App loads players on startup
  /// app.main();
  /// await PumpSequences.asyncDataLoad(tester);
  /// ```
  static Future<void> asyncDataLoad(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5)); // Wait for async operation
    await tester.pump(); // Process data loaded
    await tester.pump(); // Rebuild widget tree
    await tester.pump(); // Layout widgets
    await tester.pump(); // Paint widgets
  }

  /// Dialog open pump sequence
  ///
  /// Use after tapping button that opens a dialog
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(MenuKeys.addPlayerButton));
  /// await PumpSequences.dialogOpen(tester);
  /// ```
  static Future<void> dialogOpen(WidgetTester tester) async {
    await tester.pump(); // Process tap
    await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
    await tester.pump(); // Build dialog
    await tester.pump(); // Layout dialog
    await tester.pump(); // Paint dialog
  }

  /// Dialog close pump sequence
  ///
  /// Use after tapping button that closes a dialog
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(DialogKeys.cancelButton));
  /// await PumpSequences.dialogClose(tester);
  /// ```
  static Future<void> dialogClose(WidgetTester tester) async {
    await tester.pump(); // Process tap
    await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog to close
    await tester.pump(); // Process dialog closing
    // Wait for UI to rebuild after dialog action (e.g., adding player)
    await tester.pump(const Duration(milliseconds: 500)); // Wait for state changes
    await tester.pump(); // Process state changes
    await tester.pump(); // Rebuild UI
    await tester.pump(); // Layout widgets
    await tester.pump(); // Paint widgets
  }

  /// Text entry pump sequence
  ///
  /// Use after entering text in a field
  ///
  /// Example:
  /// ```dart
  /// await tester.enterText(find.byKey(DialogKeys.nameField), 'Alice');
  /// await PumpSequences.textEntry(tester);
  /// ```
  static Future<void> textEntry(WidgetTester tester) async {
    await tester.pump(); // Process text entry
    await tester.pump(); // Update text field
  }

  /// Simple UI update pump sequence
  ///
  /// Use after state changes that trigger simple UI updates (no navigation/dialogs)
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(MenuKeys.teamModeSwitch));
  /// await PumpSequences.simpleUpdate(tester);
  /// ```
  static Future<void> simpleUpdate(WidgetTester tester) async {
    await tester.pump(); // Process state change
    await tester.pump(); // Rebuild UI
  }

  /// Full screen rebuild pump sequence
  ///
  /// Use when waiting for complete screen re-render (e.g., after game over)
  ///
  /// Example:
  /// ```dart
  /// // After last dart thrown in game
  /// await PumpSequences.fullRebuild(tester);
  /// ```
  static Future<void> fullRebuild(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}
