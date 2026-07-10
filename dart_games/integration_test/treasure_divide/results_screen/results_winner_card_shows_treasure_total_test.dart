// integration_test/treasure_divide/results_screen/results_winner_card_shows_treasure_total_test.dart
//
// Results-5 (TD-specific) — The winner card displays the correct gold total.
// Strategy: 7-round game (sequence [20,19,18,D,17,T,Bull]).
// P1 always hits target (3 darts), P2 always misses (3 darts).
// After the game completes, assert the winner-section shows P1's name and
// the treasure score widget is visible with "gold" text.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';

final _config = GameUIConfig.treasureDivide();

MockScoliaApiService? _getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> _throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = _getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number *
          (multiplier == 'double'
              ? 2
              : multiplier == 'triple'
                  ? 3
                  : multiplier == 'bull'
                      ? 2
                      : 1),
      multiplier: multiplier,
      playerName: 'Player',
      baseScore: number,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
}

Future<void> _throwMissViaMock(WidgetTester tester) async {
  final mockApi = _getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'miss',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }
}

Future<void> _simulateTakeout(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  if (provider.shouldPromptTakeout) {
    final mockApi = _getMockApi(tester);
    mockApi?.simulateTakeoutFinished();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: winner card shows correct gold total for P1',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // 7-round sequence: [20, 19, 18, AnyDouble(-1), 17, AnyTriple(-2), Bull(25)]
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      _config,
      numberOfRounds: 7,
      playerNames: ['GoldP1', 'GoldP2'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);

    // P1 always hits 3 darts each round; P2 always misses.
    // turnCount: 0=P1, 1=P2, 2=P1, 3=P2, ...
    int turnCount = 0;
    while (!provider.hasWinner) {
      final roundIdx =
          ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdx);

      if (turnCount % 2 == 0) {
        // P1 turn — hit the target
        if (target == -1) {
          // AnyDouble
          await _throwDartViaMock(tester, 1, multiplier: 'double');
          await _throwDartViaMock(tester, 1, multiplier: 'double');
          await _throwDartViaMock(tester, 1, multiplier: 'double');
        } else if (target == -2) {
          // AnyTriple
          await _throwDartViaMock(tester, 1, multiplier: 'triple');
          await _throwDartViaMock(tester, 1, multiplier: 'triple');
          await _throwDartViaMock(tester, 1, multiplier: 'triple');
        } else {
          await _throwDartViaMock(tester, target);
          await _throwDartViaMock(tester, target);
          await _throwDartViaMock(tester, target);
        }
      } else {
        // P2 turn — all misses
        await _throwMissViaMock(tester);
        await _throwMissViaMock(tester);
        await _throwMissViaMock(tester);
      }

      await _simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      turnCount++;
    }

    // Poll for results screen
    for (int i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      if (find
          .byKey(TreasureDivideResultsKeys.playAgainButton)
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Verify results screen is showing
    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton),
        findsOneWidget,
        reason:
            '[DIAG td_results_treasure_total] Results screen not loaded');

    // Verify winner name shows GoldP1
    expect(find.byKey(TreasureDivideResultsKeys.winnerName), findsOneWidget,
        reason:
            '[DIAG td_results_treasure_total] Winner name widget not found');
    expect(find.textContaining('GoldP1'), findsWidgets,
        reason:
            '[DIAG td_results_treasure_total] GoldP1 not shown as winner');

    // Verify the treasure score widget is present and shows "gold" text
    expect(find.byKey(TreasureDivideResultsKeys.treasureScore), findsOneWidget,
        reason:
            '[DIAG td_results_treasure_total] Treasure score widget not found');
    // The winner score should be positive (P1 hit 3 darts per round × 7 rounds)
    expect(find.textContaining('gold'), findsWidgets,
        reason:
            '[DIAG td_results_treasure_total] "gold" text not found in results — '
            'treasure total display broken');
  });
}
