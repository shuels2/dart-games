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

  // MANDATORY: edit creates winner and updates stats.
  // Setup: Bo1, Easy, P1 has 2 cells in row 0 (programmatically set).
  // P1 throws 3 misses (no winner yet).
  // Edit dart 1 → S16 (row 0, col 2) → P1 wins row 0.
  // Verify hasWinner, click DARTS REMOVED, confirm results + stats.
  testWidgets('Edit Score: editing dart to win creates winner and updates stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Set up near-win state: P1 has row 0 cols 0 and 1
    await setupNearWinState(tester);

    // Throw 3 misses for P1 — no win yet (misses don't claim cells)
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.piratesGridHasWinner(tester), isFalse,
        reason: 'No winner after 3 misses');

    // Edit dart 1 from Miss → S{target at [0,2]} (Easy difficulty: any hit
    // claims). Targets are randomized per game, so read the actual number.
    final winningTarget =
        ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 2);
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'S$winningTarget');
    await updateScore(tester);

    expect(ProviderHelpers.piratesGridHasWinner(tester), isTrue,
        reason:
            'P1 should win after editing dart 1 to S$winningTarget (completes row 0)');

    // Tap DARTS REMOVED to navigate to results
    await clickDartsRemoved(tester);

    // Wait for results screen and stats updates
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    // MANDATORY: VictoryMusicService initialized
    expect(VictoryMusicService().isInitialized, isTrue,
        reason: 'VictoryMusicService should be initialized after results screen');

    // MANDATORY: Winner (Player A) stats updated
    final winner = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(winner, isNotNull);
    expect(winner!.gamesPlayed, 1, reason: 'Winner gamesPlayed should be 1');
    expect(winner.gamesWon, 1, reason: 'Winner gamesWon should be 1');
    expect(winner.gameHistory.length, 1,
        reason: 'Winner should have 1 game in history');
    expect(winner.gameHistory.first.gameName, "Pirate's Grid",
        reason: 'Game history entry should have correct game name');

    // MANDATORY: Loser (Player B) stats updated
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(loser, isNotNull);
    expect(loser!.gamesPlayed, 1, reason: 'Loser gamesPlayed should be 1');
    expect(loser.gamesWon, 0, reason: 'Loser gamesWon should be 0');
    expect(loser.gameHistory.length, 1,
        reason: 'Loser should have 1 game in history');
    expect(loser.gameHistory.first.gameName, "Pirate's Grid",
        reason: 'Loser game history entry should have correct game name');
  });
}
