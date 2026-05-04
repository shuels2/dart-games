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
      'Non-winning turn then edit creates winner and stats are updated',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config,
        healthMax: 10, playerNames: ['Player A', 'Player B']);

    // Get player IDs and opponent target
    final p1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p2 = players.firstWhere((p) => p.id != p1Id);
    final opponentTarget =
        ProviderHelpers.getMonsterMashPlayerTarget(tester, p2.id)!;

    // P1 Turn 1: deal 9 damage (3x Triple of opponent target)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);
    // Opponent should now have 1 HP: 10 - 3*3 = 1

    // P2 Turn: throw misses
    await completeTurnWithMisses(tester);

    // P1 Turn 2: throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // No winner yet
    expect(ProviderHelpers.monsterMashHasWinner(tester), isFalse);

    // Edit to kill: 1 damage from S(opponentTarget), opponent at 0 HP
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart1: 'S$opponentTarget');

    // Winner should now exist
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

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
    expect(playerA.gameHistory.first.gameName, 'Monster Mash');

    // Loser 'Player B': gamesPlayed=1, gamesWon=0
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerB, isNotNull);
    expect(playerB!.gamesPlayed, 1);
    expect(playerB.gamesWon, 0);
    expect(playerB.gameHistory.length, 1);
    expect(playerB.gameHistory.first.gameName, 'Monster Mash');
  });
}
