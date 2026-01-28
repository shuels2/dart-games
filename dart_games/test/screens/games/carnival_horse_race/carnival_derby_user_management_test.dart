import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/horse_race_game.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Carnival Derby - User Management Integration', () {
    late PlayerProvider playerProvider;
    late HorseRaceProvider horseRaceProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      playerProvider = PlayerProvider();
      horseRaceProvider = HorseRaceProvider();
      await playerProvider.loadPlayers();
    });

    test('game records winner with duration', () async {
      // Create players
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');
      await playerProvider.savePlayer(player1);
      await playerProvider.savePlayer(player2);

      // Start game
      horseRaceProvider.startGame(
        [player1, player2],
        50,
        exactScoreMode: false,
      );

      final game = horseRaceProvider.currentGame!;
      expect(game.startedAt, isNotNull);

      // Simulate game play - player 1 wins
      while (game.state != GameState.finished) {
        horseRaceProvider.processDartThrow(20);
      }

      // Calculate duration
      final gameDuration = DateTime.now().difference(game.startedAt);

      // Update stats for winner
      await playerProvider.updatePlayerStats(
        game.winnerId!,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: gameDuration,
      );

      // Update stats for loser
      final loserId = game.playerIds.firstWhere((id) => id != game.winnerId);
      await playerProvider.updatePlayerStats(loserId, won: false);

      // Verify winner has game history
      final winner = playerProvider.getPlayerById(game.winnerId!);
      expect(winner!.gamesPlayed, 1);
      expect(winner.gamesWon, 1);
      expect(winner.gameHistory.length, 1);
      expect(winner.gameHistory.first.gameName, 'Carnival Derby');
      expect(winner.gameHistory.first.duration, isNotNull);

      // Verify loser has no game history but stats updated
      final loser = playerProvider.getPlayerById(loserId);
      expect(loser!.gamesPlayed, 1);
      expect(loser.gamesWon, 0);
      expect(loser.gameHistory, isEmpty);
    });

    test('multiple games accumulate history correctly', () async {
      final player = Player.create(name: 'Multi-Game Player');
      await playerProvider.savePlayer(player);

      // Play 3 games
      for (int i = 0; i < 3; i++) {
        horseRaceProvider.startGame([player], 50, exactScoreMode: false);

        // Win the game
        while (horseRaceProvider.currentGame!.state != GameState.finished) {
          horseRaceProvider.processDartThrow(20);
        }

        final game = horseRaceProvider.currentGame!;
        final duration = DateTime.now().difference(game.startedAt);

        await playerProvider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Carnival Derby',
          gameDuration: duration,
        );

        horseRaceProvider.clearGame();
      }

      // Verify accumulated stats
      final updated = playerProvider.getPlayerById(player.id);
      expect(updated!.gamesPlayed, 3);
      expect(updated.gamesWon, 3);
      expect(updated.gameHistory.length, 3);

      // Verify all entries are Carnival Derby
      expect(
        updated.gameHistory.every((e) => e.gameName == 'Carnival Derby'),
        isTrue,
      );
    });

    test('game duration is reasonable', () async {
      final player = Player.create(name: 'Timed Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 50, exactScoreMode: false);
      final startTime = horseRaceProvider.currentGame!.startedAt;

      // Simulate quick game
      while (horseRaceProvider.currentGame!.state != GameState.finished) {
        horseRaceProvider.processDartThrow(25);
      }

      final endTime = DateTime.now();
      final actualDuration = endTime.difference(startTime);

      await playerProvider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: actualDuration,
      );

      final updated = playerProvider.getPlayerById(player.id);
      final recordedDuration = updated!.gameHistory.first.duration;

      // Duration should be very short for this test (can be 0 in fast tests)
      expect(recordedDuration.inSeconds, lessThan(5));
      expect(recordedDuration.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('win stats persist across provider reload', () async {
      final player = Player.create(name: 'Persistent Player');
      await playerProvider.savePlayer(player);

      // Play and win a game
      horseRaceProvider.startGame([player], 50, exactScoreMode: false);

      while (horseRaceProvider.currentGame!.state != GameState.finished) {
        horseRaceProvider.processDartThrow(20);
      }

      final game = horseRaceProvider.currentGame!;
      final duration = DateTime.now().difference(game.startedAt);

      await playerProvider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: duration,
      );

      // Create new provider to simulate app restart
      final newProvider = PlayerProvider();
      await newProvider.loadPlayers();

      final loaded = newProvider.getPlayerById(player.id);
      expect(loaded, isNotNull);
      expect(loaded!.gamesPlayed, 1);
      expect(loaded.gamesWon, 1);
      expect(loaded.gameHistory.length, 1);
      expect(loaded.gameHistory.first.gameName, 'Carnival Derby');
    });

    test('multiple players in same game get correct stats', () async {
      final player1 = Player.create(name: 'Winner');
      final player2 = Player.create(name: 'Runner-up');
      final player3 = Player.create(name: 'Third Place');

      await playerProvider.savePlayer(player1);
      await playerProvider.savePlayer(player2);
      await playerProvider.savePlayer(player3);

      horseRaceProvider.startGame(
        [player1, player2, player3],
        50,
        exactScoreMode: false,
      );

      // Player 1 wins
      while (horseRaceProvider.currentGame!.state != GameState.finished) {
        // Ensure player 1 gets enough points to win
        final currentPlayer = horseRaceProvider.currentGame!.playerIds[
            horseRaceProvider.currentGame!.currentPlayerIndex];

        if (currentPlayer == player1.id) {
          horseRaceProvider.processDartThrow(25);
        } else {
          horseRaceProvider.processDartThrow(5);
        }
      }

      final game = horseRaceProvider.currentGame!;
      final duration = DateTime.now().difference(game.startedAt);

      // Update all player stats
      for (final playerId in game.playerIds) {
        final isWinner = playerId == game.winnerId;
        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: isWinner ? 'Carnival Derby' : null,
          gameDuration: isWinner ? duration : null,
        );
      }

      // Verify winner
      final winner = playerProvider.getPlayerById(game.winnerId!);
      expect(winner!.gamesPlayed, 1);
      expect(winner.gamesWon, 1);
      expect(winner.gameHistory.length, 1);

      // Verify losers
      for (final playerId in game.playerIds) {
        if (playerId != game.winnerId) {
          final loser = playerProvider.getPlayerById(playerId);
          expect(loser!.gamesPlayed, 1);
          expect(loser.gamesWon, 0);
          expect(loser.gameHistory, isEmpty);
        }
      }
    });

    test('exact score mode games record duration', () async {
      final player = Player.create(name: 'Exact Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 50, exactScoreMode: true);

      // Win with exact score
      while (horseRaceProvider.currentGame!.state != GameState.finished) {
        final currentScore =
            horseRaceProvider.currentGame!.scores[player.id] ?? 0;
        final remaining = 50 - currentScore;

        if (remaining <= 25) {
          horseRaceProvider.processDartThrow(remaining);
        } else {
          horseRaceProvider.processDartThrow(20);
        }
      }

      final game = horseRaceProvider.currentGame!;
      final duration = DateTime.now().difference(game.startedAt);

      await playerProvider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: duration,
      );

      final updated = playerProvider.getPlayerById(player.id);
      expect(updated!.gameHistory.length, 1);
      expect(updated.gameHistory.first.duration, isNotNull);
    });

    test('game history stores unique IDs', () async {
      final player = Player.create(name: 'Multi-Win Player');
      await playerProvider.savePlayer(player);

      final historyIds = <String>[];

      // Play 3 games
      for (int i = 0; i < 3; i++) {
        horseRaceProvider.startGame([player], 50, exactScoreMode: false);

        while (horseRaceProvider.currentGame!.state != GameState.finished) {
          horseRaceProvider.processDartThrow(20);
        }

        final duration =
            DateTime.now().difference(horseRaceProvider.currentGame!.startedAt);

        await playerProvider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Carnival Derby',
          gameDuration: duration,
        );

        horseRaceProvider.clearGame();
      }

      final updated = playerProvider.getPlayerById(player.id);

      // Collect all history entry IDs
      for (final entry in updated!.gameHistory) {
        expect(historyIds.contains(entry.id), isFalse);
        historyIds.add(entry.id);
      }

      expect(historyIds.length, 3);
    });

    test('provider methods calculate stats correctly from history', () async {
      final player = Player.create(name: 'Stats Test');
      await playerProvider.savePlayer(player);

      // Play 3 games with different durations
      final durations = [
        const Duration(minutes: 3),
        const Duration(minutes: 5),
        const Duration(minutes: 4),
      ];

      for (final duration in durations) {
        horseRaceProvider.startGame([player], 50, exactScoreMode: false);

        while (horseRaceProvider.currentGame!.state != GameState.finished) {
          horseRaceProvider.processDartThrow(20);
        }

        await playerProvider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Carnival Derby',
          gameDuration: duration,
        );

        horseRaceProvider.clearGame();
      }

      // Test total play time
      final totalTime = playerProvider.getPlayerTotalPlayTime(player.id);
      expect(totalTime.inMinutes, 12); // 3 + 5 + 4

      // Test average duration
      final avgDuration = playerProvider.getPlayerAverageGameDuration(
        player.id,
        'Carnival Derby',
      );
      expect(avgDuration, isNotNull);
      expect(avgDuration!.inMinutes, 4); // (3 + 5 + 4) / 3 = 4

      // Test history retrieval
      final history = playerProvider.getPlayerHistory(player.id);
      expect(history.length, 3);

      final derbyHistory = playerProvider.getPlayerHistoryForGame(
        player.id,
        'Carnival Derby',
      );
      expect(derbyHistory.length, 3);
    });
  });
}
