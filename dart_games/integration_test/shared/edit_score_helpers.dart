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

  /// Parse a segment string into ring and number components
  /// Returns a map with 'ring' (String) and 'number' (int?) keys
  static Map<String, dynamic> _parseSegment(String segment) {
    if (segment == 'Bull') {
      return {'ring': 'Bullseye', 'number': null};
    }
    if (segment == '25') {
      return {'ring': 'Outer Bull', 'number': null};
    }
    if (segment == 'Miss') {
      return {'ring': 'Miss', 'number': null};
    }

    // Parse S20, s20, D20, T20 format
    final pattern = RegExp(r'^([SDTsd])(\d+)$');
    final match = pattern.firstMatch(segment);
    if (match == null) {
      throw ArgumentError('Invalid segment format: $segment');
    }

    final prefix = match.group(1)!;
    final number = int.parse(match.group(2)!);

    String ring;
    if (prefix == 'S') {
      ring = 'Single (outer)';
    } else if (prefix == 's') {
      ring = 'Single (inner)';
    } else if (prefix == 'D') {
      ring = 'Double';
    } else if (prefix == 'T') {
      ring = 'Triple';
    } else {
      throw ArgumentError('Unknown prefix: $prefix');
    }

    return {'ring': ring, 'number': number};
  }

  /// Set a dart score by clicking ring button, then number button (if needed)
  /// dartIndex: 0 for D1, 1 for D2, 2 for D3
  static Future<void> _setDartScore(
    WidgetTester tester,
    int dartIndex,
    String segment,
  ) async {
    final parsed = _parseSegment(segment);
    final ring = parsed['ring'] as String;
    final number = parsed['number'] as int?;

    // Find the dart section (Column with key)
    final dartSection = dartIndex == 0
        ? ElementFinders.getEditScoreDart1Dropdown()
        : dartIndex == 1
            ? ElementFinders.getEditScoreDart2Dropdown()
            : ElementFinders.getEditScoreDart3Dropdown();

    expect(dartSection, findsOneWidget,
        reason: 'Dart ${dartIndex + 1} section should be present');

    // Find ring button within this dart section by text
    // We need to find the ring button that is a descendant of this dart section
    final ringButtonFinder = find.descendant(
      of: dartSection,
      matching: find.text(ring),
    );

    expect(ringButtonFinder, findsOneWidget,
        reason: 'Ring button "$ring" should be present in dart ${dartIndex + 1} section');

    await tester.tap(ringButtonFinder);
    await PumpSequences.simpleUpdate(tester);

    // If this ring requires a number, click the number button
    if (number != null) {
      final numberButtonFinder = find.descendant(
        of: dartSection,
        matching: find.text('$number'),
      );

      expect(numberButtonFinder, findsOneWidget,
          reason: 'Number button "$number" should be present and enabled in dart ${dartIndex + 1} section');

      await tester.tap(numberButtonFinder);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Set dart 1 score in edit score dialog
  static Future<void> setDart1(WidgetTester tester, String sector) async {
    await _setDartScore(tester, 0, sector);
  }

  /// Set dart 2 score in edit score dialog
  static Future<void> setDart2(WidgetTester tester, String sector) async {
    await _setDartScore(tester, 1, sector);
  }

  /// Set dart 3 score in edit score dialog
  static Future<void> setDart3(WidgetTester tester, String sector) async {
    await _setDartScore(tester, 2, sector);
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
