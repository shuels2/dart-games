import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.carnivalDerby();

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> navigateToCarnivalDerbyMenu(WidgetTester tester) async {
  await UITestHelpers.resetServerState();
  await UITestHelpers.navigateToGameMenu(tester, config);
  expect(find.textContaining('Target score:'), findsOneWidget);
}

Future<void> setTargetScore(WidgetTester tester, int targetScore) =>
    GameSetupHelpers.setCarnivalDerbyTargetScoreSlider(tester, targetScore);

Future<void> startGame(WidgetTester tester) async {
  await UITestHelpers.startGame(tester, config);
  expect(find.text('Carnival Derby Race'), findsOneWidget);
}

Future<void> completeGameToVictory(WidgetTester tester) async {
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await clickDartsRemoved(tester);

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
