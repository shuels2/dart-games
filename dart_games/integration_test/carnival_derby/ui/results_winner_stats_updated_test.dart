import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results screen updates winner and loser stats on victory',
      (WidgetTester tester) async {
    await navigateToCarnivalDerbyMenu(tester);

    // Target 180 so Player1 can win in one turn (T20 x3 = 180)
    await setTargetScore(tester, 180);
    await UITestHelpers.addPlayer(tester, 'Player1', config);
    await UITestHelpers.addPlayer(tester, 'Player2', config);
    await startGame(tester);

    // Player1 wins in one turn
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await clickDartsRemoved(tester);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    // Extra pumps to let _updatePlayerStats async API calls complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    expect(VictoryMusicService().isInitialized, isTrue);

    // Winner (Player1) should have gamesPlayed=1, gamesWon=1
    final winner = ProviderHelpers.findPlayerByName(tester, 'Player1');
    expect(winner, isNotNull);
    expect(winner!.gamesPlayed, 1);
    expect(winner.gamesWon, 1);
    expect(winner.gameHistory.length, 1);
    expect(winner.gameHistory.first.gameName, 'Carnival Derby');

    // Loser (Player2) should have gamesPlayed=1, gamesWon=0
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player2');
    expect(loser, isNotNull);
    expect(loser!.gamesPlayed, 1);
    expect(loser.gamesWon, 0);
    expect(loser.gameHistory.length, 1);
    expect(loser.gameHistory.first.gameName, 'Carnival Derby');
  });
}
