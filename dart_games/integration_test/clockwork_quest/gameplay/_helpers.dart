import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.clockworkQuest();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  bool speedMode = false,
  int laps = 1,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartClockworkQuest(
      tester,
      config,
      includeBullseye: includeBullseye,
      speedMode: speedMode,
      laps: laps,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool includeBullseye = false,
}) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);

  for (int target = 1; target <= 20; target++) {
    await throwDartViaMock(tester, target);

    if (target % 3 == 0 && target < 20) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
  }

  if (includeBullseye && !provider.hasWinner) {
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
    await throwBullseyeViaMock(tester);
  }

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> advancePlayerToTarget(
    WidgetTester tester, int targetNumber) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);
  final playerId = provider.getCurrentPlayerId()!;

  for (int t = 1; t < targetNumber; t++) {
    await throwDartViaMock(tester, t);
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3) {
      await clickDartsRemoved(tester);
      await completeTurnWithMisses(tester);
    }
  }
}
