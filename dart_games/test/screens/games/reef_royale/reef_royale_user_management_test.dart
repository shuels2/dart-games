import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/services/victory_music_service.dart';
import '../../../shared/mock_api_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reef Royale - User Management Integration', () {
    late MockApiServer mockServer;
    late PlayerProvider playerProvider;
    late ReefRoyaleProvider gameProvider;

    setUp(() async {
      mockServer = MockApiServer();
      playerProvider = PlayerProvider();
      playerProvider.initialize(mockServer.apiClient);
      gameProvider = ReefRoyaleProvider();

      VictoryMusicService().initializeApi(mockServer.apiClient);
      VictoryMusicService().resetForTesting();

      await playerProvider.loadPlayers();
    });

    test('game records winner stats and victory music triggers on victory', () async {
      final p1 = Player.create(name: 'Player 1');
      final p2 = Player.create(name: 'Player 2');
      await playerProvider.savePlayer(p1);
      await playerProvider.savePlayer(p2);

      gameProvider.startGame(
        [p1, p2],
        ReefRoyaleGameMode.standard,
        false, false, false, false, true, false, 10,
      );
      final game = gameProvider.currentGame!;
      expect(game.startedAt, isNotNull);

      // Directly set win condition
      game.state = ReefRoyaleGameState.finished;
      game.winnerId = p1.id;
      game.winnerIds = [p1.id];

      final gameDuration = DateTime.now().difference(game.startedAt);
      final winnerIds = game.winnerIds ?? [];
      expect(winnerIds, contains(p1.id));

      for (final playerId in game.playerIds) {
        await playerProvider.updatePlayerStats(
          playerId,
          won: winnerIds.contains(playerId),
          gameName: 'Reef Royale',
          gameDuration: gameDuration,
          dartThrows: game.totalDartsThrown[playerId] ?? 0,
          turns: game.totalTurns[playerId] ?? 0,
          playerCount: game.playerIds.length,
        );
      }

      await playerProvider.loadPlayers();

      final winner = playerProvider.getPlayerById(p1.id)!;
      expect(winner.gamesPlayed, 1);
      expect(winner.gamesWon, 1);
      expect(winner.gameHistory.length, 1);
      expect(winner.gameHistory.first.gameName, 'Reef Royale');
      expect(winner.gameHistory.first.duration, isNotNull);

      final loser = playerProvider.getPlayerById(p2.id)!;
      expect(loser.gamesPlayed, 1);
      expect(loser.gamesWon, 0);
      expect(loser.gameHistory.length, 1);
      expect(loser.gameHistory.first.gameName, 'Reef Royale');

      // Victory music: no custom music → null (results screen falls back to default URL)
      final musicService = VictoryMusicService();
      final nullSource = await musicService.getRandomMusicSource();
      expect(nullSource, isNull);

      // With custom music configured → URL returned
      await musicService.addMusicFile(
        fileName: 'victory.mp3',
        fileBytes: Uint8List.fromList([1, 2, 3]),
      );
      musicService.resetForTesting();
      final musicSource = await musicService.getRandomMusicSource();
      expect(musicSource, isNotNull);
      expect(musicSource, contains('/api/v1/music/'));
    });

    test('all players get game history entries on completion', () async {
      final p1 = Player.create(name: 'Alice');
      final p2 = Player.create(name: 'Bob');
      final p3 = Player.create(name: 'Charlie');
      await playerProvider.savePlayer(p1);
      await playerProvider.savePlayer(p2);
      await playerProvider.savePlayer(p3);

      gameProvider.startGame(
        [p1, p2, p3],
        ReefRoyaleGameMode.standard,
        false, false, false, false, true, false, 10,
      );
      final game = gameProvider.currentGame!;

      game.state = ReefRoyaleGameState.finished;
      game.winnerId = p1.id;
      game.winnerIds = [p1.id];

      final gameDuration = DateTime.now().difference(game.startedAt);
      final winnerIds = game.winnerIds ?? [];

      for (final playerId in game.playerIds) {
        await playerProvider.updatePlayerStats(
          playerId,
          won: winnerIds.contains(playerId),
          gameName: 'Reef Royale',
          gameDuration: gameDuration,
          dartThrows: game.totalDartsThrown[playerId] ?? 0,
          turns: game.totalTurns[playerId] ?? 0,
          playerCount: game.playerIds.length,
        );
      }

      await playerProvider.loadPlayers();

      for (final player in [p1, p2, p3]) {
        final updated = playerProvider.getPlayerById(player.id)!;
        expect(updated.gamesPlayed, 1);
        expect(updated.gameHistory.length, 1);
        expect(updated.gameHistory.first.gameName, 'Reef Royale');
      }
      expect(playerProvider.getPlayerById(p1.id)!.gamesWon, 1);
      expect(playerProvider.getPlayerById(p2.id)!.gamesWon, 0);
      expect(playerProvider.getPlayerById(p3.id)!.gamesWon, 0);
    });

    test('tied winners all receive win credit', () async {
      final p1 = Player.create(name: 'Alice');
      final p2 = Player.create(name: 'Bob');
      await playerProvider.savePlayer(p1);
      await playerProvider.savePlayer(p2);

      gameProvider.startGame(
        [p1, p2],
        ReefRoyaleGameMode.standard,
        false, false, false, false, true, false, 10,
      );
      final game = gameProvider.currentGame!;

      // Tied win scenario
      game.state = ReefRoyaleGameState.finished;
      game.winnerId = p1.id;
      game.winnerIds = [p1.id, p2.id];

      final gameDuration = DateTime.now().difference(game.startedAt);
      final winnerIds = game.winnerIds ?? [];

      for (final playerId in game.playerIds) {
        await playerProvider.updatePlayerStats(
          playerId,
          won: winnerIds.contains(playerId),
          gameName: 'Reef Royale',
          gameDuration: gameDuration,
          dartThrows: 0,
          turns: 0,
          playerCount: 2,
        );
      }

      await playerProvider.loadPlayers();

      expect(playerProvider.getPlayerById(p1.id)!.gamesWon, 1);
      expect(playerProvider.getPlayerById(p2.id)!.gamesWon, 1);
    });

    test('stats persist across provider reload', () async {
      final player = Player.create(name: 'Persistent');
      final opp = Player.create(name: 'Opponent');
      await playerProvider.savePlayer(player);
      await playerProvider.savePlayer(opp);

      gameProvider.startGame(
        [player, opp],
        ReefRoyaleGameMode.standard,
        false, false, false, false, true, false, 10,
      );
      final game = gameProvider.currentGame!;
      game.state = ReefRoyaleGameState.finished;
      game.winnerId = player.id;
      game.winnerIds = [player.id];

      final gameDuration = DateTime.now().difference(game.startedAt);
      await playerProvider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Reef Royale',
        gameDuration: gameDuration,
        dartThrows: 0,
        turns: 0,
        playerCount: 2,
      );

      final newProvider = PlayerProvider();
      newProvider.initialize(mockServer.apiClient);
      await newProvider.loadPlayers();

      final loaded = newProvider.getPlayerById(player.id)!;
      expect(loaded.gamesPlayed, 1);
      expect(loaded.gamesWon, 1);
      expect(loaded.gameHistory.first.gameName, 'Reef Royale');
    });
  });
}
