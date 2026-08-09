import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/navigation_suite.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.reefRoyale();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwOuterBullViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwOuterBullViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config) =>
    GameSetupHelpers.setupAndStartReefRoyale(tester, config);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(WidgetTester tester) async {
  // P1 Turn 1: claim 20, 19, 18
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 19, multiplier: 'triple');
  await throwDartViaMock(tester, 18, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // P2 misses
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // P1 Turn 2: claim 17, 16, 15
  await throwDartViaMock(tester, 17, multiplier: 'triple');
  await throwDartViaMock(tester, 16, multiplier: 'triple');
  await throwDartViaMock(tester, 15, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // P2 misses
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // P1 Turn 3: claim Bull
  await throwBullseyeViaMock(tester);
  await throwOuterBullViaMock(tester);

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();

  await clickDartsRemoved(tester);

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPEC =====

Future<void> _reachGameScreen(WidgetTester tester) async {
  await setupAndStartGame(tester, config);
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
  menuBackButton: ElementFinders.getReefRoyaleBackButton,
  setupAndStart: (tester) => setupAndStartGame(tester, config),
  playToVictory: completeGameToVictory,
  reachGameScreen: _reachGameScreen,
  // The game-back test asserts the Game Mode control is back on the menu.
  verifySettings: (tester) {
    expect(find.textContaining('Game Mode'), findsOneWidget);
  },
);

/// Change Settings additionally asserts the mode dropdown and both players.
final navigationSettingsSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getReefRoyaleBackButton,
  setupAndStart: (tester) => setupAndStartGame(tester, config),
  playToVictory: completeGameToVictory,
  verifySettings: (tester) {
    expect(ElementFinders.getReefRoyaleGameModeDropdown(), findsOneWidget);
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  },
);
