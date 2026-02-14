import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/game_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerProvider', () {
    late PlayerProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = PlayerProvider();
    });

    test('initializes with empty player list', () {
      expect(provider.allPlayers, isEmpty);
      expect(provider.selectedPlayers, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loads players from empty storage', () async {
      await provider.loadPlayers();

      expect(provider.allPlayers, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('saves and loads a player', () async {
      final player = Player.create(name: 'Test Player');

      await provider.savePlayer(player);

      expect(provider.allPlayers.length, 1);
      expect(provider.allPlayers.first.name, 'Test Player');

      // Create new provider instance to test persistence
      final newProvider = PlayerProvider();
      await newProvider.loadPlayers();

      expect(newProvider.allPlayers.length, 1);
      expect(newProvider.allPlayers.first.id, player.id);
      expect(newProvider.allPlayers.first.name, 'Test Player');
    });

    test('updates existing player', () async {
      final player = Player.create(name: 'Original Name');
      await provider.savePlayer(player);

      final updated = player.copyWith(name: 'Updated Name');
      await provider.savePlayer(updated);

      expect(provider.allPlayers.length, 1);
      expect(provider.allPlayers.first.name, 'Updated Name');
    });

    test('saves multiple players', () async {
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');
      final player3 = Player.create(name: 'Player 3');

      await provider.savePlayer(player1);
      await provider.savePlayer(player2);
      await provider.savePlayer(player3);

      expect(provider.allPlayers.length, 3);
    });

    test('deletes player', () async {
      final player = Player.create(name: 'To Delete');
      await provider.savePlayer(player);

      expect(provider.allPlayers.length, 1);

      await provider.deletePlayer(player.id);

      expect(provider.allPlayers, isEmpty);
    });

    test('getPlayerById returns correct player', () async {
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');

      await provider.savePlayer(player1);
      await provider.savePlayer(player2);

      final found = provider.getPlayerById(player2.id);

      expect(found, isNotNull);
      expect(found!.name, 'Player 2');
    });

    test('getPlayerById returns null for non-existent ID', () {
      final found = provider.getPlayerById('non-existent-id');

      expect(found, isNull);
    });

    test('selectPlayer adds player to selected list', () async {
      final player = Player.create(name: 'Selectable');
      await provider.savePlayer(player);

      provider.selectPlayer(player);

      expect(provider.selectedPlayers.length, 1);
      expect(provider.selectedPlayers.first.id, player.id);
    });

    test('selectPlayer enforces maximum of 8 players', () async {
      for (int i = 0; i < 10; i++) {
        final player = Player.create(name: 'Player $i');
        await provider.savePlayer(player);
      }

      final allPlayers = provider.allPlayers;
      for (int i = 0; i < 10; i++) {
        provider.selectPlayer(allPlayers[i]);
      }

      expect(provider.selectedPlayers.length, 8);
      expect(provider.error, isNotNull);
    });

    test('deselectPlayer removes from selected list', () async {
      final player = Player.create(name: 'Deselectable');
      await provider.savePlayer(player);

      provider.selectPlayer(player);
      expect(provider.selectedPlayers.length, 1);

      provider.deselectPlayer(player.id);
      expect(provider.selectedPlayers, isEmpty);
    });

    test('clearSelection removes all selected players', () async {
      final player1 = Player.create(name: 'Player 1');
      final player2 = Player.create(name: 'Player 2');

      await provider.savePlayer(player1);
      await provider.savePlayer(player2);

      provider.selectPlayer(player1);
      provider.selectPlayer(player2);

      expect(provider.selectedPlayers.length, 2);

      provider.clearSelection();

      expect(provider.selectedPlayers, isEmpty);
    });

    test('updatePlayerStats increments games played', () async {
      final player = Player.create(name: 'Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(player.id, won: false);

      final updated = provider.getPlayerById(player.id);
      expect(updated!.gamesPlayed, 1);
      expect(updated.gamesWon, 0);
    });

    test('updatePlayerStats increments games won', () async {
      final player = Player.create(name: 'Winner');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(player.id, won: true);

      final updated = provider.getPlayerById(player.id);
      expect(updated!.gamesPlayed, 1);
      expect(updated.gamesWon, 1);
    });

    test('updatePlayerStats adds game history entry for wins', () async {
      final player = Player.create(name: 'History Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5, seconds: 30),
      );

      final updated = provider.getPlayerById(player.id);
      expect(updated!.gameHistory.length, 1);
      expect(updated.gameHistory.first.gameName, 'Carnival Derby');
      expect(updated.gameHistory.first.duration.inMinutes, 5);
      expect(updated.gameHistory.first.metadata?['won'], true);
    });

    test('updatePlayerStats adds history for losses with duration', () async {
      final player = Player.create(name: 'Loser');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: false,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      final updated = provider.getPlayerById(player.id);
      expect(updated!.gameHistory.length, 1);
      expect(updated.gameHistory.first.gameName, 'Carnival Derby');
      expect(updated.gameHistory.first.duration.inMinutes, 5);
      expect(updated.gameHistory.first.metadata?['won'], false);
      expect(updated.gamesPlayed, 1);
      expect(updated.gamesWon, 0);
    });

    test('updatePlayerStats accumulates multiple wins', () async {
      final player = Player.create(name: 'Multiple Winner');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 3),
      );

      final updated = provider.getPlayerById(player.id);
      expect(updated!.gamesPlayed, 2);
      expect(updated.gamesWon, 2);
      expect(updated.gameHistory.length, 2);
    });

    test('getPlayerHistory returns all history entries', () async {
      final player = Player.create(name: 'Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 3),
      );

      final history = provider.getPlayerHistory(player.id);
      expect(history.length, 2);
    });

    test('getPlayerHistory returns empty for non-existent player', () {
      final history = provider.getPlayerHistory('non-existent');
      expect(history, isEmpty);
    });

    test('getPlayerHistoryForGame filters by game name', () async {
      final player = Player.create(name: 'Multi-Game Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Other Game',
        gameDuration: const Duration(minutes: 10),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 3),
      );

      final derbyHistory = provider.getPlayerHistoryForGame(
        player.id,
        'Carnival Derby',
      );

      expect(derbyHistory.length, 2);
      expect(derbyHistory.every((e) => e.gameName == 'Carnival Derby'), isTrue);
    });

    test('getPlayerTotalPlayTime sums all game durations', () async {
      final player = Player.create(name: 'Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 3),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Other Game',
        gameDuration: const Duration(minutes: 10),
      );

      final totalTime = provider.getPlayerTotalPlayTime(player.id);
      expect(totalTime.inMinutes, 18); // 5 + 3 + 10
    });

    test('getPlayerTotalPlayTime returns zero for no history', () async {
      final player = Player.create(name: 'New Player');
      await provider.savePlayer(player);

      final totalTime = provider.getPlayerTotalPlayTime(player.id);
      expect(totalTime, Duration.zero);
    });

    test('getPlayerAverageGameDuration calculates average correctly', () async {
      final player = Player.create(name: 'Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 6),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 4),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      final avgDuration = provider.getPlayerAverageGameDuration(
        player.id,
        'Carnival Derby',
      );

      expect(avgDuration, isNotNull);
      expect(avgDuration!.inMinutes, 5); // (6 + 4 + 5) / 3 = 5
    });

    test('getPlayerAverageGameDuration returns null for no games', () async {
      final player = Player.create(name: 'Player');
      await provider.savePlayer(player);

      final avgDuration = provider.getPlayerAverageGameDuration(
        player.id,
        'Carnival Derby',
      );

      expect(avgDuration, isNull);
    });

    test('getPlayerAverageGameDuration filters by game name', () async {
      final player = Player.create(name: 'Player');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Other Game',
        gameDuration: const Duration(minutes: 20),
      );

      final avgDuration = provider.getPlayerAverageGameDuration(
        player.id,
        'Carnival Derby',
      );

      expect(avgDuration, isNotNull);
      expect(avgDuration!.inMinutes, 5); // Only Carnival Derby game
    });

    test('player data persists across provider instances', () async {
      final player = Player.create(name: 'Persistent');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      // Create new provider to simulate app restart
      final newProvider = PlayerProvider();
      await newProvider.loadPlayers();

      final loaded = newProvider.getPlayerById(player.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Persistent');
      expect(loaded.gamesPlayed, 1);
      expect(loaded.gamesWon, 1);
      expect(loaded.gameHistory.length, 1);
    });

    test('clearError clears error message', () async {
      // Force an error by trying to select too many players
      for (int i = 0; i < 9; i++) {
        final player = Player.create(name: 'Player $i');
        await provider.savePlayer(player);
        provider.selectPlayer(player);
      }

      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });

    test('deletePlayer removes from selected players', () async {
      final player = Player.create(name: 'To Delete');
      await provider.savePlayer(player);

      provider.selectPlayer(player);
      expect(provider.selectedPlayers.length, 1);

      await provider.deletePlayer(player.id);

      expect(provider.selectedPlayers, isEmpty);
    });

    test('allPlayers returns unmodifiable list', () {
      expect(() => provider.allPlayers.add(Player.create(name: 'Test')),
          throwsUnsupportedError);
    });

    test('selectedPlayers returns unmodifiable list', () {
      expect(() => provider.selectedPlayers.add(Player.create(name: 'Test')),
          throwsUnsupportedError);
    });

    group('Alphabetical Sorting', () {
      test('sorts players alphabetically on load', () async {
        // Create players in non-alphabetical order
        final playerC = Player.create(name: 'Charlie');
        final playerA = Player.create(name: 'Alice');
        final playerB = Player.create(name: 'Bob');

        await provider.savePlayer(playerC);
        await provider.savePlayer(playerA);
        await provider.savePlayer(playerB);

        // Mark as sorted and reload
        await provider.markPlayersSorted();

        final newProvider = PlayerProvider();
        await newProvider.loadPlayers();

        // Players should be alphabetically sorted
        expect(newProvider.allPlayers.length, 3);
        expect(newProvider.allPlayers[0].name, 'Alice');
        expect(newProvider.allPlayers[1].name, 'Bob');
        expect(newProvider.allPlayers[2].name, 'Charlie');
      });

      test('new players appear at bottom (not inserted alphabetically)', () async {
        // Create and sort initial players
        final playerA = Player.create(name: 'Alice');
        final playerC = Player.create(name: 'Charlie');
        await provider.savePlayer(playerA);
        await provider.savePlayer(playerC);
        await provider.markPlayersSorted();

        // Reload to get sorted state
        final newProvider = PlayerProvider();
        await newProvider.loadPlayers();

        // Add new player that would alphabetically go in the middle
        final playerB = Player.create(name: 'Bob');
        await newProvider.savePlayer(playerB);

        // Bob should be at the END, not inserted between Alice and Charlie
        expect(newProvider.allPlayers.length, 3);
        expect(newProvider.allPlayers[0].name, 'Alice');
        expect(newProvider.allPlayers[1].name, 'Charlie');
        expect(newProvider.allPlayers[2].name, 'Bob'); // At bottom, not middle
      });

      test('markPlayersSorted updates timestamp', () async {
        // Add a player
        final player = Player.create(name: 'Test');
        await provider.savePlayer(player);

        // Mark as sorted
        await provider.markPlayersSorted();

        // Verify timestamp was saved by checking it loads in new provider
        final newProvider = PlayerProvider();
        await newProvider.loadPlayers();

        // Add another player after marking sorted
        final newPlayer = Player.create(name: 'Zara');
        await newProvider.savePlayer(newPlayer);

        // Zara should be at bottom (new player)
        expect(newProvider.allPlayers.length, 2);
        expect(newProvider.allPlayers[1].name, 'Zara');
      });

      test('returning to screen sorts all players', () async {
        // Initial setup: add players
        final playerC = Player.create(name: 'Charlie');
        final playerA = Player.create(name: 'Alice');
        await provider.savePlayer(playerC);
        await provider.savePlayer(playerA);
        await provider.markPlayersSorted();

        // Load sorted players
        final provider2 = PlayerProvider();
        await provider2.loadPlayers();
        expect(provider2.allPlayers[0].name, 'Alice');
        expect(provider2.allPlayers[1].name, 'Charlie');

        // Add new player (appears at bottom)
        final playerB = Player.create(name: 'Bob');
        await provider2.savePlayer(playerB);
        expect(provider2.allPlayers[2].name, 'Bob'); // At bottom

        // Mark sorted (simulating leaving screen)
        await provider2.markPlayersSorted();

        // Reload (simulating returning to screen)
        final provider3 = PlayerProvider();
        await provider3.loadPlayers();

        // Now Bob should be alphabetically sorted
        expect(provider3.allPlayers.length, 3);
        expect(provider3.allPlayers[0].name, 'Alice');
        expect(provider3.allPlayers[1].name, 'Bob'); // Now sorted!
        expect(provider3.allPlayers[2].name, 'Charlie');
      });

      test('sorts case-insensitively', () async {
        // Create players with mixed case
        final playerLowerA = Player.create(name: 'alice');
        final playerUpperB = Player.create(name: 'Bob');
        final playerLowerC = Player.create(name: 'charlie');
        final playerUpperD = Player.create(name: 'DELTA');

        await provider.savePlayer(playerUpperD);
        await provider.savePlayer(playerLowerC);
        await provider.savePlayer(playerUpperB);
        await provider.savePlayer(playerLowerA);

        await provider.markPlayersSorted();

        final newProvider = PlayerProvider();
        await newProvider.loadPlayers();

        // Should be sorted alphabetically regardless of case
        expect(newProvider.allPlayers[0].name, 'alice');
        expect(newProvider.allPlayers[1].name, 'Bob');
        expect(newProvider.allPlayers[2].name, 'charlie');
        expect(newProvider.allPlayers[3].name, 'DELTA');
      });

      test('sorting empty list does not crash', () async {
        // Load empty list
        await provider.loadPlayers();

        // Should not crash
        expect(provider.allPlayers, isEmpty);

        // Mark sorted on empty list
        await provider.markPlayersSorted();

        // Should still be empty
        expect(provider.allPlayers, isEmpty);
      });

      test('sorting single player works correctly', () async {
        final player = Player.create(name: 'Only Player');
        await provider.savePlayer(player);
        await provider.markPlayersSorted();

        final newProvider = PlayerProvider();
        await newProvider.loadPlayers();

        // Single player should remain
        expect(newProvider.allPlayers.length, 1);
        expect(newProvider.allPlayers.first.name, 'Only Player');
      });
    });

    group('New Stats Tracking', () {
      test('updatePlayerStats stores new fields', () async {
        final player = Player.create(name: 'Stats Player');
        await provider.savePlayer(player);

        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Target Tag',
          gameDuration: const Duration(minutes: 8),
          dartThrows: 42,
          turns: 14,
          playerCount: 4,
        );

        final updated = provider.getPlayerById(player.id);
        expect(updated, isNotNull);
        expect(updated!.gameHistory.length, 1);
        expect(updated.gameHistory.first.dartThrows, 42);
        expect(updated.gameHistory.first.turns, 14);
        expect(updated.gameHistory.first.playerCount, 4);
      });

      test('getPlayerTotalDartsThrown sums correctly', () async {
        final player = Player.create(name: 'Dart Counter');
        await provider.savePlayer(player);

        // Add multiple games with dart throws
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 1',
          gameDuration: const Duration(minutes: 5),
          dartThrows: 30,
        );
        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Game 2',
          gameDuration: const Duration(minutes: 6),
          dartThrows: 45,
        );
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 3',
          gameDuration: const Duration(minutes: 4),
          dartThrows: 25,
        );

        final totalDarts = provider.getPlayerTotalDartsThrown(player.id);
        expect(totalDarts, 100); // 30 + 45 + 25
      });

      test('getPlayerTotalTurns sums correctly', () async {
        final player = Player.create(name: 'Turn Counter');
        await provider.savePlayer(player);

        // Add games with turns
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 1',
          gameDuration: const Duration(minutes: 5),
          turns: 10,
        );
        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Game 2',
          gameDuration: const Duration(minutes: 6),
          turns: 15,
        );
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 3',
          gameDuration: const Duration(minutes: 4),
          turns: 8,
        );

        final totalTurns = provider.getPlayerTotalTurns(player.id);
        expect(totalTurns, 33); // 10 + 15 + 8
      });

      test('getPlayerTotalPlayersEncountered sums correctly', () async {
        final player = Player.create(name: 'Social Player');
        await provider.savePlayer(player);

        // Add games with different player counts
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 1',
          gameDuration: const Duration(minutes: 5),
          playerCount: 2,
        );
        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Game 2',
          gameDuration: const Duration(minutes: 6),
          playerCount: 4,
        );
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 3',
          gameDuration: const Duration(minutes: 4),
          playerCount: 3,
        );

        final totalPlayers = provider.getPlayerTotalPlayersEncountered(player.id);
        expect(totalPlayers, 9); // 2 + 4 + 3
      });

      test('getPlayerAverageDartsPerGame calculates correctly', () async {
        final player = Player.create(name: 'Average Dart Player');
        await provider.savePlayer(player);

        // Add Target Tag games
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Target Tag',
          gameDuration: const Duration(minutes: 5),
          dartThrows: 30,
        );
        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Target Tag',
          gameDuration: const Duration(minutes: 6),
          dartThrows: 42,
        );
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Target Tag',
          gameDuration: const Duration(minutes: 4),
          dartThrows: 36,
        );

        // Add Carnival Derby game (should not affect Target Tag average)
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Carnival Derby',
          gameDuration: const Duration(minutes: 3),
          dartThrows: 15,
        );

        final avgDarts = provider.getPlayerAverageDartsPerGame(player.id, 'Target Tag');
        expect(avgDarts, 36.0); // (30 + 42 + 36) / 3 = 36
      });

      test('getPlayerAverageTurnsPerGame calculates correctly', () async {
        final player = Player.create(name: 'Average Turn Player');
        await provider.savePlayer(player);

        // Add Carnival Derby games
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Carnival Derby',
          gameDuration: const Duration(minutes: 5),
          turns: 10,
        );
        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Carnival Derby',
          gameDuration: const Duration(minutes: 6),
          turns: 14,
        );
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Carnival Derby',
          gameDuration: const Duration(minutes: 4),
          turns: 12,
        );

        final avgTurns = provider.getPlayerAverageTurnsPerGame(player.id, 'Carnival Derby');
        expect(avgTurns, 12.0); // (10 + 14 + 12) / 3 = 12
      });

      test('handles null values in old entries', () async {
        final player = Player.create(name: 'Legacy Player');
        await provider.savePlayer(player);

        // Add old entry without new stats (simulates backward compatibility)
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Old Game',
          gameDuration: const Duration(minutes: 5),
          // dartThrows, turns, playerCount not provided (null)
        );

        // Add new entry with stats
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'New Game',
          gameDuration: const Duration(minutes: 6),
          dartThrows: 30,
          turns: 10,
          playerCount: 4,
        );

        // Should sum only non-null values
        expect(provider.getPlayerTotalDartsThrown(player.id), 30);
        expect(provider.getPlayerTotalTurns(player.id), 10);
        expect(provider.getPlayerTotalPlayersEncountered(player.id), 4);

        // Averages should handle null values correctly
        final avgDarts = provider.getPlayerAverageDartsPerGame(player.id, 'New Game');
        expect(avgDarts, 30.0);
      });

      test('stores won metadata correctly for wins', () async {
        final player = Player.create(name: 'Winner');
        await provider.savePlayer(player);

        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Target Tag',
          gameDuration: const Duration(minutes: 5),
        );

        final updated = provider.getPlayerById(player.id);
        expect(updated, isNotNull);
        expect(updated!.gameHistory.length, 1);
        expect(updated.gameHistory.first.metadata?['won'], true);
      });

      test('stores won metadata correctly for losses', () async {
        final player = Player.create(name: 'Loser');
        await provider.savePlayer(player);

        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Carnival Derby',
          gameDuration: const Duration(minutes: 8),
        );

        final updated = provider.getPlayerById(player.id);
        expect(updated, isNotNull);
        expect(updated!.gameHistory.length, 1);
        expect(updated.gameHistory.first.metadata?['won'], false);
      });

      test('correctly tracks wins and losses in metadata', () async {
        final player = Player.create(name: 'Mixed Results');
        await provider.savePlayer(player);

        // Win a game
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 1',
          gameDuration: const Duration(minutes: 5),
        );

        // Lose a game
        await provider.updatePlayerStats(
          player.id,
          won: false,
          gameName: 'Game 2',
          gameDuration: const Duration(minutes: 6),
        );

        // Win another game
        await provider.updatePlayerStats(
          player.id,
          won: true,
          gameName: 'Game 3',
          gameDuration: const Duration(minutes: 4),
        );

        final updated = provider.getPlayerById(player.id);
        expect(updated, isNotNull);
        expect(updated!.gameHistory.length, 3);

        // Check metadata for each game
        expect(updated.gameHistory[0].metadata?['won'], true);  // First game - win
        expect(updated.gameHistory[1].metadata?['won'], false); // Second game - loss
        expect(updated.gameHistory[2].metadata?['won'], true);  // Third game - win

        // Verify stats still correct
        expect(updated.gamesPlayed, 3);
        expect(updated.gamesWon, 2);
      });
    });
  });
}
