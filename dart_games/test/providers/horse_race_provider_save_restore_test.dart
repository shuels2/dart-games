import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late HorseRaceProvider provider;
  late List<Player> players;

  setUp(() async {
    mockServer = MockApiServer();
    provider = HorseRaceProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  group('HorseRaceProvider save/restore', () {
    test('saveGame creates metadata with correct fields', () async {
      provider.startGame(players, 200, exactScoreMode: true);
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(5, dartDisplay: '5');

      await provider.saveGame(players);

      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'carnival_derby');
      expect(saved[0].playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved[0].gameModeName, contains('200'));
      expect(saved[0].gameModeName, contains('Perfect Finish'));
      expect(saved[0].leadingPlayerName, 'Alice');
      expect(saved[0].leadingPlayerScore, '25 pts');
      expect(saved[0].progressInfo, 'Leading: 25 pts');
    });

    test('restoreGame restores full game state', () async {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(60, dartDisplay: 'T20');
      provider.processDartThrow(5, dartDisplay: '5');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');

      // Create new provider and restore
      final newProvider = HorseRaceProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.scores['p1'], 85);
      expect(newProvider.currentGame!.playerIds, ['p1', 'p2', 'p3']);
      expect(newProvider.currentGame!.targetScore, 200);
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startGame(players, 200);
      // Throw 3 darts to trigger waitingForTakeout
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(20, dartDisplay: '20');
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');

      final newProvider = HorseRaceProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.shouldPromptTakeout, true);
    });

    test('restoreGame sets resumedSavedGameId', () async {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');

      final newProvider = HorseRaceProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.resumedSavedGameId, saved[0].id);
    });

    test('clearResumedSavedGameId clears the ID', () async {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(20, dartDisplay: '20');
      provider.handleTakeoutFinished();
      // P2's turn
      provider.processDartThrow(10, dartDisplay: '10');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');

      final newProvider = HorseRaceProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      expect(newProvider.currentGame!.totalTurns['p2'], 1);
    });

    test('gameplay continues correctly after restore', () async {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient).loadSavedGames('carnival_derby');

      final newProvider = HorseRaceProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      // Continue throwing darts
      newProvider.processDartThrow(30, dartDisplay: 'T10');
      expect(newProvider.currentGame!.scores['p1'], 50);
      expect(newProvider.currentGame!.totalDartsThrown['p1'], 2);
    });
  });
}
