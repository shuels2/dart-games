import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/clockwork_quest_game.dart';
import 'package:dart_games/providers/clockwork_quest_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/services/victory_music_service.dart';
import '../../../shared/mock_api_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clockwork Quest - User Management Integration', () {
    late MockApiServer mockServer;
    late PlayerProvider playerProvider;
    late ClockworkQuestProvider gameProvider;

    setUp(() async {
      mockServer = MockApiServer();
      playerProvider = PlayerProvider();
      playerProvider.initialize(mockServer.apiClient);
      gameProvider = ClockworkQuestProvider();

      VictoryMusicService().initializeApi(mockServer.apiClient);
      VictoryMusicService().resetForTesting();

      await playerProvider.loadPlayers();
    });

    test('game records winner stats and victory music triggers on victory', () async {
      final p1 = Player.create(name: 'Player 1');
      final p2 = Player.create(name: 'Player 2');
      await playerProvider.savePlayer(p1);
      await playerProvider.savePlayer(p2);

      gameProvider.startGame([p1, p2], false, false, 1);
      final game = gameProvider.currentGame!;
      expect(game.startedAt, isNotNull);

      // Directly set win condition
      game.winnerId = p1.id;
      game.state = ClockworkQuestGameState.finished;

      final gameDuration = DateTime.now().difference(game.startedAt);
      expect(game.winnerId, p1.id);

      for (final playerId in game.playerIds) {
        final isWinner = playerId == game.winnerId;
        await playerProvider.updatePlayerStats(
          playerId,
          won: isWinner,
          gameName: 'Clockwork Quest',
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
      expect(winner.gameHistory.first.gameName, 'Clockwork Quest');
      expect(winner.gameHistory.first.duration, isNotNull);

      final loser = playerProvider.getPlayerById(p2.id)!;
      expect(loser.gamesPlayed, 1);
      expect(loser.gamesWon, 0);
      expect(loser.gameHistory.length, 1);
      expect(loser.gameHistory.first.gameName, 'Clockwork Quest');

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

      gameProvider.startGame([p1, p2, p3], false, false, 1);
      final game = gameProvider.currentGame!;

      game.winnerId = p1.id;
      game.state = ClockworkQuestGameState.finished;

      final gameDuration = DateTime.now().difference(game.startedAt);

      for (final playerId in game.playerIds) {
        await playerProvider.updatePlayerStats(
          playerId,
          won: playerId == game.winnerId,
          gameName: 'Clockwork Quest',
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
        expect(updated.gameHistory.first.gameName, 'Clockwork Quest');
      }
      expect(playerProvider.getPlayerById(p1.id)!.gamesWon, 1);
      expect(playerProvider.getPlayerById(p2.id)!.gamesWon, 0);
      expect(playerProvider.getPlayerById(p3.id)!.gamesWon, 0);
    });

    test('multi-lap game records win correctly', () async {
      final p1 = Player.create(name: 'Lapper');
      final p2 = Player.create(name: 'Opponent');
      await playerProvider.savePlayer(p1);
      await playerProvider.savePlayer(p2);

      gameProvider.startGame([p1, p2], false, false, 2);
      final game = gameProvider.currentGame!;

      game.winnerId = p1.id;
      game.state = ClockworkQuestGameState.finished;

      final gameDuration = DateTime.now().difference(game.startedAt);
      await playerProvider.updatePlayerStats(
        p1.id,
        won: true,
        gameName: 'Clockwork Quest',
        gameDuration: gameDuration,
        dartThrows: 0,
        turns: 0,
        playerCount: 2,
      );
      await playerProvider.updatePlayerStats(
        p2.id,
        won: false,
        gameName: 'Clockwork Quest',
        gameDuration: gameDuration,
        dartThrows: 0,
        turns: 0,
        playerCount: 2,
      );

      await playerProvider.loadPlayers();

      final winner = playerProvider.getPlayerById(p1.id)!;
      expect(winner.gamesWon, 1);
      expect(winner.gameHistory.first.gameName, 'Clockwork Quest');
    });

    test('stats persist across provider reload', () async {
      final player = Player.create(name: 'Persistent');
      final opp = Player.create(name: 'Opponent');
      await playerProvider.savePlayer(player);
      await playerProvider.savePlayer(opp);

      gameProvider.startGame([player, opp], false, false, 1);
      final game = gameProvider.currentGame!;
      game.winnerId = player.id;
      game.state = ClockworkQuestGameState.finished;

      final gameDuration = DateTime.now().difference(game.startedAt);
      await playerProvider.updatePlayerStats(
        player.id,
        won: true,
        gameName: 'Clockwork Quest',
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
      expect(loaded.gameHistory.first.gameName, 'Clockwork Quest');
    });
  });
}
