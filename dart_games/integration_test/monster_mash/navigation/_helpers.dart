import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/navigation_suite.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.monsterMash();

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

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(WidgetTester tester) async {
  final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
  final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
  if (playerA == null || playerB == null) {
    throw Exception('Players not found');
  }

  final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
  final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
  final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

  // Attack opponent with triples: 3+3+3 = 9 damage (out of 10 HP)
  await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
  await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
  await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // Opponent misses
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // Finish off opponent (1 HP remaining)
  await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
  await clickDartsRemoved(tester);

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPEC =====

Future<void> _setupAndStart(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await UITestHelpers.startGame(tester, config);
}

void _verifyHealthMax(WidgetTester tester) {
  final slider =
      tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
  expect(slider.value.toInt(), 10,
      reason: 'Health max should be preserved at 10');
}

Future<void> _reachGameScreen(WidgetTester tester) async {
  await _setupAndStart(tester);
  await completeGameToVictory(tester);
  await ResultsHelpers.pumpUntilResults(tester, config);
  expect(config.getPlayAgainButton(), findsOneWidget);
  await UITestHelpers.clickPlayAgain(tester, config);

  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getMonsterMashBackButton,
  setupAndStart: _setupAndStart,
  playToVictory: completeGameToVictory,
  reachGameScreen: _reachGameScreen,
  verifySettings: _verifyHealthMax,
);

/// The Change Settings test additionally asserts both players survived.
final navigationSettingsSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getMonsterMashBackButton,
  setupAndStart: _setupAndStart,
  playToVictory: completeGameToVictory,
  verifySettings: (tester) {
    _verifyHealthMax(tester);
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  },
);
