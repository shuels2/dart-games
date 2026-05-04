import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../shared/ui_test_helpers.dart';
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

    // P1 Turn 2: throw S(opponentTarget) + 2 misses (1 damage = kills)
    await throwDartViaMock(tester, opponentTarget);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Winner should exist
    expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

    // Edit to remove winner: change dart1 to S1 (not anyone's target), rest Miss
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart1: 'S1', dart2: 'Miss', dart3: 'Miss');

    // Winner should be removed
    expect(ProviderHelpers.monsterMashHasWinner(tester), isFalse);

    // Click DARTS REMOVED to continue
    await clickDartsRemoved(tester);

    // Game should still be active
    expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);

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
