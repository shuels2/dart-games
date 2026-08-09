// integration_test/treasure_divide/play_to_complete/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide play-to-complete tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

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
  WidgetTester tester, {
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  bool teamMode = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      teamMode: teamMode,
      playerNames: playerNames,
    );

// ===== TREASURE DIVIDE-SPECIFIC HELPERS =====

/// Get the current round's target number from the provider.
int getCurrentRoundTarget(WidgetTester tester) {
  final roundIndex = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
  return ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
}

/// Drive a 2-player solo game to completion (all rounds, target hit every turn).
///
/// Every player hits the round's target on dart 1. After all rounds,
/// hasWinner becomes true and the results screen navigates into view.
Future<void> playGameToCompletion(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentRoundTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation (victory delay + animation)
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}

// ===== PLAY TO COMPLETE SUITE SPEC =====
//
// Shared bodies live in shared/play_to_complete_suite.dart; everything
// specific to Treasure Divide is supplied here. Only the two commodity scenarios
// (default settings, mid-game pickup) use it — the per-option tests in this
// folder stay hand-written.

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartTreasureDivide(tester, config),
  hasWinner: (tester) =>
      ProviderHelpers.getTreasureDivideProvider(tester).hasWinner,
  // A full turn of misses, then takeout, so auto-play picks up on P2's turn.
  //
  // Takeout goes through the mock API, NOT clickDartsRemoved: that taps the
  // DARTS REMOVED button, which calls
  // dartboardKey?.currentState?.removeDarts() — and TD's game screen never
  // passes a dartboardKey to DartboardEmulatorSection, so the tap is a no-op.
  midGameDarts: (tester) async {
    for (var i = 0; i < 3; i++) {
      await DartThrowHelpers.throwMissViaMock(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }
    DartThrowHelpers.getMockApi(tester)?.simulateTakeoutFinished();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  },
  maxIterations: 500,
);
