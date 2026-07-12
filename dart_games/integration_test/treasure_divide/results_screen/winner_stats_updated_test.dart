// integration_test/treasure_divide/results_screen/winner_stats_updated_test.dart
//
// Results-3 — Player stats are updated after a Treasure Divide game completes.
// MANDATORY: Winner: gamesPlayed=1, gamesWon=1. Loser: gamesPlayed=1, gamesWon=0.
// Both have gameHistory with 'Treasure Divide' entry.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: winner and loser stats updated after Treasure Divide victory',
      (WidgetTester tester) async {
    // resetServerState calls VictoryMusicService().resetForTesting()
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 7, playerNames: ['StatsP1', 'StatsP2']);

    await playGameToResultsScreen(tester);

    // VictoryMusicService.initialize() + _updatePlayerStats() run async
    // AFTER the Play Again button mounts; pumpUntilResults only settles
    // ~1s post-button, which isn't enough under load.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    // MANDATORY: VictoryMusicService should be initialized
    expect(VictoryMusicService().isInitialized, isTrue,
        reason:
            '[DIAG td_results_stats] VictoryMusicService should be initialized '
            'after results screen loads');

    // Both players should have gamesPlayed=1
    final p1 = ProviderHelpers.findPlayerByName(tester, 'StatsP1');
    expect(p1, isNotNull,
        reason: '[DIAG td_results_stats] StatsP1 not found in provider');
    expect(p1!.gamesPlayed, 1,
        reason: '[DIAG td_results_stats] StatsP1 gamesPlayed should be 1');

    final p2 = ProviderHelpers.findPlayerByName(tester, 'StatsP2');
    expect(p2, isNotNull,
        reason: '[DIAG td_results_stats] StatsP2 not found in provider');
    expect(p2!.gamesPlayed, 1,
        reason: '[DIAG td_results_stats] StatsP2 gamesPlayed should be 1');

    // Determine winner from provider
    final winnerIds = ProviderHelpers.getTreasureDivideWinnerIds(tester);
    expect(winnerIds.isNotEmpty, isTrue,
        reason: '[DIAG td_results_stats] winnerIds should not be empty');
    final winnerId = winnerIds.first;

    // Winner has gamesWon=1, loser has gamesWon=0
    if (p1.id == winnerId) {
      expect(p1.gamesWon, 1,
          reason: '[DIAG td_results_stats] StatsP1 (winner) gamesWon should be 1');
      expect(p2.gamesWon, 0,
          reason: '[DIAG td_results_stats] StatsP2 (loser) gamesWon should be 0');
    } else {
      expect(p2.gamesWon, 1,
          reason: '[DIAG td_results_stats] StatsP2 (winner) gamesWon should be 1');
      expect(p1.gamesWon, 0,
          reason: '[DIAG td_results_stats] StatsP1 (loser) gamesWon should be 0');
    }

    // Both players have 1 gameHistory entry with correct game name
    expect(p1.gameHistory.length, 1,
        reason: '[DIAG td_results_stats] StatsP1 should have 1 game in history');
    expect(p2.gameHistory.length, 1,
        reason: '[DIAG td_results_stats] StatsP2 should have 1 game in history');
    expect(p1.gameHistory.first.gameName, 'Treasure Divide',
        reason:
            '[DIAG td_results_stats] StatsP1 game history entry should be "Treasure Divide"');
    expect(p2.gameHistory.first.gameName, 'Treasure Divide',
        reason:
            '[DIAG td_results_stats] StatsP2 game history entry should be "Treasure Divide"');
  });
}
