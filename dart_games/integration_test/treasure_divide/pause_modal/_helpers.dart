// integration_test/treasure_divide/pause_modal/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide pause-modal (dartboard paused) tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';
export '../../shared/element_finders.dart';

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
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      playerNames: playerNames,
    );

Future<void> openEditScore(WidgetTester tester, GameUIConfig cfg) =>
    EditScoreHelpers.openEditScore(tester, cfg);

void simulateDartboardDisconnection(WidgetTester tester) =>
    ProviderHelpers.simulateDartboardDisconnection(tester);

void simulateDartboardReconnection(WidgetTester tester) =>
    ProviderHelpers.simulateDartboardReconnection(tester);

// ===== TREASURE DIVIDE-SPECIFIC HELPERS =====

/// Get the current round's target number from the provider.
int getCurrentRoundTarget(WidgetTester tester) {
  final roundIndex = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
  return ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
}

/// Throws a single dart against [target], picking the multiplier that
/// actually satisfies the target. Treats Treasure Divide's sentinel targets
/// (Any Double = -1, Any Triple = -2, Bull = 25) by throwing the right kind
/// of dart (D20, T20, Bull). For 1-20 targets, throws a single.
Future<void> _throwHitForTarget(WidgetTester tester, int target) async {
  if (target == -1) {
    // Any Double — D20 satisfies and scores 40
    await throwDartViaMock(tester, 20, multiplier: 'double');
  } else if (target == -2) {
    // Any Triple — T20 satisfies and scores 60
    await throwDartViaMock(tester, 20, multiplier: 'triple');
  } else if (target == 25) {
    // Bull round — Bullseye satisfies
    await throwDartViaMock(tester, 25, multiplier: 'bullseye');
  } else {
    await throwDartViaMock(tester, target);
  }
}

/// Simulate a single TD takeout: wait 1s for the provider to process the
/// final dart, then fire `simulateTakeoutFinished` only if
/// `shouldPromptTakeout` is true.  Mirrors the proven pattern from
/// results_screen/_helpers.dart simulateTakeout().
Future<void> _simulateTakeoutViaMock(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  if (provider.shouldPromptTakeout) {
    final mockApi = getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

/// Drive a Solo or Team game to completion. Hits the target every turn so the
/// player with the first throw of each round accumulates the most gold and
/// wins. Reads `dartsThisTurn` from the provider per iteration so both Solo
/// (3 darts) and Team-mode solo-crew (6 darts) turns are filled correctly.
///
/// Uses `_simulateTakeoutViaMock` (mirrors results_screen/_helpers.dart
/// simulateTakeout) which guards on `shouldPromptTakeout` before firing the
/// event. The UI "DARTS REMOVED" button is broken for TD (no dartboardKey
/// passed → `dartboardKey?.currentState?.removeDarts()` is a no-op), so the
/// mock-API path is the only reliable way to advance turns.
///
/// Has a hard safety bound — if 40 turn-loop iterations pass without
/// reaching `hasWinner`, throws an Exception (prevents the test from
/// looping indefinitely if a takeout never advances).
Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  const int maxIterations = 40; // 9-round 2p Solo = 18 turns; plenty of headroom
  int iterations = 0;

  while (!provider.hasWinner) {
    if (iterations++ > maxIterations) {
      throw Exception(
          'completeGameToVictory: hit safety bound at $maxIterations '
          'iterations without reaching hasWinner — game completion stalled.');
    }
    final roundIndex =
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target =
        ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
    final dartsThisTurn = provider.currentGame?.dartsThisTurn ?? 3;
    // Fill the whole turn — solo = 3 darts, solo-crew team = 6 darts.
    for (int i = 0; i < dartsThisTurn; i++) {
      await _throwHitForTarget(tester, target);
    }
    // Wait for shouldPromptTakeout then commit the turn via mock API.
    await _simulateTakeoutViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  // Wait for results screen navigation (Play Again button mounts).
  await ResultsHelpers.pumpUntilResults(tester, config);
}
