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
  static Future<void> openEditScore(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final editButton = config.getEditScoreButton();

    expect(editButton, findsOneWidget,
        reason: 'Edit score button should be present before opening dialog');

    await tester.tap(editButton);
    await PumpSequences.dialogOpen(tester);

    final saveButton = ElementFinders.getEditScoreSaveButton();
    expect(saveButton, findsOneWidget,
        reason: 'Edit score dialog should be open after tapping edit button');
  }

  /// Update score (submit edit score dialog)
  static Future<void> updateScore(WidgetTester tester) async {
    final saveButton = ElementFinders.getEditScoreSaveButton();

    expect(saveButton, findsOneWidget,
        reason: 'Save button should be present before saving');

    await tester.tap(saveButton);
    await PumpSequences.dialogClose(tester);

    expect(saveButton, findsNothing,
        reason: 'Edit score dialog should be closed after saving');
  }

  /// Cancel edit score
  static Future<void> cancelEditScore(WidgetTester tester) async {
    final cancelButton = ElementFinders.getEditScoreCancelButton();

    expect(cancelButton, findsOneWidget,
        reason: 'Cancel button should be present before canceling');

    await tester.tap(cancelButton);
    await PumpSequences.dialogClose(tester);

    final saveButton = ElementFinders.getEditScoreSaveButton();
    expect(saveButton, findsNothing,
        reason: 'Edit score dialog should be closed after canceling');
  }

  // ==========================================================================
  // DART SCORE MANIPULATION
  // ==========================================================================

  /// Set dart 1 score in edit score dialog
  static Future<void> setDart1(WidgetTester tester, String sector) async {
    final dropdown = ElementFinders.getEditScoreDart1Dropdown();

    expect(dropdown, findsOneWidget,
        reason: 'Dart 1 dropdown should be present in edit score dialog');

    await tester.tap(dropdown);
    await PumpSequences.simpleUpdate(tester);

    final dropdownItem = find.text(sector).last;
    await tester.tap(dropdownItem);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Set dart 2 score in edit score dialog
  static Future<void> setDart2(WidgetTester tester, String sector) async {
    final dropdown = ElementFinders.getEditScoreDart2Dropdown();

    expect(dropdown, findsOneWidget,
        reason: 'Dart 2 dropdown should be present in edit score dialog');

    await tester.tap(dropdown);
    await PumpSequences.simpleUpdate(tester);

    final dropdownItem = find.text(sector).last;
    await tester.tap(dropdownItem);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Set dart 3 score in edit score dialog
  static Future<void> setDart3(WidgetTester tester, String sector) async {
    final dropdown = ElementFinders.getEditScoreDart3Dropdown();

    expect(dropdown, findsOneWidget,
        reason: 'Dart 3 dropdown should be present in edit score dialog');

    await tester.tap(dropdown);
    await PumpSequences.simpleUpdate(tester);

    final dropdownItem = find.text(sector).last;
    await tester.tap(dropdownItem);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Set all three darts at once
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

  static void verifyDialogOpen() {
    final dialog = ElementFinders.getEditScoreDialog();
    final saveButton = ElementFinders.getEditScoreSaveButton();
    expect(dialog, findsOneWidget);
    expect(saveButton, findsOneWidget);
  }

  static void verifyDialogClosed() {
    final dialog = ElementFinders.getEditScoreDialog();
    final saveButton = ElementFinders.getEditScoreSaveButton();
    expect(dialog, findsNothing);
    expect(saveButton, findsNothing);
  }

  static void verifyDialogElements() {
    expect(ElementFinders.getEditScoreDart1Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreDart2Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreDart3Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreSaveButton(), findsOneWidget);
    expect(ElementFinders.getEditScoreCancelButton(), findsOneWidget);
  }

  // ==========================================================================
  // COMPLETE WORKFLOWS
  // ==========================================================================

  /// Complete edit score workflow: open, set darts, save
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
