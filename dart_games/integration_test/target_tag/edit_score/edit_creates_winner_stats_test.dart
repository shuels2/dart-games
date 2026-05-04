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
      'Edit Score: non-winning turn edited to eliminate opponent updates stats',
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

    // P1 (tagged in): throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.targetTagHasWinner(tester), isFalse);

    // Edit to eliminate P2: change all 3 darts to P2's target
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart1: 'S$p2Target', dart2: 'S$p2Target', dart3: 'S$p2Target');

    expect(ProviderHelpers.targetTagHasWinner(tester), isTrue);

    await clickDartsRemoved(tester);

    // Wait for victory animations and stats API calls
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

    // Winner (Player A) should have gamesPlayed=1, gamesWon=1
    final winner = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(winner, isNotNull);
    expect(winner!.gamesPlayed, 1);
    expect(winner.gamesWon, 1);
    expect(winner.gameHistory.length, 1);
    expect(winner.gameHistory.first.gameName, 'Target Tag');

    // Loser (Player B) should have gamesPlayed=1, gamesWon=0
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(loser, isNotNull);
    expect(loser!.gamesPlayed, 1);
    expect(loser.gamesWon, 0);
    expect(loser.gameHistory.length, 1);
    expect(loser.gameHistory.first.gameName, 'Target Tag');
  });
}
