import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';
import 'package:dart_games/models/clockwork_quest_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late ClockworkQuestProvider provider;
  late List<Player> players;

  setUp(() async {
    mockServer = MockApiServer();
    provider = ClockworkQuestProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  group('ClockworkQuestProvider save/restore', () {
    test('saveGame creates metadata with correct fields', () async {
      provider.startGame(players, false, false, 1);

      // Throw a dart to create some state
      provider.processDartThrow('S1');

      await provider.saveGame(players);

      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'clockwork_quest');
      expect(saved[0].playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved[0].progressInfo, contains('Lap'));
      expect(saved[0].progressInfo, contains('Target'));
      expect(saved[0].leadingPlayerName, isNotEmpty);
      expect(saved[0].leadingPlayerScore, contains('Lap'));
    });

    test('restoreGame restores full game state', () async {
      provider.startGame(players, true, false, 2);

      provider.processDartThrow('S1');
      provider.processDartThrow('S2');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');

      final newProvider =
          ClockworkQuestProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.includeBullseye, true);
      expect(newProvider.currentGame!.numberOfLaps, 2);
      expect(newProvider.currentGame!.totalDartsThrown['p1']! > 0, true);
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startGame(players, false, false, 1);
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      provider.processDartThrow('S3');
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');

      final newProvider =
          ClockworkQuestProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, true);
    });

    test('resumedSavedGameId is set and clearable', () async {
      provider.startGame(players, false, false, 1);
      provider.processDartThrow('S1');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, saved[0].id);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startGame(players, false, false, 1);
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      provider.processDartThrow('S3');
      provider.advanceTurn();

      provider.processDartThrow('S1');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');

      final newProvider =
          ClockworkQuestProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      // p2 hasn't completed a turn yet (advanceTurn not called for p2)
      expect(newProvider.currentGame!.totalTurns['p2'], 0);
    });

    test('gameplay continues correctly after restore', () async {
      provider.startGame(players, false, false, 1);
      provider.processDartThrow('S1');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');

      final newProvider =
          ClockworkQuestProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      newProvider.processDartThrow('S2');
      expect(newProvider.currentGame!.totalDartsThrown['p1'], 2);
    });

    test('completedTargets survive save/restore', () async {
      provider.startGame(players, false, false, 1);
      // Hit targets to advance
      provider.processDartThrow('S1');
      provider.processDartThrow('S2');
      provider.processDartThrow('S3');
      provider.advanceTurn();

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('clockwork_quest');

      final newProvider =
          ClockworkQuestProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      // p1 should have advanced their target past 1
      expect(
          newProvider.currentGame!.currentTarget['p1']! > 1 ||
              newProvider.currentGame!.completedTargets['p1']!.isNotEmpty,
          true);
    });
  });
}
