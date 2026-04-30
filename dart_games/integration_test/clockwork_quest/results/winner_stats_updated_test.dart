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
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester, numOpponents: 1);

    // Extra pumps to let _updatePlayerStats async API calls complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // _playVictoryMusic() calls getRandomMusicSource() → initialize();
    // resetServerState() resets _initialized to false, so true here proves
    // the results screen actually triggered music playback.
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
