import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Non-winning turn then edit claims final target and stats are updated',
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

    // P1 Turn 3: throw 3 misses (non-winning turn)
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // No winner yet
    expect(ProviderHelpers.reefRoyaleHasWinner(tester), isFalse);

    // Edit to claim 7th target (Bull): Bullseye + Outer Bull + Miss = 3 marks
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart1: 'Bull', dart2: '25', dart3: 'Miss');

    // Winner should now exist
    expect(ProviderHelpers.reefRoyaleHasWinner(tester), isTrue);

    // Click DARTS REMOVED to trigger game won flow
    await clickDartsRemoved(tester);

    // Wait for results screen navigation and stats update
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    expect(VictoryMusicService().isInitialized, isTrue);

    // Winner 'Player A': gamesPlayed=1, gamesWon=1
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(playerA, isNotNull);
    expect(playerA!.gamesPlayed, 1);
    expect(playerA.gamesWon, 1);
    expect(playerA.gameHistory.length, 1);
    expect(playerA.gameHistory.first.gameName, 'Reef Royale');

    // Loser 'Player B': gamesPlayed=1, gamesWon=0
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerB, isNotNull);
    expect(playerB!.gamesPlayed, 1);
    expect(playerB.gamesWon, 0);
    expect(playerB.gameHistory.length, 1);
    expect(playerB.gameHistory.first.gameName, 'Reef Royale');
  });
}
