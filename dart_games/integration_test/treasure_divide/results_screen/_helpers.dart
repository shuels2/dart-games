// integration_test/treasure_divide/results_screen/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide results-screen tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> setupAndStartGame(
  WidgetTester tester, {
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      teamMode: teamMode,
      manualAssignment: manualAssignment,
      playerNames: playerNames,
    );

// ===== TREASURE DIVIDE-SPECIFIC HELPERS =====

/// Get the current round's target number from the provider.
int getCurrentRoundTarget(WidgetTester tester) {
  final roundIndex = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
  return ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
}

/// Throw a single dart that hits the given round target.
/// Handles special targets: -1=AnyDouble, -2=AnyTriple, 25=Bull.
Future<void> _throwHitForTarget(WidgetTester tester, int target) async {
  if (target == -1) {
    // AnyDouble: throw D1 (any double qualifies)
    await throwDartViaMock(tester, 1, multiplier: 'double');
  } else if (target == -2) {
    // AnyTriple: throw T1 (any triple qualifies)
    await throwDartViaMock(tester, 1, multiplier: 'triple');
  } else if (target == 25) {
    // Bull: throw outer bull (base=25, multiplier='bull')
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: 25,
        multiplier: 'bull',
        playerName: 'Player',
        baseScore: 25,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }
  } else {
    // Standard target: throw single matching segment
    await throwDartViaMock(tester, target);
  }
}

/// Simulate takeout via direct mock API call (matches gameplay/_helpers.dart
/// simulateTakeout pattern). Uses mockApi.simulateTakeoutFinished() directly
/// rather than tapping the UI button, which is the proven integration test
/// pattern for the TD game screen.
Future<void> simulateTakeout(WidgetTester tester) async {
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

/// Drive a 2-player solo game to completion, then pump until results screen.
///
/// P1 (first player at start) always hits target; P2 always misses.
/// This ensures P1 wins with a non-zero score and no ties can occur,
/// so winner/loser stats are deterministic: P1.gamesWon=1, P2.gamesWon=0.
///
/// Uses simulateTakeoutFinished() directly rather than tapping the UI button
/// (the DARTS REMOVED button is broken for TD — dartboardKey is null).
Future<void> playGameToResultsScreen(WidgetTester tester) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);

  // Capture P1's ID at game start — always the first player to act.
  final p1Id = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);

  int turnCount = 0;

  while (!provider.hasWinner) {
    final currentId = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);
    final isP1Turn = (currentId == p1Id);

    if (isP1Turn) {
      // P1 hits target all 3 darts → accumulates gold.
      // Special targets: -1=AnyDouble, -2=AnyTriple, 25=Bull.
      final target = getCurrentRoundTarget(tester);
      await _throwHitForTarget(tester, target);
      await _throwHitForTarget(tester, target);
      await _throwHitForTarget(tester, target);
    } else {
      // P2 misses all 3 darts → 0 gold
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
    }

    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    turnCount++;
    // Safety: prevent infinite loop (max 2 players × 12 rounds × some buffer)
    if (turnCount > 40) break;
  }

  await ResultsHelpers.pumpUntilResults(tester, config);
}
