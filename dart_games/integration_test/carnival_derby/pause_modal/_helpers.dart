import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/results_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/edit_score_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.carnivalDerby();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

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

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Carnival Derby is supplied here.
//
// Like Target Tag, Carnival's hand-written pause tests were the older
// generation with guarded taps and no overlay assertions. The shared bodies
// are a strict superset of what they checked.

final pauseModalSpec = PauseModalSpec(
  config: config,
  menuBackButton: ElementFinders.getCarnivalDerbyBackButton,
  ownGameCard: ElementFinders.getCarnivalDerbyCard,
  verifyOnMenu: (tester) =>
      expect(find.textContaining('Target score:'), findsOneWidget,
          reason: 'Menu screen not showing — target score label not found'),
  menuSettingsControls: [ElementFinders.getCarnivalDerbyTargetScoreDropdown],
  menuStartPlayers: const ['PauseA', 'PauseB'],
  verifyOnHome: (tester) {
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);
    expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
  },
  startGame: (tester) =>
      GameSetupHelpers.setupAndStartCarnivalDerby(tester, config),
  verifyOnGameScreen: (tester) {
    expect(config.getGameBackButton(), findsOneWidget,
        reason: 'Game screen not showing — game back button not found');
    expect(ProviderHelpers.isCarnivalDerbyGameActive(tester), isTrue,
        reason: 'Game is no longer active');
  },
  throwOneDart: (tester) => throwDartViaMock(tester, 20),
  throwAnotherDart: (tester) => throwDartViaMock(tester, 5),
  throwTurnToTakeout: (tester) async {
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 1);
  },
  verifyNoSavePrompt: (tester) => expect(find.text('Save'), findsNothing,
      reason: 'Save prompt appeared despite the pause overlay'),
  finishTakeout: clickDartsRemoved,
  openEditScore: (tester) => EditScoreHelpers.openEditScore(tester, config),
  reachResults: (tester) async {
    await GameSetupHelpers.setupAndStartCarnivalDerby(tester, config);
    await completeGameToVictory(tester);
  },
  resultsAfterReconnect: (tester) async {
    await UITestHelpers.clickPlayAgain(tester, config);
    expect(config.getPlayAgainButton(), findsNothing,
        reason: 'Play Again did not work after reconnect');
  },
);
