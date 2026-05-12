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

    // Winner stats should be updated. Look up players by ID — NOT by name —
    // because `GladiatorArenaProvider.startGame` picks a random starting
    // player (`rng.nextInt(playerIds.length)`), so "Player A" by name may
    // not be the one who threw darts in this run. `p1Id` was captured at
    // the start of the test as the active player who then threw every dart,
    // so by construction it's the winner; the other player in
    // `game.playerIds` is the loser.
    final game = ProviderHelpers.getGladiatorArenaProvider(tester).currentGame!;
    final loserId = game.playerIds.firstWhere((id) => id != p1Id);

    final winner = ProviderHelpers.findPlayerById(tester, p1Id);
    final loser = ProviderHelpers.findPlayerById(tester, loserId);

    expect(winner, isNotNull);
    expect(winner!.gamesWon, 1,
        reason: 'Winner (id=$p1Id) should have gamesWon=1');
    expect(winner.gamesPlayed, 1,
        reason: 'Winner should have gamesPlayed=1');
    expect(loser?.gamesWon ?? 0, 0,
        reason: 'Loser (id=$loserId) should have gamesWon=0');
    expect(loser?.gamesPlayed ?? 0, 1,
        reason: 'Loser should have gamesPlayed=1');
  });
}
