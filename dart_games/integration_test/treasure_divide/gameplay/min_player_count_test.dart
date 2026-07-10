// integration_test/treasure_divide/gameplay/min_player_count_test.dart
//
// Group A – Test 1: Solo, 2 players (minimum). Both tiles render, both players
// complete one turn cycle, scores update correctly.
//
// NOTE: Uses throwDartDirect() (via provider.processDartThrow) instead of
// throwDartViaMock() because MockScoliaApiService omits score/multiplier/baseScore
// from the THROW_DETECTED payload, causing _handleDartThrow to read score=0 for
// every throw. throwDartDirect bypasses the event pipeline and delivers a
// correctly-scored dart to the provider.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 2-player Solo game — both tiles render and score after round 1',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        playerNames: ['MinP1', 'MinP2']);

    // ── Both players should be selected ───────────────────────────────────
    final players = ProviderHelpers.getSelectedPlayers(tester);
    expect(players.length, 2,
        reason: '[DIAG min_player] Should have exactly 2 players selected');

    // ── Both player names visible ──────────────────────────────────────────
    for (final p in players) {
      expect(find.textContaining(p.name), findsWidgets,
          reason: '[DIAG min_player] ${p.name} should appear in UI');
    }

    // ── Game is active ─────────────────────────────────────────────────────
    expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue,
        reason: '[DIAG min_player] Game should be active after start');

    // ── P1 turn: throw 3 hit darts on round-0 target (20) ─────────────────
    final target = getCurrentRoundTarget(tester);
    final p1Id = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester)!;

    // Use throwDartDirect so score is non-zero (mock payload bug workaround)
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await throwDartDirect(tester, target);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // P1 score should be 3×target (= 60 for default round-0 target of 20)
    final p1Score = ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id);
    expect(p1Score, greaterThan(0),
        reason: '[DIAG min_player] P1 score should be > 0 after 3 hits');

    // Turn should have advanced to P2
    final p2Id = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester)!;
    expect(p2Id, isNot(equals(p1Id)),
        reason: '[DIAG min_player] Turn should advance to P2 after P1 takeout');

    // ── P2 turn: throw 3 misses ────────────────────────────────────────────
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await throwMissDirect(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // After P2 wipeout in round 1, P2 score = 0 / 2 = 0 (half of 0 is still 0)
    final p2Score = ProviderHelpers.getTreasureDividePlayerTotal(tester, p2Id);
    expect(p2Score, equals(0),
        reason: '[DIAG min_player] P2 score should still be 0 after wipeout round 1');

    // Round 1 done — should be on round 2 now
    final roundIdx = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    expect(roundIdx, equals(1),
        reason: '[DIAG min_player] Should be on round index 1 after both players complete round 0');

    // Both player totals visible
    expect(ProviderHelpers.getTreasureDividePlayerTotal(tester, p1Id), greaterThan(0),
        reason: '[DIAG min_player] P1 total should be preserved after round advance');

    // Game still active
    expect(ProviderHelpers.isTreasureDivideGameActive(tester), isTrue,
        reason: '[DIAG min_player] Game should still be active after 1 round');

  });
}
