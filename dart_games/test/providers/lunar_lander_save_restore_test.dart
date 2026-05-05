import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/lunar_lander_provider.dart';
import 'package:dart_games/models/lunar_lander_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late LunarLanderProvider provider;
  late List<Player> players;

  setUp(() async {
    mockServer = MockApiServer();
    provider = LunarLanderProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  group('LunarLanderProvider save/restore', () {
    test('saveGame creates metadata with correct fields', () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );

      // Throw a dart to create some state
      provider.processDartThrow(score: 10, multiplier: 2, sector: 'D10');

      await provider.saveGame(players);

      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'lunar_lander');
      expect(saved[0].playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved[0].progressInfo, contains('Altitude'));
      expect(saved[0].progressInfo, contains('200'));
      expect(saved[0].leadingPlayerName, isNotEmpty);
      expect(saved[0].leadingPlayerScore, contains('Alt'));
    });

    test('restoreGame restores full game state', () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 300,
        hardLandingEnabled: true,
      );

      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5');
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');

      final newProvider =
          LunarLanderProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.startingAltitude, 300);
      expect(newProvider.currentGame!.hardLandingEnabled, true);
      expect(newProvider.currentGame!.totalDartsThrown['p1']! > 0, true);
      // Character assignments should be restored
      expect(newProvider.currentGame!.characterAssignments.length, 3);
      for (final char
          in newProvider.currentGame!.characterAssignments.values) {
        expect(char, isA<LunarLanderCharacter>());
      }
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      // Throw 3 darts to fill the turn → waitingForTakeout = true
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');

      final newProvider =
          LunarLanderProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, true);
    });

    test('resumedSavedGameId is set and clearable', () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, saved[0].id);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('saving a resumed game overwrites the existing save', () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5');

      // First save
      await provider.saveGame(players);
      final saved1 = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');
      expect(saved1, hasLength(1));
      final originalId = saved1[0].id;

      // Restore and throw another dart, then save again
      provider.restoreGame(saved1[0]);
      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5');
      await provider.saveGame(players);

      // Should still be 1 saved game, same id (overwrite)
      final saved2 = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');
      expect(saved2, hasLength(1));
      expect(saved2[0].id, originalId);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      // p1 throws 3 darts, then turn advances
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.advanceTurn();

      // p2 throws 1 dart
      provider.processDartThrow(score: 2, multiplier: 1, sector: 'S2');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');

      final newProvider =
          LunarLanderProvider(apiClient: mockServer.apiClient);
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      // totalTurns is incremented ONCE per turn (on the first dart of the turn).
      // p1 played one full turn (3 darts) → totalTurns = 1.
      // p2 is mid-turn (first dart thrown) → totalTurns = 1.
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      expect(newProvider.currentGame!.totalTurns['p2'], 1);
    });

    test('gameDuration is non-null after restoreGame and null after endGame',
        () async {
      provider.startGame(
        playerIds: ['p1', 'p2'],
        startingAltitude: 100,
        hardLandingEnabled: false,
      );
      provider.processDartThrow(score: 3, multiplier: 1, sector: 'S3');

      await provider.saveGame(players);
      final saved = await SaveGameService(mockServer.apiClient)
          .loadSavedGames('lunar_lander');

      final newProvider =
          LunarLanderProvider(apiClient: mockServer.apiClient);
      // Before restore, gameDuration is null
      expect(newProvider.gameDuration, isNull);

      // restoreGame sets _gameStartTime = DateTime.now()
      newProvider.restoreGame(saved[0]);
      expect(newProvider.gameDuration, isNotNull);
      expect(newProvider.gameDuration!.inSeconds, greaterThanOrEqualTo(0));

      // endGame does not reset _gameStartTime (gameDuration stays non-null
      // until clearGame is called)
      newProvider.endGame();
      expect(newProvider.gameDuration, isNotNull);

      // clearGame clears _gameStartTime → gameDuration becomes null
      newProvider.clearGame();
      expect(newProvider.gameDuration, isNull);
    });
  });
}
