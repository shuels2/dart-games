import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/player_provider.dart';

/// Utilities for player management in tests
class PlayerTestUtils {
  /// Create multiple test players with sequential names
  static List<Player> createPlayers(int count, {String namePrefix = 'Player'}) {
    return List.generate(
      count,
      (i) => Player.create(name: '$namePrefix ${i + 1}'),
    );
  }

  /// Create and save multiple players to provider
  static Future<List<Player>> createAndSavePlayers(
    PlayerProvider provider,
    int count,
    {String namePrefix = 'Player'}
  ) async {
    final players = createPlayers(count, namePrefix: namePrefix);
    for (final player in players) {
      await provider.savePlayer(player);
    }
    return players;
  }

  /// Verify player has expected stats
  static void verifyPlayerStats(
    Player player, {
    required int gamesPlayed,
    required int gamesWon,
    int? historyLength,
    String? lastGameName,
    Duration? lastGameDuration,
  }) {
    expect(player.gamesPlayed, gamesPlayed,
      reason: '${player.name} should have played $gamesPlayed games');
    expect(player.gamesWon, gamesWon,
      reason: '${player.name} should have won $gamesWon games');

    if (historyLength != null) {
      expect(player.gameHistory.length, historyLength,
        reason: '${player.name} should have $historyLength history entries');
    }

    if (lastGameName != null && player.gameHistory.isNotEmpty) {
      expect(player.gameHistory.last.gameName, lastGameName,
        reason: '${player.name} last game should be $lastGameName');
    }

    if (lastGameDuration != null && player.gameHistory.isNotEmpty) {
      expect(player.gameHistory.last.duration, lastGameDuration,
        reason: '${player.name} last game duration mismatch');
    }
  }

  /// Find player by ID from provider
  static Player? getPlayerById(PlayerProvider provider, String playerId) {
    return provider.getPlayerById(playerId);
  }

  /// Reload players from storage and return specific player
  static Future<Player?> reloadAndGetPlayer(
    PlayerProvider provider,
    String playerId,
  ) async {
    await provider.loadPlayers();
    return getPlayerById(provider, playerId);
  }
}
