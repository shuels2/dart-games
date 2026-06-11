// integration_test/treasure_divide/gameplay/game_mode_solo_per_player_scoring_test.dart
//
// Group B – Test 5: Solo mode — each player's score is tracked independently.
// P1 hits; P2 misses all round 0. After round 0: P1 score > 0, P2 score = 0.
//
// NOTE: Uses throwDartDirect() for P1's hits — see min_player_count_test.dart
// for the full explanation of the MockScoliaApiService payload limitation.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Solo mode — per-player independent scoring',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        playerNames: ['SoloP1', 'SoloP2']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1Id = players[0].id;
    final p2Id = players[1].id;

    // Both scores should be 0 at start
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id), equals(0),
        reason: '[DIAG solo_scoring] P1 initial score should be 0');
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p2Id), equals(0),
        reason: '[DIAG solo_scoring] P2 initial score should be 0');

    // ── Round 0: P1 hits 3× target-20 ────────────────────────────────────
    final target = getCurrentRoundTarget(tester); // Should be 20 for 7-round default
    // Use throwDartDirect for non-zero scores (mock payload limitation)
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    // P1 score = 3 × target
    final p1Score = ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(p1Score, equals(target * 3),
        reason: '[DIAG solo_scoring] P1 score should be ${target * 3} after 3 hits');
    // P2 score still 0
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p2Id), equals(0),
        reason: '[DIAG solo_scoring] P2 score should still be 0 (has not thrown yet)');

    // ── Round 0: P2 misses all ────────────────────────────────────────────
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    // P2 score: halving of 0 = 0
    final p2Score = ProviderHelpers.getTreasureDividePlayerTotal(tester, p2Id);
    expect(p2Score, equals(0),
        reason: '[DIAG solo_scoring] P2 score should be 0 after wipeout round 0');

    // P1 score still unaffected by P2 completion
    final p1ScoreAfterRound =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(p1ScoreAfterRound, equals(p1Score),
        reason: '[DIAG solo_scoring] P1 score must not change when P2 completes round');

    // Scores are independent: P1 > 0, P2 = 0
    expect(p1ScoreAfterRound, greaterThan(p2Score),
        reason: '[DIAG solo_scoring] P1 and P2 must have different independent scores');

    // Suppress layout exceptions during cleanup pump (TD game screen layout bug).
    suppressLayoutExceptionsForCleanup();
  });
}
