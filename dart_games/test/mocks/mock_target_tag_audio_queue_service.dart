import 'package:flutter/foundation.dart';

/// Mock audio queue service that captures announcements for testing
/// instead of actually playing them through web audio APIs
class MockTargetTagAudioQueueService {
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

  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    if (isMiss) {
      announce('Miss');
      return;
    }

    String text = '';
    if (number == 50) {
      text = 'Bullseye!';
    } else if (number == 25) {
      text = 'Outer bull';
    } else {
      final mult = multiplier == 'double' ? 'Double' : (multiplier == 'triple' ? 'Triple' : 'Single');
      text = '$mult $number';
    }
    announce(text);
  }

  void announceShieldGained(String playerName, int shields, int shieldMax) {
    announce('$shields shields');
  }

  void announceTaggedIn(List<String> playerNames) {
    String names;
    if (playerNames.length == 1) {
      names = '${playerNames[0]} is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]} are';
    } else {
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last} are';
    }
    announce('JACKPOT! $names TAGGED IN!');
  }

  void announceTaggedOut(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are';
    } else {
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are';
    }
    announce('Shield compromised! $names $verb back on the hunt.');
  }

  void announceLowShields(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = '${playerNames[0]}\'s';
      verb = 'are';  // Changed from 'is' to 'are' for consistency
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}\'s';
      verb = 'are';
    } else {
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}\'s';
      verb = 'are';
    }
    announce('Warning! $names shields $verb almost gone!');
  }

  void announceVulnerable(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are';
    } else {
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are';
    }
    announce('DANGER! $names $verb vulnerable! One more hit and you\'re out!');
  }

  void announceEliminated(List<String> playerNames) {
    String names;
    if (playerNames.length == 1) {
      names = '${playerNames[0]} is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]} are';
    } else {
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last} are';
    }
    announce('$names Tagged Out! Better luck next time!');
  }

  void announceSuccessfulTag() {
    announce('Tag! Got \'em!');
  }

  void announceTurn(String playerName) {
    announce('$playerName, your turn');
  }

  void announceGameStart() {
    announce('Welcome to Target Tag! Fill those shields!');
  }

  void announceWinner(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is the Target Tag Champion';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are the Target Tag Champions';
    } else {
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are the Target Tag Champions';
    }
    announce('GAME OVER! $names $verb!');
  }

  void announceRemoveDarts() {
    announce('Remove your darts');
  }

  void dispose() {
    _announcements.clear();
  }
}
