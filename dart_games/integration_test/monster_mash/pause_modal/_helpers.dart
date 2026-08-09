import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/ui_test_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';

import '../../shared/results_helpers.dart';

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

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int? healthMax,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartMonsterMash(
      tester,
      config,
      healthMax: healthMax,
      playerNames: playerNames,
    );

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<void> openEditScore(WidgetTester tester, GameUIConfig config) =>
    EditScoreHelpers.openEditScore(tester, config);

Future<void> updateScore(WidgetTester tester) =>
    EditScoreHelpers.updateScore(tester);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(WidgetTester tester) async {
  final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
  final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
  if (playerA == null || playerB == null) {
    throw Exception('Players not found');
  }

  final currentPlayerId =
      ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
  final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
  final opponentTarget =
      ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

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

  // Wait for victory screen
  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Monster Mash is supplied here. Health Max 10 and the two
// players are the exact setup the hand-written results tests used.

Future<void> _reachResults(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await UITestHelpers.startGame(tester, config);
  await completeGameToVictory(tester);
}

final pauseModalSpec = PauseModalSpec(
  config: config,
  menuBackButton: ElementFinders.getMonsterMashBackButton,
  ownGameCard: ElementFinders.getMonsterMashCard,
  menuSettingsControls: [ElementFinders.getMonsterMashHealthPointsSlider],
  menuAddPlayerButton: ElementFinders.getMonsterMashAddPlayerButtonEmptyState,
  startGame: (tester) => setupAndStartGame(tester, config),
  throwOneDart: (tester) => throwDartViaMock(tester, 20),
  throwAnotherDart: (tester) => throwDartViaMock(tester, 19),
  throwTurnToTakeout: (tester) async {
    // Three 20s ends the turn and raises the takeout prompt.
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
  },
  finishTakeout: clickDartsRemoved,
  openEditScore: (tester) => openEditScore(tester, config),
  reachResults: _reachResults,
  resultsAfterReconnect: (tester) async {
    await UITestHelpers.clickBackToMenu(tester, config);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
        reason: 'Back to Menu did not work after reconnect');
  },
);
