import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../shared/dart_throw_helpers.dart';
import '../shared/pump_sequences.dart';
import '../shared/game_ui_config.dart';
import '../shared/game_setup_helpers.dart';
import '../shared/provider_helpers.dart';

final config = GameUIConfig.lunarLander();

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

// ===== GAME-SPECIFIC HELPERS =====

/// Complete the game to victory for Player A (first player).
///
/// Strategy: throw single 20s repeatedly until Player A's altitude reaches 0.
/// With altitude=200, this takes 10 singles of 20 (200 / 20 = 10).
/// With Hard Landing ON, we throw smaller values to avoid overshooting (avoid bust).
///
/// [numOpponents] controls how many opponents take dummy turns (with misses).
Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool hardLandingEnabled = false,
}) async {
  final provider = ProviderHelpers.getLunarLanderProvider(tester);

  // Repeatedly descend until we win
  // We descend 20 per dart (single 20), 3 darts per turn = 60 per turn
  // At altitude 200, ~3.3 turns needed (4 turns to be safe)
  // Strategy for Hard Landing: use single 10s to avoid overshoot near end
  for (int round = 0; round < 30; round++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final currentAlt = provider.getCurrentAltitude(currentPlayerId);

    if (hardLandingEnabled && currentAlt <= 20) {
      // Near-landing: throw exact value or 1 to avoid bust
      if (currentAlt > 0) {
        await throwDartViaMock(tester, currentAlt);
      }
    } else {
      // Standard: throw single 20
      await throwDartViaMock(tester, 20);
    }

    if (provider.hasWinner) break;

    // If turn is over (3 darts thrown or bust), remove darts and advance
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;

      // Opponents take dummy turns (all misses)
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
