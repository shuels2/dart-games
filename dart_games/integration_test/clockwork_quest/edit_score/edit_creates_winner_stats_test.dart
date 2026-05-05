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

  testWidgets('Edit score creates winner and updates stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        includeBullseye: true, playerNames: ['Player A', 'Player B']);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);

    // Programmatically set player to target 21 (bullseye)
    provider.currentGame!.currentTarget[playerId] = 21;
    provider.currentGame!.turnStartCurrentTarget[playerId] = 21;
    provider.currentGame!.turnStartLapsCompleted[playerId] = 0;
    provider.currentGame!.turnStartState = provider.currentGame!.state;
    provider.currentGame!.turnStartWinnerId = null;
    provider.currentGame!.turnStartCompletedTargets[playerId] = [];
    provider.notifyListeners();
    await PumpSequences.simpleUpdate(tester);

    // Throw 3 misses at bullseye target
    await throw3DartsAndWaitForTakeout(tester);
    expect(provider.hasWinner, isFalse);

    // Edit: change dart 1 to Bullseye hit — should create a winner
    await EditScoreHelpers.editScoreAndSave(tester, config, dart1: 'Bull');
    expect(provider.hasWinner, isTrue);

    // Confirm darts removed
    await clickDartsRemoved(tester);

    // Wait for results screen and stats API calls
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // Verify victory music was triggered
    expect(VictoryMusicService().isInitialized, isTrue);

    // Winner (Player A) should have gamesPlayed=1, gamesWon=1
    final winner = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(winner, isNotNull);
    expect(winner!.gamesPlayed, 1);
    expect(winner.gamesWon, 1);
    expect(winner.gameHistory.length, 1);
    expect(winner.gameHistory.first.gameName, 'Clockwork Quest');

    // Loser (Player B) should have gamesPlayed=1, gamesWon=0
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(loser, isNotNull);
    expect(loser!.gamesPlayed, 1);
    expect(loser.gamesWon, 0);
    expect(loser.gameHistory.length, 1);
    expect(loser.gameHistory.first.gameName, 'Clockwork Quest');
  });
}
