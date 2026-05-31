import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

/// MANDATORY: Player stats are updated after a game completes.
/// Winner: gamesPlayed=1, gamesWon=1. Losers: gamesWon=0.
/// Also verifies VictoryMusicService is initialized after results screen loads.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: winner and loser stats updated on victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3, playerNames: ['Alice', 'Bob']);

    await driveToCompletion(tester, playerNames: ['Alice', 'Bob']);

    // Wait for results + let _updatePlayerStats async API calls complete
    await ResultsHelpers.pumpUntilResults(tester, config);
    // VictoryMusicService.initialize() + _updatePlayerStats() API call run async
    // AFTER the Play Again button mounts; pumpUntilResults only settles ~1s
    // post-button, which isn't enough under heavy parallel load.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    // MANDATORY: VictoryMusicService should be initialized
    expect(VictoryMusicService().isInitialized, isTrue,
        reason:
            'VictoryMusicService should be initialized after results screen loads');

    // MANDATORY: Winner (lowest score) should have gamesPlayed=1, gamesWon=1.
    // driveToCompletion gives both birdies — winner determined by tiebreak
    // or first-player advantage per spec. We check both have gamesPlayed=1.
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    expect(alice, isNotNull, reason: 'Alice should exist in provider');
    expect(alice!.gamesPlayed, 1, reason: 'Alice gamesPlayed should be 1');

    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(bob, isNotNull, reason: 'Bob should exist in provider');
    expect(bob!.gamesPlayed, 1, reason: 'Bob gamesPlayed should be 1');

    // Exactly one of them should be the winner
    final winnerId = ProviderHelpers.getTikiGolfWinnerId(tester);
    expect(winnerId, isNotNull, reason: 'Provider should have a winnerId');

    // Winner has gamesWon=1, loser has gamesWon=0
    if (alice.id == winnerId) {
      expect(alice.gamesWon, 1,
          reason: 'Alice (winner) should have gamesWon=1');
      expect(bob.gamesWon, 0,
          reason: 'Bob (loser) should have gamesWon=0');
    } else {
      expect(bob.gamesWon, 1,
          reason: 'Bob (winner) should have gamesWon=1');
      expect(alice.gamesWon, 0,
          reason: 'Alice (loser) should have gamesWon=0');
    }

    // Both have game history
    expect(alice.gameHistory.length, 1,
        reason: 'Alice should have 1 entry in gameHistory');
    expect(bob.gameHistory.length, 1,
        reason: 'Bob should have 1 entry in gameHistory');

    expect(alice.gameHistory.first.gameName, 'Tiki Golf',
        reason: 'Game history entry should have correct game name');
    expect(bob.gameHistory.first.gameName, 'Tiki Golf',
        reason: 'Game history entry should have correct game name');
  });
}
