import 'package:flutter/foundation.dart';

/// Mock audio queue service that captures announcements for testing
/// instead of actually playing them through web audio APIs
class MockCarnivalDerbyAudioQueueService {
  final List<String> _announcements = [];

  /// Get all announcements that have been queued
  List<String> get announcements => List.unmodifiable(_announcements);

  /// Clear all captured announcements
  void clearAnnouncements() {
    _announcements.clear();
  }

  /// Mock implementation of announce - just captures the text
  void announce(String text) {
    _announcements.add(text);
    debugPrint('Mock announcement: $text');
  }

  // Game-specific announcement methods (matching real service)

  void announceTurn(String playerName) {
    announce('$playerName, it\'s your turn');
  }

  void announceDart(int score, String multiplier) {
    String text;
    if (multiplier == 'bullseye') {
      text = 'Bullseye! 50 points!';
    } else if (multiplier == 'outer_bull') {
      text = '25. Outer bull.';
    } else if (multiplier == 'miss') {
      text = 'Miss. No score.';
    } else {
      // Regular scoring
      final baseScore = multiplier == 'double' ? score ~/ 2
                      : multiplier == 'triple' ? score ~/ 3
                      : score;
      final multiplierText = multiplier == 'double' ? 'double'
                           : multiplier == 'triple' ? 'triple'
                           : '';

      if (multiplierText.isEmpty) {
        text = '$score';
      } else {
        text = '$multiplierText $baseScore for $score';
      }
    }
    announce(text);
  }

  void announceMiss() {
    announce('Miss');
  }

  void announceBust(String playerName) {
    announce('$playerName, you busted and your turn is over');
  }

  void announceRemoveDarts(String playerName) {
    announce('$playerName, remove your darts');
  }

  void announceGameComplete() {
    announce('The game is complete');
  }

  void announceWinner(String playerName) {
    announce('$playerName is the winner');
  }

  void dispose() {
    _announcements.clear();
  }
}
