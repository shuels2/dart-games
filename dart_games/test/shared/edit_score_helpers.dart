import 'package:flutter_test/flutter_test.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';
import 'game_ui_config.dart';

/// Helpers for interacting with edit score dialogs
///
/// Provides high-level operations for edit score dialogs using widget keys.
/// All operations are game-agnostic and work with any GameUIConfig.
class EditScoreHelpers {
  // ==========================================================================
  // DIALOG OPENING/CLOSING
  // ==========================================================================

  /// Open edit score dialog
  ///
  /// Taps the edit score button and waits for dialog to open.
  /// Verifies the dialog is displayed after opening.
  ///
  /// Example:
  /// ```dart
  /// final config = GameUIConfig.targetTag();
  /// await EditScoreHelpers.openEditScore(tester, config);
  /// ```
  static Future<void> openEditScore(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final editButton = config.getEditScoreButton();

    expect(editButton, findsOneWidget,
        reason: 'Edit score button should be present before opening dialog');

    await tester.tap(editButton);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog opened
    final saveButton = ElementFinders.getEditScoreSaveButton();
    expect(saveButton, findsOneWidget,
        reason: 'Edit score dialog should be open after tapping edit button');
  }

  /// Update score (submit edit score dialog)
  ///
  /// Taps the save/update button and waits for dialog to close.
  /// Verifies the dialog is dismissed after saving.
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.updateScore(tester);
  /// ```
  static Future<void> updateScore(WidgetTester tester) async {
    final saveButton = ElementFinders.getEditScoreSaveButton();

    expect(saveButton, findsOneWidget,
        reason: 'Save button should be present before saving');

    await tester.tap(saveButton);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    expect(saveButton, findsNothing,
        reason: 'Edit score dialog should be closed after saving');
  }

  /// Cancel edit score
  ///
  /// Taps the cancel button and waits for dialog to close.
  /// Verifies the dialog is dismissed without saving changes.
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.cancelEditScore(tester);
  /// ```
  static Future<void> cancelEditScore(WidgetTester tester) async {
    final cancelButton = ElementFinders.getEditScoreCancelButton();

    expect(cancelButton, findsOneWidget,
        reason: 'Cancel button should be present before canceling');

    await tester.tap(cancelButton);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    final saveButton = ElementFinders.getEditScoreSaveButton();
    expect(saveButton, findsNothing,
        reason: 'Edit score dialog should be closed after canceling');
  }

  // ==========================================================================
  // DART SCORE MANIPULATION
  // ==========================================================================

  /// Set dart 1 score in edit score dialog
  ///
  /// Opens dart 1 dropdown and selects the specified sector.
  /// Sector format: "S20", "D20", "T20", "Bull", "25", "Miss"
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.setDart1(tester, 'T20');
  /// ```
  static Future<void> setDart1(WidgetTester tester, String sector) async {
    final dropdown = ElementFinders.getEditScoreDart1Dropdown();

    expect(dropdown, findsOneWidget,
        reason: 'Dart 1 dropdown should be present in edit score dialog');

    await tester.tap(dropdown);
    await PumpSequences.simpleUpdate(tester);

    // Find and tap the dropdown item
    final dropdownItem = find.text(sector).last;
    await tester.tap(dropdownItem);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Set dart 2 score in edit score dialog
  ///
  /// Opens dart 2 dropdown and selects the specified sector.
  /// Sector format: "S20", "D20", "T20", "Bull", "25", "Miss"
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.setDart2(tester, 'D20');
  /// ```
  static Future<void> setDart2(WidgetTester tester, String sector) async {
    final dropdown = ElementFinders.getEditScoreDart2Dropdown();

    expect(dropdown, findsOneWidget,
        reason: 'Dart 2 dropdown should be present in edit score dialog');

    await tester.tap(dropdown);
    await PumpSequences.simpleUpdate(tester);

    // Find and tap the dropdown item
    final dropdownItem = find.text(sector).last;
    await tester.tap(dropdownItem);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Set dart 3 score in edit score dialog
  ///
  /// Opens dart 3 dropdown and selects the specified sector.
  /// Sector format: "S20", "D20", "T20", "Bull", "25", "Miss"
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.setDart3(tester, 'S20');
  /// ```
  static Future<void> setDart3(WidgetTester tester, String sector) async {
    final dropdown = ElementFinders.getEditScoreDart3Dropdown();

    expect(dropdown, findsOneWidget,
        reason: 'Dart 3 dropdown should be present in edit score dialog');

    await tester.tap(dropdown);
    await PumpSequences.simpleUpdate(tester);

    // Find and tap the dropdown item
    final dropdownItem = find.text(sector).last;
    await tester.tap(dropdownItem);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Set all three darts at once
  ///
  /// Convenience method to set all three dart scores in sequence.
  /// Use null or empty string to leave a dart unset.
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.setAllDarts(tester, 'T20', 'T20', 'D20');
  /// await EditScoreHelpers.setAllDarts(tester, 'Bull', 'Miss', null);
  /// ```
  static Future<void> setAllDarts(
    WidgetTester tester,
    String? dart1,
    String? dart2,
    String? dart3,
  ) async {
    if (dart1 != null && dart1.isNotEmpty) {
      await setDart1(tester, dart1);
    }
    if (dart2 != null && dart2.isNotEmpty) {
      await setDart2(tester, dart2);
    }
    if (dart3 != null && dart3.isNotEmpty) {
      await setDart3(tester, dart3);
    }
  }

  // ==========================================================================
  // VERIFICATION HELPERS
  // ==========================================================================

  /// Verify edit score dialog is open
  ///
  /// Checks that the dialog container and save button are present.
  ///
  /// Example:
  /// ```dart
  /// EditScoreHelpers.verifyDialogOpen();
  /// ```
  static void verifyDialogOpen() {
    final dialog = ElementFinders.getEditScoreDialog();
    final saveButton = ElementFinders.getEditScoreSaveButton();

    expect(dialog, findsOneWidget,
        reason: 'Edit score dialog container should be present');
    expect(saveButton, findsOneWidget,
        reason: 'Edit score save button should be present');
  }

  /// Verify edit score dialog is closed
  ///
  /// Checks that the dialog is no longer visible.
  ///
  /// Example:
  /// ```dart
  /// EditScoreHelpers.verifyDialogClosed();
  /// ```
  static void verifyDialogClosed() {
    final dialog = ElementFinders.getEditScoreDialog();
    final saveButton = ElementFinders.getEditScoreSaveButton();

    expect(dialog, findsNothing,
        reason: 'Edit score dialog container should not be present');
    expect(saveButton, findsNothing,
        reason: 'Edit score save button should not be present');
  }

  /// Verify all edit score dialog elements are present
  ///
  /// Checks for all three dart dropdowns, save button, and cancel button.
  ///
  /// Example:
  /// ```dart
  /// EditScoreHelpers.verifyDialogElements();
  /// ```
  static void verifyDialogElements() {
    expect(ElementFinders.getEditScoreDart1Dropdown(), findsOneWidget,
        reason: 'Dart 1 dropdown should be present');
    expect(ElementFinders.getEditScoreDart2Dropdown(), findsOneWidget,
        reason: 'Dart 2 dropdown should be present');
    expect(ElementFinders.getEditScoreDart3Dropdown(), findsOneWidget,
        reason: 'Dart 3 dropdown should be present');
    expect(ElementFinders.getEditScoreSaveButton(), findsOneWidget,
        reason: 'Save button should be present');
    expect(ElementFinders.getEditScoreCancelButton(), findsOneWidget,
        reason: 'Cancel button should be present');
  }

  // ==========================================================================
  // COMPLETE WORKFLOWS
  // ==========================================================================

  /// Complete edit score workflow: open, set darts, save
  ///
  /// Convenience method that combines opening dialog, setting scores, and saving.
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.editScoreAndSave(
  ///   tester,
  ///   config,
  ///   dart1: 'T20',
  ///   dart2: 'T20',
  ///   dart3: 'D20',
  /// );
  /// ```
  static Future<void> editScoreAndSave(
    WidgetTester tester,
    GameUIConfig config, {
    String? dart1,
    String? dart2,
    String? dart3,
  }) async {
    await openEditScore(tester, config);
    await setAllDarts(tester, dart1, dart2, dart3);
    await updateScore(tester);
  }

  /// Complete edit score workflow: open, set darts, cancel
  ///
  /// Convenience method for testing cancel functionality.
  ///
  /// Example:
  /// ```dart
  /// await EditScoreHelpers.editScoreAndCancel(
  ///   tester,
  ///   config,
  ///   dart1: 'T20',
  ///   dart2: 'Miss',
  /// );
  /// ```
  static Future<void> editScoreAndCancel(
    WidgetTester tester,
    GameUIConfig config, {
    String? dart1,
    String? dart2,
    String? dart3,
  }) async {
    await openEditScore(tester, config);
    await setAllDarts(tester, dart1, dart2, dart3);
    await cancelEditScore(tester);
  }
}
