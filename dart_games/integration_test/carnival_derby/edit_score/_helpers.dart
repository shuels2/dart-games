import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/edit_score_helpers.dart';
export '../../shared/provider_helpers.dart';

final config = GameUIConfig.carnivalDerby();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int? targetScore,
  bool perfectFinish = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartCarnivalDerby(
      tester,
      config,
      targetScore: targetScore,
      perfectFinish: perfectFinish,
      playerNames: playerNames,
    );

Future<void> openEditScore(WidgetTester tester) =>
    EditScoreHelpers.openEditScore(tester, config);

Future<void> updateScore(WidgetTester tester) =>
    EditScoreHelpers.updateScore(tester);

/// Carnival Derby-specific: set dart ring in edit score dialog.
/// Only changes the ring button (e.g., 'Triple', 'Double', 'Single')
/// without re-selecting the number, which avoids ambiguity with
/// Carnival Derby's ring-button layout where numbers appear in multiple columns.
Future<void> setDartInEditScore(WidgetTester tester, int dartIndex, String ring, {int? number}) async {
  final ringButton = find.text(ring);
  if (ringButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(ringButton.first);
    await tester.pump();
    await tester.tap(ringButton.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }

  if (number != null && ring != 'Bullseye' && ring != 'Outer bull (25)' && ring != 'Miss') {
    final numberText = find.descendant(
      of: find.byType(Dialog),
      matching: find.text(number.toString()),
    );
    final actualIndex = dartIndex + 1;
    if (numberText.evaluate().length > actualIndex) {
      await tester.ensureVisible(numberText.at(actualIndex));
      await tester.pump();
      await tester.tap(numberText.at(actualIndex), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }
  }
}
