import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: editing dart 3 to winning value creates winner and stats',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Target=100, DF OFF: win by reaching 100
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Get to 80 over 2 turns: Turn1=60 (S20*3), Turn2=20 (S20)
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester);

    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester);

    // P1 at 80. Throw 3 non-winning darts: S1 + S1 + S1 = 83
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 1);

    // Edit dart 3: change S1 to D10 (20) → 80 + 1 + 1 + 20 = 102 >= 100 = WIN (DF OFF)
    await openEditScore(tester, config);
    await setDart3(tester, 'D10');
    await updateScore(tester);

    await tester.pump(const Duration(seconds: 1));

    // Diagnostic / early assertion (Monster Mash pattern):
    // Verify the edit-replay actually created a winner BEFORE we ask the
    // Results screen to mount and update stats. If this fails, the bug is in
    // editPlayerScore's win-trigger path for "lowercase-single → D10" replay.
    // If this passes but the gamesWon assertion below still fails, the bug
    // is in the post-win stats HTTP round-trip on the Results screen.
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason:
            'Edit-replay (s1+s1+D10 with preTurnScore=80, target=100, DF OFF) '
            'should have triggered _triggerWin and set hasWinner=true');

    // Click darts removed
    await clickDartsRemoved(tester);

    // Wait for results navigation (3s delayed) and stats update.
    // Pattern mirrors monster_mash/edit_score/edit_creates_winner_stats_test.dart
    // which uses 4s + pumps + 5s + pumps + fullRebuild.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);
    // Extra wait for server stats round-trip (batchAddPlayerHistory HTTP call)
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Should be on results screen
    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should be on results screen after winning via edit');

    // Winner stats should be updated. Use a unified diagnostic assertion so
    // the failure message reveals which dimension of the flow broke. The
    // early hasWinner assertion above proved edit-replay set the winner;
    // this remaining failure mode is in the Results-screen stats path
    // (HTTP round-trip in `batchUpdatePlayerStats`).
    final winner = ProviderHelpers.findPlayerByName(tester, 'Player A');
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player B');
    final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
    final game = provider.currentGame;

    expect(winner, isNotNull);
    expect(winner!.gamesWon, 1,
        reason:
            '[DIAG] winner.gamesWon expected 1, got ${winner.gamesWon}. '
            'Full state: '
            'winner={played:${winner.gamesPlayed}, '
            'won:${winner.gamesWon}, '
            'history:${winner.gameHistory.length}}, '
            'loser={played:${loser?.gamesPlayed}, '
            'won:${loser?.gamesWon}, '
            'history:${loser?.gameHistory.length}}, '
            'game={winnerId:${game?.winnerId}, '
            'state:${game?.state}, '
            'endedAt:${game?.endedAt != null ? "set" : "null"}, '
            'totalDartsThrown[A]:${game?.totalDartsThrown[winner.id]}, '
            'totalTurns[A]:${game?.totalTurns[winner.id]}}');
    expect(winner.gamesPlayed, 1,
        reason: 'Winner gamesPlayed should be 1');
  });
}
