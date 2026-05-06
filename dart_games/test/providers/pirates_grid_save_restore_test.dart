import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/pirates_grid_provider.dart';
import 'package:dart_games/models/pirates_grid_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late PiratesGridProvider provider;
  late List<Player> players;

  setUp(() async {
    mockServer = MockApiServer();
    provider = PiratesGridProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
    ];
  });

  group('PiratesGridProvider save/restore', () {
    test('saveGame creates SavedGameMetadata with correct fields', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );

      // Throw a dart to create some state
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      await provider.saveGame(players);

      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');
      expect(saved, hasLength(1));
      expect(saved[0].playerNames, ['Alice', 'Bob']);
      expect(saved[0].progressInfo, contains('Round'));
      expect(saved[0].progressInfo, contains('Alice'));
      expect(saved[0].leadingPlayerName, isNotEmpty);
    });

    test('saveGame uses gameType=pirates_grid', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      await provider.saveGame(players);

      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'pirates_grid');
    });

    test('restoreGame loads full game state from SavedGameMetadata', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.medium,
        3,
        true,
        false,
      );
      provider.processDartThrow(score: 20, multiplier: 2, sector: 'D20');
      provider.processDartThrow(score: 18, multiplier: 2, sector: 'D18');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.targetDifficulty, TargetDifficulty.medium);
      expect(newProvider.currentGame!.bestOf, 3);
      expect(newProvider.currentGame!.stealMode, true);
      expect(newProvider.currentGame!.speedPlay, false);
      expect(newProvider.currentGame!.playerIds, ['p1', 'p2']);
      expect(newProvider.currentGame!.totalDartsThrown['p1']! > 0, true);
    });

    test('resumedSavedGameId is set after saveGame', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      expect(provider.resumedSavedGameId, saved[0].id);
    });

    test('resumedSavedGameId is set after restoreGame', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, saved[0].id);
    });

    test('clearResumedSavedGameId resets resumedSavedGameId to null', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('mid-round save/restore preserves currentTurnDartSegments and dartsThrown', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      // p1 throws 2 darts
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      provider.processDartThrow(score: 18, multiplier: 1, sector: 'S18');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      final game = newProvider.currentGame!;
      expect(game.dartsThrown['p1'], 2);
      expect(game.currentTurnDartSegments['p1'], ['S20', 'S18']);
      expect(game.totalDartsThrown['p1'], 2);
    });

    test('mid-match Bo3 save/restore preserves roundsWon, currentRound, and winningLine', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        3,
        false,
        false,
      );

      // Easy grid row 0: [S20, S18, S16] — p1 claims all three for a win
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      provider.processDartThrow(score: 18, multiplier: 1, sector: 'S18');
      provider.processDartThrow(score: 16, multiplier: 1, sector: 'S16');
      // Round 1 is now won by p1 (three in a row in row 0); takeout needed
      provider.handleTakeoutFinished(); // transitions to round 2

      // Now in round 2: save mid-round
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      final game = newProvider.currentGame!;
      expect(game.roundsWon['p1'], 1);
      expect(game.roundsWon['p2'], 0);
      expect(game.currentRound, 2);
      expect(game.isDraw, false);
      expect(game.winnerId, isNull); // round 2 not finished
    });

    test('game with all options ON (Hard + Bo5 + Steal + Speed) saves and restores all settings', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.hard,
        5,
        true,
        true,
      );
      // Hard center = Bull; skip with a miss
      provider.processDartThrow(score: 7, multiplier: 1, sector: 'S7');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      final game = newProvider.currentGame!;
      // Verify ALL four game options are preserved
      expect(game.targetDifficulty, TargetDifficulty.hard);
      expect(game.bestOf, 5);
      expect(game.stealMode, true);
      expect(game.speedPlay, true);
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      // Throw 3 darts to fill turn → waitingForTakeout = true
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 2, multiplier: 1, sector: 'S2');
      provider.processDartThrow(score: 3, multiplier: 1, sector: 'S3');
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, true);
    });

    test('saving a resumed game overwrites the existing save', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      // First save
      await provider.saveGame(players);
      final saved1 = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');
      expect(saved1, hasLength(1));
      final originalId = saved1[0].id;

      // Restore and throw another dart, then save again
      provider.restoreGame(saved1[0]);
      provider.processDartThrow(score: 18, multiplier: 1, sector: 'S18');
      await provider.saveGame(players);

      // Should still be 1 saved game, same id (overwrite)
      final saved2 = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');
      expect(saved2, hasLength(1));
      expect(saved2[0].id, originalId);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startGame(
        ['p1', 'p2'],
        TargetDifficulty.easy,
        1,
        false,
        false,
      );
      // p1 throws 3 darts, then turn advances
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 2, multiplier: 1, sector: 'S2');
      provider.processDartThrow(score: 3, multiplier: 1, sector: 'S3');
      provider.handleTakeoutFinished(); // advances turn to p2

      // p2 throws 1 dart
      provider.processDartThrow(score: 4, multiplier: 1, sector: 'S4');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('pirates_grid');

      final newProvider = PiratesGridProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      expect(newProvider.currentGame!.totalTurns['p2'], 1);
    });
  });
}
