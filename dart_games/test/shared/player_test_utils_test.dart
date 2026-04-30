import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'player_test_utils.dart';
import 'package:dart_games/models/player.dart';
import 'mock_api_helpers.dart';

void main() {
  group('PlayerTestUtils', () {
    test('creates multiple players with sequential names', () {
      final players = PlayerTestUtils.createPlayers(3);

      expect(players.length, 3);
      expect(players[0].name, 'Player 1');
      expect(players[1].name, 'Player 2');
      expect(players[2].name, 'Player 3');
    });

    test('creates players with custom prefix', () {
      final players = PlayerTestUtils.createPlayers(2, namePrefix: 'Test');

      expect(players.length, 2);
      expect(players[0].name, 'Test 1');
      expect(players[1].name, 'Test 2');
    });

    test('creates and saves players to provider', () async {
      final mockServer = MockApiServer();
      final provider = PlayerProvider();
      provider.initialize(mockServer.apiClient);
      await provider.loadPlayers();

      final players = await PlayerTestUtils.createAndSavePlayers(provider, 2);

      expect(players.length, 2);
      expect(provider.allPlayers.length, 2);
      expect(provider.allPlayers[0].name, 'Player 1');
      expect(provider.allPlayers[1].name, 'Player 2');
    });

    test('verifies player stats - passes with correct stats', () {
      final player = Player.create(name: 'Test').copyWith(
        gamesPlayed: 5,
        gamesWon: 2,
      );

      expect(
        () => PlayerTestUtils.verifyPlayerStats(
          player,
          gamesPlayed: 5,
          gamesWon: 2,
        ),
        returnsNormally,
      );
    });

    test('verifies player stats - fails with incorrect stats', () {
      final player = Player.create(name: 'Test').copyWith(
        gamesPlayed: 5,
        gamesWon: 2,
      );

      expect(
        () => PlayerTestUtils.verifyPlayerStats(
          player,
          gamesPlayed: 10, // Wrong
          gamesWon: 2,
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('finds player by ID from provider', () async {
      final mockServer = MockApiServer();
      final provider = PlayerProvider();
      provider.initialize(mockServer.apiClient);
      await provider.loadPlayers();

      final players = await PlayerTestUtils.createAndSavePlayers(provider, 2);
      final foundPlayer = PlayerTestUtils.getPlayerById(provider, players[0].id);

      expect(foundPlayer, isNotNull);
      expect(foundPlayer!.id, players[0].id);
      expect(foundPlayer.name, 'Player 1');
    });

    test('reloads and gets player', () async {
      final mockServer = MockApiServer();
      final provider = PlayerProvider();
      provider.initialize(mockServer.apiClient);
      await provider.loadPlayers();

      final players = await PlayerTestUtils.createAndSavePlayers(provider, 1);
      final playerId = players[0].id;

      // Simulate app restart
      final newProvider = PlayerProvider();
      newProvider.initialize(mockServer.apiClient);
      final reloadedPlayer = await PlayerTestUtils.reloadAndGetPlayer(newProvider, playerId);

      expect(reloadedPlayer, isNotNull);
      expect(reloadedPlayer!.id, playerId);
      expect(reloadedPlayer.name, 'Player 1');
    });

    test('verifies history length', () {
      final player = Player.create(name: 'Test').copyWith(
        gamesPlayed: 3,
        gamesWon: 1,
      );

      // Add some game history
      final updatedPlayer = player; // In real usage, history would be added via updatePlayerStats

      expect(
        () => PlayerTestUtils.verifyPlayerStats(
          updatedPlayer,
          gamesPlayed: 3,
          gamesWon: 1,
          historyLength: 0, // No history added yet
        ),
        returnsNormally,
      );
    });

    test('returns null when player ID not found', () async {
      final mockServer = MockApiServer();
      final provider = PlayerProvider();
      provider.initialize(mockServer.apiClient);
      await provider.loadPlayers();

      final foundPlayer = PlayerTestUtils.getPlayerById(provider, 'nonexistent-id');

      expect(foundPlayer, isNull);
    });

    test('returns null when reloading nonexistent player', () async {
      final mockServer = MockApiServer();
      final provider = PlayerProvider();
      provider.initialize(mockServer.apiClient);

      final reloadedPlayer = await PlayerTestUtils.reloadAndGetPlayer(provider, 'nonexistent-id');

      expect(reloadedPlayer, isNull);
    });
  });
}
