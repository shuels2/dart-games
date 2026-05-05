import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
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
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartClockworkQuest(
      tester,
      config,
      includeBullseye: includeBullseye,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool includeBullseye = false,
}) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);

  for (int startTarget = 1; startTarget <= 20; startTarget += 3) {
    for (int t = startTarget; t < startTarget + 3 && t <= 20; t++) {
      await throwDartViaMock(tester, t);
    }
    final targetsHit = (startTarget + 2 <= 20) ? 3 : (20 - startTarget + 1);
    for (int i = targetsHit; i < 3; i++) {
      await throwMissViaMock(tester);
    }
    await clickDartsRemoved(tester);

    if (ProviderHelpers.clockworkQuestHasWinner(tester)) break;

    for (int i = 0; i < numOpponents; i++) {
      await completeTurnWithMisses(tester);
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
    // Remove darts to trigger victory flow after bullseye win
    await clickDartsRemoved(tester);
  }

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
