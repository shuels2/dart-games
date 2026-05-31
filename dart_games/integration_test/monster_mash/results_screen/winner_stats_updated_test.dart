import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results screen updates winner and loser stats on victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Low health for a fast game
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester);

    // Wait for results + let _updatePlayerStats async API calls complete
    await ResultsHelpers.pumpUntilResults(tester, config);
    // VictoryMusicService.initialize() + _updatePlayerStats() API call run async
    // AFTER the Play Again button mounts; pumpUntilResults only settles ~1s
    // post-button, which isn't enough under heavy parallel load.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    expect(VictoryMusicService().isInitialized, isTrue);

    // Winner should have gamesPlayed=1, gamesWon=1
    // completeGameToVictory makes the current first player win
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerA, isNotNull);
    expect(playerB, isNotNull);

    // Both players must have a game recorded
    expect(playerA!.gamesPlayed, 1);
    expect(playerB!.gamesPlayed, 1);
    expect(playerA.gameHistory.length, 1);
    expect(playerB.gameHistory.length, 1);
    expect(playerA.gameHistory.first.gameName, 'Monster Mash');
    expect(playerB.gameHistory.first.gameName, 'Monster Mash');

    // Exactly one of them must be the winner
    expect(playerA.gamesWon + playerB.gamesWon, 1);
  });
}
