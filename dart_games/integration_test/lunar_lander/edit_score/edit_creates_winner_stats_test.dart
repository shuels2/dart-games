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
        playerNames: ['Player A', 'Player B']);

    final playerId =
        ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getLunarLanderProvider(tester);

    // Programmatically set altitude low so a single S10 can win
    provider.currentGame!.currentAltitudes[playerId] = 10;
    provider.currentGame!.turnStartAltitude[playerId] = 10;
    provider.currentGame!.turnStartState = provider.currentGame!.state;
    provider.currentGame!.turnStartWinnerId = null;
    provider.notifyListeners();
    await PumpSequences.simpleUpdate(tester);

    // Throw 3 misses (altitude stays at 10)
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.lunarLanderHasWinner(tester), isFalse);

    // Edit: change dart 1 to S10 — should create a winner (altitude 10 - 10 = 0)
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'S10');
    await updateScore(tester);

    expect(ProviderHelpers.lunarLanderHasWinner(tester), isTrue);

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
    expect(winner.gameHistory.first.gameName, 'Lunar Lander');

    // Loser (Player B) should have gamesPlayed=1, gamesWon=0
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(loser, isNotNull);
    expect(loser!.gamesPlayed, 1);
    expect(loser.gamesWon, 0);
    expect(loser.gameHistory.length, 1);
    expect(loser.gameHistory.first.gameName, 'Lunar Lander');
  });
}
