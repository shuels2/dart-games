// integration_test/treasure_divide/gameplay/win_on_early_dart_test.dart
//
// Group A – Test 4: Win on dart 1 of the final turn.
// Setup: 7-round game, 2 players. Play rounds 0-5 normally (P1 always hits,
// P2 always misses). Round 6 = Bull (final round for 7-round sequence).
// P1 throws dart 1 = Bull (50) → score > 0 → BUT we need to check hasWinner
// only fires AFTER all 3 darts are thrown and takeout is done.
// Actually spec rule §5e says win fires AFTER the round completes for ALL
// players (turn-based game). So this test verifies the game ends on the final
// round's last takeout, not mid-dart.
// The "early" part: P1 hits on dart 1 of final turn (not needing darts 2+3
// to trigger anything — the turn end still requires 3 darts or skip).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Win fires after final round completes (Bull hit on dart 1)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // 7-round sequence: [20, 19, 18, AnyDouble, 17, AnyTriple, Bull]
    await setupAndStartGame(tester,
        numberOfRounds: 7,
        playerNames: ['WinP1', 'WinP2']);

    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p1Id = players[0].id;

    // ── Rounds 0-5: P1 hits 3, P2 misses 3 (each round) ──────────────────
    // Round 0: target=20, Round 1: target=19, Round 2: target=18
    // Round 3: target=AnyDouble(-1), Round 4: target=17, Round 5: target=AnyTriple(-2)
    for (int round = 0; round < 6; round++) {
      // P1 turn
      final roundIdxP1 = ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final targetP1 = ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIdxP1);
      if (targetP1 == -1) {
        await throwDartViaMock(tester, 1, multiplier: 'double');
        await throwDartViaMock(tester, 1, multiplier: 'double');
        await throwDartViaMock(tester, 1, multiplier: 'double');
      } else if (targetP1 == -2) {
        await throwDartViaMock(tester, 1, multiplier: 'triple');
        await throwDartViaMock(tester, 1, multiplier: 'triple');
        await throwDartViaMock(tester, 1, multiplier: 'triple');
      } else {
        await throwDartViaMock(tester, targetP1);
        await throwDartViaMock(tester, targetP1);
        await throwDartViaMock(tester, targetP1);
      }
      await simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // P2 turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await simulateTakeout(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    // ── Round 6 = Bull (final) ─────────────────────────────────────────────
    expect(ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester), equals(6),
        reason: '[DIAG win_early] Should be on final round (index 6) now');
    expect(ProviderHelpers.getTreasureDivideCurrentPlayerId(tester), equals(p1Id),
        reason: '[DIAG win_early] P1 should be active in final round');

    // Game should NOT have winner yet
    expect(ProviderHelpers.treasureDivideHasWinner(tester), isFalse,
        reason: '[DIAG win_early] Game should not have winner before final round completes');

    // P1 throws DART 1 = Bull (50)
    await throwDartViaMock(tester, 25, multiplier: 'bull');
    await throwDartViaMock(tester, 25, multiplier: 'bull');
    await throwDartViaMock(tester, 25, multiplier: 'bull');
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // P2 final round
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await simulateTakeout(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // ── After all 7 rounds complete: hasWinner = true ─────────────────────
    expect(ProviderHelpers.treasureDivideHasWinner(tester), isTrue,
        reason: '[DIAG win_early] hasWinner should be true after final round completes');

    // Poll for results screen
    for (int i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      if (find.byKey(TreasureDivideResultsKeys.playAgainButton).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byKey(TreasureDivideResultsKeys.playAgainButton), findsOneWidget,
        reason: '[DIAG win_early] Results screen (SAIL AGAIN) should be visible');
  });
}
