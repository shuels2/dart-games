import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/navigation_suite.dart';

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
  // Extra pump time for game screen to fully render after navigation
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  expect(find.text('Carnival Derby Race'), findsOneWidget);
}

Future<void> completeGameToVictory(WidgetTester tester) async {
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await clickDartsRemoved(tester);

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPEC =====

Future<void> _setupAndStart(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  expect(find.textContaining('Target score:'), findsOneWidget);
  await setTargetScore(tester, 180);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await startGame(tester);
}

Future<void> _reachGameScreen(WidgetTester tester) async {
  await _setupAndStart(tester);
  await completeGameToVictory(tester);
  await ResultsHelpers.pumpUntilResults(tester, config);
  expect(config.getPlayAgainButton(), findsOneWidget);
  await UITestHelpers.clickPlayAgain(tester, config);

  // Extra settle after Play Again before the game screen is interactive.
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getCarnivalDerbyBackButton,
  setupAndStart: _setupAndStart,
  playToVictory: completeGameToVictory,
  reachGameScreen: _reachGameScreen,
  verifySettings: (tester) {
    expect(find.textContaining('180'), findsOneWidget);
  },
);
