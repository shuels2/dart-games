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

final config = GameUIConfig.lunarLander();

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
  int altitude = 200,
  bool hardLanding = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: altitude,
      hardLanding: hardLanding,
      playerNames: playerNames,
    );

Future<void> clickPlayAgain(WidgetTester tester) =>
    ResultsHelpers.clickPlayAgain(tester, config);

Future<void> clickChangeSettings(WidgetTester tester) =>
    ResultsHelpers.clickChangeSettings(tester, config);

Future<void> clickBackToMenu(WidgetTester tester) =>
    ResultsHelpers.clickSelectDifferentGame(tester, config);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool hardLandingEnabled = false,
}) async {
  final provider = ProviderHelpers.getLunarLanderProvider(tester);

  for (int round = 0; round < 30; round++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final currentAlt = provider.getCurrentAltitude(currentPlayerId);

    if (hardLandingEnabled && currentAlt <= 20) {
      if (currentAlt > 0) {
        await throwDartViaMock(tester, currentAlt);
      }
    } else {
      await throwDartViaMock(tester, 20);
    }

    if (provider.hasWinner) break;

    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;

      for (int i = 0; i < numOpponents; i++) {
        if (provider.hasWinner) break;
        await completeTurnWithMisses(tester);
      }
    }
  }

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
