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
    });

    test('updatePlayerStats does not add history for losses', () async {
      final player = Player.create(name: 'Loser');
      await provider.savePlayer(player);

      await provider.updatePlayerStats(
        player.id,
        won: false,
        gameName: 'Carnival Derby',
        gameDuration: const Duration(minutes: 5),
      );

      final updated = provider.getPlayerById(player.id);
      expect(updated!.gameHistory, isEmpty);
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
  });
}
