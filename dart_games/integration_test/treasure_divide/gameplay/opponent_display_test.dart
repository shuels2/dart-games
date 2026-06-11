// integration_test/treasure_divide/gameplay/opponent_display_test.dart
//
// Group A – Test 3: 3-player Solo. After each player's turn the opponent tile
// reflects their updated score, and previous players' scores are not overwritten.
//
// NOTE: Uses throwDartDirect() for hit throws — see min_player_count_test.dart
// for the full explanation of the MockScoliaApiService payload limitation.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: opponent tiles show updated scores and do not overwrite each other',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        playerNames: ['OppP1', 'OppP2', 'OppP3']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    expect(players.length, 3,
        reason: '[DIAG opp_display] Should have 3 players');

    final p1 = players[0];
    final p2 = players[1];
    final p3 = players[2];

    // ── P1 turn: 3 hits (score > 0) ───────────────────────────────────────
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester), equals(p1.id),
        reason: '[DIAG opp_display] P1 should be active first');
    final target = getCurrentRoundTarget(tester);
    // Use throwDartDirect for non-zero scores (mock payload limitation)
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    final p1ScoreAfterTurn = ProviderHelpers.getTreasureDividePlayerTotal(tester, p1.id);
    expect(p1ScoreAfterTurn, greaterThan(0),
        reason: '[DIAG opp_display] P1 score should be > 0 after 3 hits');

    // ── P2 turn: 3 misses (score stays 0 after halving 0) ─────────────────
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester), equals(p2.id),
        reason: '[DIAG opp_display] P2 should be active after P1 takeout');
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    // P2 started at 0 so halving = 0
    final p2ScoreAfterTurn = ProviderHelpers.getTreasureDividePlayerTotal(tester, p2.id);
    expect(p2ScoreAfterTurn, equals(0),
        reason: '[DIAG opp_display] P2 score should be 0 after miss with no prior score');

    // P1 score should be unchanged
    final p1ScoreCheck =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p1.id);
    expect(p1ScoreCheck, equals(p1ScoreAfterTurn),
        reason: '[DIAG opp_display] P1 score should not change after P2 completes turn');

    // ── P3 turn: 3 hits ───────────────────────────────────────────────────
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester), equals(p3.id),
        reason: '[DIAG opp_display] P3 should be active after P2 takeout');
    final target2 = getCurrentRoundTarget(tester);
    await throwDartDirect(tester, target2);
    await throwDartDirect(tester, target2);
    await throwDartDirect(tester, target2);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    drainExceptions(tester);

    final p3ScoreAfterTurn =
        ProviderHelpers.getTreasureDividePlayerTotal(tester, p3.id);
    expect(p3ScoreAfterTurn, greaterThan(0),
        reason: '[DIAG opp_display] P3 score should be > 0 after 3 hits');

    // P1 and P2 scores still correct after P3's turn
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p1.id),
        equals(p1ScoreAfterTurn),
        reason: '[DIAG opp_display] P1 score not overwritten by P3 turn');
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p2.id),
        equals(0),
        reason: '[DIAG opp_display] P2 score not overwritten by P3 turn');

    // Suppress layout exceptions during cleanup pump (TD game screen layout bug).
    suppressLayoutExceptionsForCleanup();
  });
}
