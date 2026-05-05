import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Winning turn then edit removes winner and stats are NOT updated',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // P1 Turn 1: claim 20, 19, 18
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 19, multiplier: 'triple');
    await throwDartViaMock(tester, 18, multiplier: 'triple');

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Click DARTS REMOVED
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    final dartsRemovedButton2 = find.text('DARTS REMOVED');
    if (dartsRemovedButton2.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton2.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P1 Turn 2: claim 17, 16, 15
    await throwDartViaMock(tester, 17, multiplier: 'triple');
    await throwDartViaMock(tester, 16, multiplier: 'triple');
    await throwDartViaMock(tester, 15, multiplier: 'triple');

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    final dartsRemovedButton3 = find.text('DARTS REMOVED');
    if (dartsRemovedButton3.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton3.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    final dartsRemovedButton4 = find.text('DARTS REMOVED');
    if (dartsRemovedButton4.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton4.first);
      await PumpSequences.simpleUpdate(tester);
    }

    // P1 now has 6/7 targets claimed — verify
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
        isTrue);
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 15),
        isTrue);

    // P1 Turn 3: throw Miss + 25 + Bull (wins on dart 3, all darts processed)
    // 25 gives 1 mark, Bull gives 2 marks = 3 total on dart 3
    await throwMissViaMock(tester);
    await throwOuterBullViaMock(tester);
    await throwBullseyeViaMock(tester);

    expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

    // Edit dart 3: Bull → S1 (not a RR target, removes marks, removes winner)
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart3: 'S1');

    // Winner should be removed
    expect(ProviderHelpers.reefRoyaleHasWinner(tester), isFalse);

    // Click DARTS REMOVED to continue
    await clickDartsRemoved(tester);

    // Game should still be active
    expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);

    // Neither player should have stats updated
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(playerA, isNotNull);
    expect(playerA!.gamesPlayed, 0);
    expect(playerA.gamesWon, 0);
    expect(playerA.gameHistory.isEmpty, isTrue);

    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerB, isNotNull);
    expect(playerB!.gamesPlayed, 0);
    expect(playerB.gamesWon, 0);
    expect(playerB.gameHistory.isEmpty, isTrue);
  });
}
