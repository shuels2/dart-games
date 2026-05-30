import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/provider_helpers.dart';

final config = GameUIConfig.gladiatorArena();

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

// ===== GAME-SPECIFIC HELPERS =====

/// Drive the game to victory with the FIRST player as the designated winner.
/// All non-winner players miss every turn. The winner throws T20 + Miss + Miss
/// each turn to gain 60 pts/turn. With targetScore=100 + DF=OFF, the winner
/// reaches target on their 2nd turn (60 + 60 = 120 ≥ 100 → WIN at turn end).
///
/// REQUIRES the test to have called `setupAndStartGame(...)` with
/// `targetScore: 100, doubleFinishEnabled: false`.
Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
}) async {
  final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
  final designatedWinnerId = provider.currentGame!.playerIds.first;

  for (int safety = 0; safety < 30; safety++) {
    if (provider.hasWinner) break;
    final currentId = provider.currentPlayerId;
    if (currentId == null) break;

    if (currentId == designatedWinnerId) {
      // P1 throws T20 + Miss + Miss (60 pts)
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      if (!provider.hasWinner && !provider.shouldPromptTakeout) {
        await throwMissViaMock(tester);
      }
      if (!provider.hasWinner && !provider.shouldPromptTakeout) {
        await throwMissViaMock(tester);
      }
    } else {
      // Other player: 3 misses
      for (int d = 0; d < 3; d++) {
        if (provider.hasWinner || provider.shouldPromptTakeout) break;
        await throwMissViaMock(tester);
      }
    }

    if (provider.hasWinner) break;
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
    }
  }

  // FINAL takeout click — fires _handleTakeoutFinished → _handleGameWon →
  // Navigator.pushReplacement(GladiatorArenaResultsScreen). Without this,
  // the RemoveDartsModal stays visible on the game screen forever (the
  // loop's takeout click only happens when shouldPromptTakeout is true
  // BUT the loop breaks on hasWinner BEFORE that branch fires for the
  // winning turn).
  if (provider.hasWinner) {
    await clickDartsRemoved(tester);
    await ResultsHelpers.pumpUntilResults(tester, config);
  }
}
