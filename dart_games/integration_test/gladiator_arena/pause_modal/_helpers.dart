import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';

import '../../shared/results_helpers.dart';

import '../../shared/element_finders.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.gladiatorArena();

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
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      targetScore: targetScore,
      doubleFinishEnabled: doubleFinishEnabled,
      shieldRoundEnabled: shieldRoundEnabled,
      speedPlayEnabled: speedPlayEnabled,
      playerNames: playerNames,
    );

Future<void> openEditScore(WidgetTester tester, GameUIConfig config) =>
    EditScoreHelpers.openEditScore(tester, config);

Future<void> updateScore(WidgetTester tester) =>
    EditScoreHelpers.updateScore(tester);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getGladiatorArenaProvider(tester);

  // Use targetScore=100, doubleFinishEnabled=false to win quickly
  // P1 throws S20 x 5 = 100, opponents miss
  for (int round = 0; round < 30; round++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.currentPlayerId;
    if (currentPlayerId == null) break;

    for (int d = 0; d < 3; d++) {
      if (provider.hasWinner || provider.shouldPromptTakeout) break;
      await throwDartViaMock(tester, 20);
    }

    if (provider.hasWinner) break;

    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;
      await completeTurnWithMisses(tester);
    }
  }

  if (provider.hasWinner) {
    await clickDartsRemoved(tester);
  }

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Gladiator Arena is supplied here.
//
// NOTE: Gladiator's twenty hand-written pause tests were hollow — every body
// in all three files was the same four lines (navigate, disconnect, assert
// the start/back button, reconnect) regardless of the test's name, and not
// one of them contained a `tester.tap`. Wiring them to these runners is what
// finally gives the category the coverage its names have always claimed.
//
// Results uses targetScore 100 with double-finish off, per the note on
// completeGameToVictory: 5 x S20 reaches 100 and ends the game quickly.

final pauseModalSpec = PauseModalSpec(
  config: config,
  menuBackButton: ElementFinders.getGladiatorArenaBackButton,
  ownGameCard: ElementFinders.getGladiatorArenaCard,
  verifyOnMenu: (tester) =>
      expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget,
          reason: 'Menu screen not showing — start button not found'),
  menuSettingsControls: [ElementFinders.getGladiatorArenaTargetScoreSlider],
  menuAddPlayerButton:
      ElementFinders.getGladiatorArenaAddPlayerButtonEmptyState,
  startGame: (tester) => setupAndStartGame(tester, config),
  throwOneDart: (tester) => throwDartViaMock(tester, 20),
  throwAnotherDart: (tester) => throwDartViaMock(tester, 19),
  throwTurnToTakeout: (tester) async {
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
  },
  finishTakeout: clickDartsRemoved,
  openEditScore: (tester) => openEditScore(tester, config),
  reachResults: (tester) async {
    await setupAndStartGame(tester, config,
        targetScore: 100, doubleFinishEnabled: false);
    await completeGameToVictory(tester);
  },
  resultsAfterReconnect: (tester) async {
    await UITestHelpers.clickBackToMenu(tester, config);
    expect(ElementFinders.getGladiatorArenaCard(), findsOneWidget,
        reason: 'Back to Menu did not work after reconnect');
  },
);
