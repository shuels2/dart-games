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

      // Update stats for all players (both winners and losers get duration)
      for (final playerId in game.playerIds) {
        final isWinner = playerId == game.winnerId;
        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: 'Carnival Derby',
          gameDuration: gameDuration,
        );
      }

      // Reload players from storage
      await playerProvider.loadPlayers();

      // Verify winner has game history
      final winner = playerProvider.getPlayerById(game.winnerId!);
      expect(winner!.gamesPlayed, 1);
      expect(winner.gamesWon, 1);
      expect(winner.gameHistory.length, 1);
      expect(winner.gameHistory.first.gameName, 'Carnival Derby');
      expect(winner.gameHistory.first.duration, isNotNull);

      // Verify loser also has game history with duration
      final loserId = game.playerIds.firstWhere((id) => id != game.winnerId);
      final loser = playerProvider.getPlayerById(loserId);
      expect(loser!.gamesPlayed, 1);
      expect(loser.gamesWon, 0);
      expect(loser.gameHistory.length, 1);
      expect(loser.gameHistory.first.gameName, 'Carnival Derby');
      expect(loser.gameHistory.first.duration, isNotNull);

      // Verify both have same duration
      expect(winner.gameHistory.first.duration, loser.gameHistory.first.duration);
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

      // Update all player stats (both winners and losers get duration)
      for (final playerId in game.playerIds) {
        final isWinner = playerId == game.winnerId;
        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: 'Carnival Derby',
          gameDuration: duration,
        );
      }

      // Reload players from storage
      await playerProvider.loadPlayers();

      // Verify winner
      final winner = playerProvider.getPlayerById(game.winnerId!);
      expect(winner!.gamesPlayed, 1);
      expect(winner.gamesWon, 1);
      expect(winner.gameHistory.length, 1);
      expect(winner.gameHistory.first.gameName, 'Carnival Derby');
      expect(winner.gameHistory.first.duration, isNotNull);

      // Verify losers also have game history with duration
      for (final playerId in game.playerIds) {
        if (playerId != game.winnerId) {
          final loser = playerProvider.getPlayerById(playerId);
          expect(loser!.gamesPlayed, 1);
          expect(loser.gamesWon, 0);
          expect(loser.gameHistory.length, 1);
          expect(loser.gameHistory.first.gameName, 'Carnival Derby');
          expect(loser.gameHistory.first.duration, isNotNull);

          // Verify loser has same duration as winner
          expect(loser.gameHistory.first.duration, winner.gameHistory.first.duration);
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

    test('max 8 players can be selected for Carnival Derby', () async {
      // Create 10 players
      final players = <Player>[];
      for (int i = 1; i <= 10; i++) {
        final player = Player.create(name: 'Player $i');
        await playerProvider.savePlayer(player);
        players.add(player);
      }

      // Select first 7 players (under max of 8)
      for (int i = 0; i < 7; i++) {
        playerProvider.selectPlayer(players[i], maxPlayers: 8);
      }

      expect(playerProvider.selectedPlayers.length, 7);

      // Select 8th player - should succeed
      playerProvider.selectPlayer(players[7], maxPlayers: 8);
      expect(playerProvider.selectedPlayers.length, 8);

      // Attempt to select 9th player - should fail (max reached)
      playerProvider.selectPlayer(players[8], maxPlayers: 8);
      expect(playerProvider.selectedPlayers.length, 8);
      expect(
        playerProvider.selectedPlayers.any((p) => p.id == players[8].id),
        isFalse,
      );

      // Deselect one player
      playerProvider.deselectPlayer(players[7].id);
      expect(playerProvider.selectedPlayers.length, 7);

      // Now selecting 9th player should succeed (under max again)
      playerProvider.selectPlayer(players[8], maxPlayers: 8);
      expect(playerProvider.selectedPlayers.length, 8);
      expect(
        playerProvider.selectedPlayers.any((p) => p.id == players[8].id),
        isTrue,
      );
    });

    test('skip turn records misses and advances turn', () async {
      // Create players
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');
      final player3 = Player.create(name: 'Player 3');
      await playerProvider.savePlayer(player1);
      await playerProvider.savePlayer(player2);
      await playerProvider.savePlayer(player3);

      // Start game
      horseRaceProvider.startGame([player1, player2, player3], 50, exactScoreMode: false);

      // Player 1 skips turn (no darts thrown)
      expect(horseRaceProvider.getCurrentPlayerId(), player1.id);
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 0);

      horseRaceProvider.skipTurn();

      // Verify 3 misses recorded
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 3);
      final dartScores = horseRaceProvider.getCurrentTurnDartScores(player1.id);
      expect(dartScores.length, 3);
      expect(dartScores[0], 'Miss');
      expect(dartScores[1], 'Miss');
      expect(dartScores[2], 'Miss');

      // Verify score is still 0
      expect(horseRaceProvider.getPlayerScore(player1.id), 0);

      // Verify waiting for takeout
      expect(horseRaceProvider.shouldPromptTakeout, true);

      // Finish takeout
      horseRaceProvider.handleTakeoutFinished();

      // Verify turn advanced to player 2
      expect(horseRaceProvider.getCurrentPlayerId(), player2.id);
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 0);
      expect(horseRaceProvider.shouldPromptTakeout, false);

      // Player 2 throws 1 dart then skips
      horseRaceProvider.processDartThrow(20);
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 1);

      horseRaceProvider.skipTurn();

      // Verify 2 more misses recorded (total 3)
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 3);
      final dartScores2 = horseRaceProvider.getCurrentTurnDartScores(player2.id);
      expect(dartScores2.length, 3);
      expect(dartScores2[0], '20');
      expect(dartScores2[1], 'Miss');
      expect(dartScores2[2], 'Miss');

      // Verify score is 20
      expect(horseRaceProvider.getPlayerScore(player2.id), 20);

      horseRaceProvider.handleTakeoutFinished();

      // Verify turn advanced to player 3
      expect(horseRaceProvider.getCurrentPlayerId(), player3.id);
    });

    test('skip multiple turns in sequence', () async {
      // Create players
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');
      final player3 = Player.create(name: 'Player 3');
      final player4 = Player.create(name: 'Player 4');
      await playerProvider.savePlayer(player1);
      await playerProvider.savePlayer(player2);
      await playerProvider.savePlayer(player3);
      await playerProvider.savePlayer(player4);

      // Start game
      horseRaceProvider.startGame([player1, player2, player3, player4], 50, exactScoreMode: false);

      // Player 1 skips
      expect(horseRaceProvider.getCurrentPlayerId(), player1.id);
      horseRaceProvider.skipTurn();
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 3);
      expect(horseRaceProvider.getPlayerScore(player1.id), 0);
      horseRaceProvider.handleTakeoutFinished();

      // Player 2 skips
      expect(horseRaceProvider.getCurrentPlayerId(), player2.id);
      horseRaceProvider.skipTurn();
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 3);
      expect(horseRaceProvider.getPlayerScore(player2.id), 0);
      horseRaceProvider.handleTakeoutFinished();

      // Player 3 throws some darts
      expect(horseRaceProvider.getCurrentPlayerId(), player3.id);
      horseRaceProvider.processDartThrow(15);
      horseRaceProvider.processDartThrow(10);
      horseRaceProvider.processDartThrow(5);
      expect(horseRaceProvider.getPlayerScore(player3.id), 30);
      horseRaceProvider.handleTakeoutFinished();

      // Player 4 skips
      expect(horseRaceProvider.getCurrentPlayerId(), player4.id);
      horseRaceProvider.skipTurn();
      expect(horseRaceProvider.getCurrentPlayerDartsThrown(), 3);
      expect(horseRaceProvider.getPlayerScore(player4.id), 0);
      horseRaceProvider.handleTakeoutFinished();

      // Back to player 1 - verify scores
      expect(horseRaceProvider.getCurrentPlayerId(), player1.id);
      expect(horseRaceProvider.getPlayerScore(player1.id), 0);
      expect(horseRaceProvider.getPlayerScore(player2.id), 0);
      expect(horseRaceProvider.getPlayerScore(player3.id), 30);
      expect(horseRaceProvider.getPlayerScore(player4.id), 0);
    });

    test('edit score on first turn preserves score correctly', () async {
      // Test that edit score works on the very first turn
      final player = Player.create(name: 'First Turn Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 100, exactScoreMode: false);

      // Throw darts (S20, D13, T19)
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(26, dartDisplay: 'D13');
      horseRaceProvider.processDartThrow(57, dartDisplay: 'T19');

      // Verify initial score
      expect(horseRaceProvider.getPlayerScore(player.id), 103);
      final initialDarts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(initialDarts, ['S20', 'D13', 'T19']);

      // Edit scores: Change to S15, S10, S5
      horseRaceProvider.updateAllDartScores(player.id, ['S15', 'S10', 'S5']);

      // Verify edited score
      expect(horseRaceProvider.getPlayerScore(player.id), 30);
      final editedDarts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(editedDarts, ['S15', 'S10', 'S5']);
    });

    test('edit score preserves inner vs outer single distinction', () async {
      final player = Player.create(name: 'Singles Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 100, exactScoreMode: false);

      // Throw inner singles (lowercase s)
      horseRaceProvider.processDartThrow(20, dartDisplay: 's20');
      horseRaceProvider.processDartThrow(15, dartDisplay: 's15');
      horseRaceProvider.processDartThrow(10, dartDisplay: 's10');

      expect(horseRaceProvider.getPlayerScore(player.id), 45);
      final initialDarts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(initialDarts, ['s20', 's15', 's10']);

      // Edit to outer singles (uppercase S)
      horseRaceProvider.updateAllDartScores(player.id, ['S20', 'S15', 'S10']);

      // Score should be same but sector format should change
      expect(horseRaceProvider.getPlayerScore(player.id), 45);
      final editedDarts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(editedDarts, ['S20', 'S15', 'S10']);

      // Edit back to inner singles
      horseRaceProvider.updateAllDartScores(player.id, ['s18', 's14', 's12']);

      expect(horseRaceProvider.getPlayerScore(player.id), 44);
      final finalDarts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(finalDarts, ['s18', 's14', 's12']);
    });

    test('edit score increases player total score', () async {
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');
      await playerProvider.savePlayer(player1);
      await playerProvider.savePlayer(player2);

      horseRaceProvider.startGame([player1, player2], 200, exactScoreMode: false); // High target to avoid early win

      // Player 1 throws low scores
      horseRaceProvider.processDartThrow(5, dartDisplay: 'S5');
      horseRaceProvider.processDartThrow(3, dartDisplay: 'S3');
      horseRaceProvider.processDartThrow(2, dartDisplay: 'S2');

      expect(horseRaceProvider.getPlayerScore(player1.id), 10);

      // Edit to higher scores (Double 20, Double 15, Double 10)
      horseRaceProvider.updateAllDartScores(player1.id, ['D20', 'D15', 'D10']);

      // Verify increased score
      expect(horseRaceProvider.getPlayerScore(player1.id), 90); // 40 + 30 + 20
      final darts = horseRaceProvider.getCurrentTurnDartScores(player1.id);
      expect(darts, ['D20', 'D15', 'D10']);
    });

    test('edit score decreases player total score', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 200, exactScoreMode: false); // High target

      // Throw high scores
      horseRaceProvider.processDartThrow(60, dartDisplay: 'T20');
      horseRaceProvider.processDartThrow(57, dartDisplay: 'T19');
      horseRaceProvider.processDartThrow(54, dartDisplay: 'T18');

      expect(horseRaceProvider.getPlayerScore(player.id), 171);

      // Edit to lower scores
      horseRaceProvider.updateAllDartScores(player.id, ['S10', 'S5', 'Miss']);

      // Verify decreased score
      expect(horseRaceProvider.getPlayerScore(player.id), 15);
      final darts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(darts, ['S10', 'S5', 'Miss']);
    });

    test('edit score to add misses', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 100, exactScoreMode: false);

      // Throw all hits
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(19, dartDisplay: 'S19');
      horseRaceProvider.processDartThrow(18, dartDisplay: 'S18');

      expect(horseRaceProvider.getPlayerScore(player.id), 57);

      // Edit to include misses
      horseRaceProvider.updateAllDartScores(player.id, ['Miss', 'S10', 'Miss']);

      // Verify score with misses
      expect(horseRaceProvider.getPlayerScore(player.id), 10);
      final darts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(darts, ['Miss', 'S10', 'Miss']);
    });

    test('edit score to remove misses', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 100, exactScoreMode: false);

      // Throw with misses
      horseRaceProvider.processDartThrow(0, dartDisplay: 'Miss');
      horseRaceProvider.processDartThrow(10, dartDisplay: 'S10');
      horseRaceProvider.processDartThrow(0, dartDisplay: 'Miss');

      expect(horseRaceProvider.getPlayerScore(player.id), 10);

      // Edit to remove misses
      horseRaceProvider.updateAllDartScores(player.id, ['S20', 'D15', 'T10']);

      // Verify score without misses
      expect(horseRaceProvider.getPlayerScore(player.id), 80); // 20 + 30 + 30
      final darts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(darts, ['S20', 'D15', 'T10']);
    });

    test('edit score with bulls (bullseye and outer bull)', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 100, exactScoreMode: false);

      // Throw regular scores
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');

      expect(horseRaceProvider.getPlayerScore(player.id), 60);

      // Edit to bulls
      horseRaceProvider.updateAllDartScores(player.id, ['Bull', '25', 'S10']);

      // Verify score with bulls
      expect(horseRaceProvider.getPlayerScore(player.id), 85); // 50 + 25 + 10
      final darts = horseRaceProvider.getCurrentTurnDartScores(player.id);
      expect(darts, ['Bull', '25', 'S10']);
    });

    test('edit score maintains waiting for takeout state', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 200, exactScoreMode: false); // High target

      // Throw 3 darts (turn complete)
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');

      // Should be waiting for takeout
      expect(horseRaceProvider.shouldPromptTakeout, true);
      expect(horseRaceProvider.getPlayerScore(player.id), 60);

      // Edit scores
      horseRaceProvider.updateAllDartScores(player.id, ['D20', 'D20', 'D20']);

      // Should still be waiting for takeout
      expect(horseRaceProvider.shouldPromptTakeout, true);
      expect(horseRaceProvider.getPlayerScore(player.id), 120); // 40 + 40 + 40
    });

    test('edit score does not affect other players', () async {
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');
      await playerProvider.savePlayer(player1);
      await playerProvider.savePlayer(player2);

      horseRaceProvider.startGame([player1, player2], 200, exactScoreMode: false); // High target

      // Player 1 throws
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      expect(horseRaceProvider.getPlayerScore(player1.id), 60);
      horseRaceProvider.handleTakeoutFinished();

      // Player 2 throws
      horseRaceProvider.processDartThrow(15, dartDisplay: 'S15');
      horseRaceProvider.processDartThrow(15, dartDisplay: 'S15');
      horseRaceProvider.processDartThrow(15, dartDisplay: 'S15');
      expect(horseRaceProvider.getPlayerScore(player2.id), 45);

      // Edit Player 2's score to higher values
      horseRaceProvider.updateAllDartScores(player2.id, ['D19', 'D18', 'D17']);

      // Verify Player 2's score changed
      expect(horseRaceProvider.getPlayerScore(player2.id), 108); // 38 + 36 + 34

      // Verify Player 1's score unchanged
      expect(horseRaceProvider.getPlayerScore(player1.id), 60);
    });

    test('edit score in exact mode handles bust correctly', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 50, exactScoreMode: true);

      // Throw to get close to target (40 points)
      horseRaceProvider.processDartThrow(20, dartDisplay: 'S20');
      horseRaceProvider.processDartThrow(10, dartDisplay: 'S10');
      horseRaceProvider.processDartThrow(10, dartDisplay: 'S10');
      expect(horseRaceProvider.getPlayerScore(player.id), 40);
      horseRaceProvider.handleTakeoutFinished();

      // Next turn: throw safe throws (45 total)
      horseRaceProvider.processDartThrow(3, dartDisplay: 'S3');
      horseRaceProvider.processDartThrow(1, dartDisplay: 'S1');
      horseRaceProvider.processDartThrow(1, dartDisplay: 'S1');
      expect(horseRaceProvider.getPlayerScore(player.id), 45);
      expect(horseRaceProvider.currentPlayerBusted, false);

      // Edit to cause a bust (20 would make 60, over 50)
      horseRaceProvider.updateAllDartScores(player.id, ['S20', 'Miss', 'Miss']);

      // In exact mode, bust means first dart that goes over doesn't count
      // S20 would make score 60 (40 + 20), which is over 50, so it busts
      // Score stays at 40 (start of turn), bust flag is set
      expect(horseRaceProvider.getPlayerScore(player.id), 40);
      expect(horseRaceProvider.currentPlayerBusted, true);
    });

    test('edit score can trigger win in exact mode', () async {
      final player = Player.create(name: 'Player');
      await playerProvider.savePlayer(player);

      horseRaceProvider.startGame([player], 50, exactScoreMode: true);

      // Get to 40
      horseRaceProvider.processDartThrow(40, dartDisplay: 'D20');
      horseRaceProvider.processDartThrow(0, dartDisplay: 'Miss');
      horseRaceProvider.processDartThrow(0, dartDisplay: 'Miss');
      expect(horseRaceProvider.getPlayerScore(player.id), 40);
      horseRaceProvider.handleTakeoutFinished();

      // Next turn: throw that doesn't win
      horseRaceProvider.processDartThrow(5, dartDisplay: 'S5');
      horseRaceProvider.processDartThrow(3, dartDisplay: 'S3');
      horseRaceProvider.processDartThrow(1, dartDisplay: 'S1');
      expect(horseRaceProvider.getPlayerScore(player.id), 49);
      expect(horseRaceProvider.hasWinner, false);

      // Edit to hit exact score
      horseRaceProvider.updateAllDartScores(player.id, ['S10', 'Miss', 'Miss']);

      // Should win with exact 50
      expect(horseRaceProvider.getPlayerScore(player.id), 50);
      expect(horseRaceProvider.hasWinner, true);
      expect(horseRaceProvider.currentGame!.winnerId, player.id);
    });
  });
}
