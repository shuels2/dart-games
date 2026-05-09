import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/models/pirates_grid_game.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

// Bo5 win threshold: (5 ~/ 2) + 1 = 3 rounds.
// P1 wins rounds 1, 2, 3 → matchWinnerId set, state=finished.
// Strategy per round (Easy): P1 claims row 0 cells [0,0], [0,1], [0,2]
//   in one turn (3 darts).  P2 throws 3 misses first (because P2 goes
//   second) — but since P1 has 3 darts per turn, P1 can claim all three
//   cells in a single turn before P2 throws.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Bo5 — P1 wins 3 consecutive rounds to claim the match',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '5',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Round tracker should be visible for Bo5 (non-Bo1 mode shows tracker)
    expect(ElementFinders.getPiratesGridRoundTracker(), findsOneWidget,
        reason: 'Round tracker should be visible for Bo5');

    // ── Round 1: P1 wins with row 0 ────────────────────────────────────────

    // Read CURRENT cell targets (grid is reshuffled each round)
    int t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    int t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    int t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);

    // P1 claims all three row-0 cells in one turn → wins round 1
    await throwDartViaMock(tester, t00);
    await throwDartViaMock(tester, t01);
    await throwDartViaMock(tester, t02);

    expect(provider.currentGame!.roundsWon[p1Id], 1,
        reason: 'P1 should have 1 round win after winning round 1');
    expect(provider.currentGame!.matchWinnerId, isNull,
        reason: 'Match should NOT be decided yet (need 3 wins for Bo5)');
    expect(provider.currentGame!.state, isNot(GameState.finished),
        reason: 'Match should still be in progress after round 1');

    // DARTS REMOVED → triggers round transition
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Should now be in round 2
    expect(provider.currentGame!.currentRound, 2,
        reason: 'Should now be in round 2');

    // Grid should be fully reset
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        expect(
            ProviderHelpers.getPiratesGridCellClaimedBy(tester, r, c), isNull,
            reason: 'Cell [$r,$c] should be empty at start of round 2');
      }
    }

    // ── Round 2: P1 wins again ─────────────────────────────────────────────

    // P2 starts round 2 (starting player alternates).
    // P2 throws 3 misses, then P1 wins with row 0.
    final p2StartsR2 =
        provider.currentGame!.currentRoundStartingPlayerIndex == 1;

    if (p2StartsR2) {
      // P2 goes first this round — let P2 miss all 3 darts
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();
    }

    // Now it is P1's turn — claim row 0
    t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);

    await throwDartViaMock(tester, t00);
    await throwDartViaMock(tester, t01);
    await throwDartViaMock(tester, t02);

    expect(provider.currentGame!.roundsWon[p1Id], 2,
        reason: 'P1 should have 2 round wins after winning round 2');
    expect(provider.currentGame!.matchWinnerId, isNull,
        reason: 'Match should NOT be decided yet (need 3 wins for Bo5)');

    // DARTS REMOVED → round transition
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    expect(provider.currentGame!.currentRound, 3,
        reason: 'Should now be in round 3');

    // Grid reset again
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        expect(
            ProviderHelpers.getPiratesGridCellClaimedBy(tester, r, c), isNull,
            reason: 'Cell [$r,$c] should be empty at start of round 3');
      }
    }

    // ── Round 3: P1 wins → clinches match (3 wins = Bo5 threshold) ────────

    final p1StartsR3 =
        provider.currentGame!.currentRoundStartingPlayerIndex == 0;

    if (!p1StartsR3) {
      // P2 goes first — let P2 miss
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await tester.pump();
    }

    // P1 claims row 0 again
    t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    t01 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);
    t02 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);

    await throwDartViaMock(tester, t00);
    await throwDartViaMock(tester, t01);
    await throwDartViaMock(tester, t02);

    // After winning round 3, P1 has 3 wins → match is decided immediately
    expect(provider.currentGame!.roundsWon[p1Id], 3,
        reason: 'P1 should have 3 round wins after winning round 3');
    expect(provider.currentGame!.matchWinnerId, p1Id,
        reason: 'P1 should be the match winner after 3 round wins in Bo5');
    expect(provider.currentGame!.state, GameState.finished,
        reason: 'Game state should be finished after P1 wins the match');
    expect(provider.currentGame!.roundsWon[p2Id], 0,
        reason: 'P2 should have 0 round wins');

    // DARTS REMOVED → navigate to results screen
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    // Results screen should be shown
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason:
            'Results screen should appear after P1 wins the Bo5 match');
  });
}
