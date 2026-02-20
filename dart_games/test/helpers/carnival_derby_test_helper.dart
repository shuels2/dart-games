import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import '../mocks/mock_carnival_derby_audio_queue_service.dart';

/// Helper class to simulate game screen announcement logic in tests
class CarnivalDerbyTestHelper {
  final HorseRaceProvider provider;
  final MockCarnivalDerbyAudioQueueService audioQueue;
  final List<Player> players;

  bool _gameStartAnnounced = false;

  CarnivalDerbyTestHelper({
    required this.provider,
    required this.audioQueue,
    required this.players,
  });

  /// Call this at the start of the game (simulates first turn announcement)
  void announceGameStart() {
    if (!_gameStartAnnounced) {
      final currentPlayer = provider.getCurrentPlayer(players);
      if (currentPlayer != null) {
        audioQueue.announceTurn(currentPlayer.name);
      }
      _gameStartAnnounced = true;
    }
  }

  /// Process dart throw with announcements
  void processDartThrowWithAnnouncements(String sector) {
    final currentPlayer = provider.getCurrentPlayer(players);
    if (currentPlayer == null) return;

    // Announce turn if this is the first dart
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown == 0 && _gameStartAnnounced) {
      audioQueue.announceTurn(currentPlayer.name);
    }

    // Parse sector to get score and multiplier
    final parsed = _parseSector(sector);

    // Record the throw
    if (parsed != null) {
      provider.processDartThrow(parsed['score'] as int, dartDisplay: sector);
    } else {
      provider.processDartThrow(0, dartDisplay: 'Miss');
    }

    // Announce the dart score
    if (parsed != null) {
      audioQueue.announceDart(parsed['score'] as int, parsed['multiplier'] as String);
    } else {
      audioQueue.announceMiss();
    }

    // Check for bust (in exact score mode)
    if (provider.currentPlayerBusted) {
      audioQueue.announceBust(currentPlayer.name);
    }

    // Announce remove darts if turn is over
    if (provider.shouldPromptTakeout) {
      audioQueue.announceRemoveDarts(currentPlayer.name);
    }

    // Announce winner if game is over
    if (provider.hasWinner) {
      final winner = provider.getWinner(players);
      if (winner != null) {
        // Note: Game complete announcement happens on results screen
        // Winner announcement happens after game complete
        // For tests, we'll just announce the winner here
      }
    }
  }

  /// Skip remaining darts with announcements
  void skipTurn() {
    final currentPlayer = provider.getCurrentPlayer(players);
    if (currentPlayer == null) return;

    final dartsThrown = provider.getCurrentPlayerDartsThrown();

    // Announce turn if this is the first action
    if (dartsThrown == 0 && _gameStartAnnounced) {
      audioQueue.announceTurn(currentPlayer.name);
    }

    provider.skipTurn();

    if (provider.shouldPromptTakeout) {
      audioQueue.announceRemoveDarts(currentPlayer.name);
    }
  }

  /// Handle takeout finished
  void handleTakeoutFinished() {
    provider.handleTakeoutFinished();
  }

  /// Announce game complete (called on results screen)
  void announceGameComplete() {
    audioQueue.announceGameComplete();
  }

  /// Announce winner (called on results screen after game complete)
  void announceWinner() {
    final winner = provider.getWinner(players);
    if (winner != null) {
      audioQueue.announceWinner(winner.name);
    }
  }

  /// Parse dartboard sector string
  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'Bull') {
      return {'score': 50, 'multiplier': 'bullseye'};
    }
    if (sector == '25') {
      return {'score': 25, 'multiplier': 'outer_bull'};
    }
    if (sector == 'None' || sector == 'Miss' || sector.isEmpty) {
      return null;
    }

    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return null;

    final baseNumber = int.parse(match.group(1)!);
    String multiplier = 'single';
    int score = baseNumber;

    if (sector.startsWith('D') || sector.startsWith('d')) {
      multiplier = 'double';
      score = baseNumber * 2;
    } else if (sector.startsWith('T') || sector.startsWith('t')) {
      multiplier = 'triple';
      score = baseNumber * 3;
    }

    return {'score': score, 'multiplier': multiplier};
  }

  /// Verify announcements match expected
  void verifyAnnouncements(List<String> expected) {
    final actual = audioQueue.announcements;
    if (actual.length != expected.length) {
      throw Exception(
        'Announcement count mismatch:\n'
        'Expected ${expected.length} announcements: $expected\n'
        'Got ${actual.length} announcements: $actual'
      );
    }

    for (int i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        throw Exception(
          'Announcement mismatch at index $i:\n'
          'Expected: "${expected[i]}"\n'
          'Got: "${actual[i]}"\n'
          'Full expected: $expected\n'
          'Full actual: $actual'
        );
      }
    }
  }

  /// Clear announcements for next test step
  void clearAnnouncements() {
    audioQueue.clearAnnouncements();
  }
}
