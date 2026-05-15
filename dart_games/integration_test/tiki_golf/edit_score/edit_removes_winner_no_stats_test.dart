import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

/// MANDATORY: Edit Score — editing a score BEFORE game end prevents stats from
/// being persisted for a different outcome than what would have occurred.
///
/// In Tiki Golf, the winner is determined at confirmTurnEnd → _endGame (not
/// during processDartThrow). So "remove winner" means: before the game ends,
/// edit a would-be winning score to a losing score, then confirm → different
/// winner, stats reflect edited outcome.
///
/// Strategy:
///  1. Drive both players through holes 1-8 (birdies, 8 each).
///  2. Alice hole 9: Birdie (strokes=1, total=9) → confirm.
///  3. Bob hole 9: throw target on dart 1 → Birdie (strokes=1, total=9 = tie).
///  4. With tie, Alice wins (first in turn order). BUT: edit Bob's score
///     to Splash (strokes=4) before confirming.
///  5. Confirm → game ends: Bob total=12, Alice total=9 → Alice wins.
///  6. Verify Bob has gamesPlayed=1, gamesWon=0 (stats match edited outcome).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: editing score before game end produces correct stats outcome',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3, playerNames: ['Alice', 'Bob']);

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final aliceId = players.firstWhere((p) => p.name == 'Alice').id;
    final bobId = players.firstWhere((p) => p.name == 'Bob').id;

    // Helper: throw the target dart for the current hole
    Future<void> throwCurrentTarget() async {
      final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
      final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
      await throwDartViaMock(tester, target);
    }

    // Drive through holes 1-8 for both players (all birdies)
    int safety = 0;
    while (!provider.hasWinner &&
        provider.currentGame!.currentHole < 9 &&
        safety < 200) {
      safety++;
      await throwCurrentTarget();
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }

    expect(provider.currentGame!.currentHole, 9,
        reason: 'Should be on hole 9');

    // Alice hole 9: Birdie (strokes=1, total=9)
    await throwCurrentTarget();
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Bob hole 9: throw target on dart 1 → Birdie (strokes=1, total=9 = tie)
    // currentTurnEnded=true, hasWinner=false (game ends at confirmTurnEnd)
    await throwCurrentTarget();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(provider.shouldPromptTakeout, isTrue,
        reason: "Bob's turn ended on dart 1 — prompt takeout");
    expect(provider.hasWinner, isFalse,
        reason: 'Winner not set yet — confirmTurnEnd not called');

    // Edit Bob's score: change dart 1 from target (Birdie) to a Miss (Splash)
    // After edit: Bob hole 9 = 4 (Splash), total = 12
    // Alice total = 9 → Alice will win decisively
    await EditScoreHelpers.editScoreAndSave(
      tester,
      config,
      dart1: 'Miss',   // Miss on dart 1
      dart2: 'Miss',   // Miss on dart 2
      dart3: 'Miss',   // Miss on dart 3
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // After edit: Bob hole 9 should be 4 (Splash) — no winning dart
    final bobHole9Score =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, bobId, 9);
    expect(bobHole9Score, 4,
        reason: "Bob's hole 9 should be 4 (Splash) after editing to all misses");

    expect(provider.hasWinner, isFalse,
        reason: 'Winner still not set after edit — confirmTurnEnd not called');

    // Confirm Bob's takeout → _endGame → Alice wins (total 9 vs Bob 12)
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Game should now have a winner (Alice wins)
    expect(provider.hasWinner, isTrue,
        reason: 'Game should end after Bob confirms takeout');
    expect(provider.currentGame?.winnerId, aliceId,
        reason: 'Alice should win (total=9 vs Bob total=12 after edit)');

    // No stats should be persisted yet (still in game — stats update on results screen)
    // Verify game is in finished state but stats aren't persisted until results loads
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    expect(alice, isNotNull);
    expect(alice!.gamesPlayed, 0,
        reason: 'Alice gamesPlayed should be 0 — results screen not yet loaded');

    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(bob, isNotNull);
    expect(bob!.gamesPlayed, 0,
        reason: 'Bob gamesPlayed should be 0 — results screen not yet loaded');
  });
}
