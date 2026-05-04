import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: winning turn edited to remove winner does not update stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        shieldMax: 3, playerNames: ['Player A', 'Player B']);

    // Get player IDs and targets
    final p1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester)!;
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final p2Id = players.firstWhere((p) => p.id != p1Id).id;
    final p1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, p1Id)!;
    final p2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, p2Id)!;

    // P1 builds shields (gets tagged in): throw 3x own target
    await throwDartViaMock(tester, p1Target);
    await throwDartViaMock(tester, p1Target);
    await throwDartViaMock(tester, p1Target);
    await clickDartsRemoved(tester);

    // P2 throws misses
    await completeTurnWithMisses(tester);

    // P1 (tagged in): throw 3x P2's target (eliminates P2)
    await throwDartViaMock(tester, p2Target);
    await throwDartViaMock(tester, p2Target);
    await throwDartViaMock(tester, p2Target);

    expect(ProviderHelpers.targetTagHasWinner(tester), isTrue);

    // Edit to remove win: change all 3 darts to Miss
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart1: 'Miss', dart2: 'Miss', dart3: 'Miss');

    expect(ProviderHelpers.targetTagHasWinner(tester), isFalse);

    await clickDartsRemoved(tester);

    // Game should continue
    expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);

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
