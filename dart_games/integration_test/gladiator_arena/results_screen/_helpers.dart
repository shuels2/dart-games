import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/results_helpers.dart';
export '../../shared/provider_helpers.dart';

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

Future<void> clickPlayAgain(WidgetTester tester) =>
    ResultsHelpers.clickPlayAgain(tester, config);

Future<void> clickChangeSettings(WidgetTester tester) =>
    ResultsHelpers.clickChangeSettings(tester, config);

Future<void> clickBackToMenu(WidgetTester tester) =>
    ResultsHelpers.clickSelectDifferentGame(tester, config);

// ===== GAME-SPECIFIC HELPERS =====

/// Complete game to victory (DF OFF, target=100 for speed).
/// Strategy: P1 (playerIds.first) is designated winner.
///   - Winner throws T20 (60 pts) + Miss + Miss per turn (winning dart is dart 3).
///   - All other players throw 3 misses.
/// With target=100, DF=OFF: P1 wins on their 2nd turn (60+60=120 ≥ 100).
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
      // Winner: T20 + Miss + Miss (60 pts), winning dart is dart 3 when turn ends.
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      if (!provider.hasWinner && !provider.shouldPromptTakeout) {
        await throwMissViaMock(tester);
      }
      if (!provider.hasWinner && !provider.shouldPromptTakeout) {
        await throwMissViaMock(tester);
      }
    } else {
      // Non-winner: 3 misses
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

  // Final takeout click fires _handleTakeoutFinished → _handleGameWon → navigate.
  if (provider.hasWinner) {
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);
  }
}
