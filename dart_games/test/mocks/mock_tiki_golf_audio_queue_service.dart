import 'package:flutter/foundation.dart';

/// Mock audio queue service for Tiki Golf that captures announcements for
/// testing instead of playing them through the web audio APIs.
class MockTikiGolfAudioQueueService {
  final List<String> _announcements = [];

  /// All announcements that have been queued (in order).
  List<String> get announcements => List.unmodifiable(_announcements);

  /// Clears all captured announcements.
  void clearAnnouncements() => _announcements.clear();

  /// Low-level capture used by every public announce* method.
  void announce(String text) {
    _announcements.add(text);
    debugPrint('Mock Tiki Golf announcement: $text');
  }

  // ─── Per-event methods matching TikiGolfAnnouncementHelper ───────────────────

  void announceGameStart() {
    announce("Welcome to Tiki Golf! Let's tee off!");
  }

  void announceNewHole(int holeNumber, int targetNumber) {
    announce('Hole $holeNumber: Aim for number $targetNumber!');
  }

  void announcePlayerTurn(String playerName) {
    announce("$playerName, you're on the tee!");
  }

  void announceBirdie(String playerName) {
    announce('Birdie! You sunk it on the first dart!');
  }

  void announcePar(String playerName) {
    announce('Par! Solid shot!');
  }

  void announceBogey(String playerName) {
    announce('Bogey! Just squeaked that one in!');
  }

  void announceDoubleBogey(String playerName) {
    announce('Double bogey! Squeaked it out!');
  }

  void announceTripleBogey(String playerName) {
    announce('Triple bogey! Barely hung in!');
  }

  void announceQuadrupleBogey(String playerName) {
    announce('Quadruple bogey! That was a wild one!');
  }

  void announceSplash(String playerName) {
    announce('Splash! Missed them all!');
  }

  void announceMiss() {
    announce('That one went wide!');
  }

  void announceAlmostThere(String playerName) {
    announce('One dart left to save par!');
  }

  void announceMulliganUsed(String playerName) {
    announce('Mulligan! $playerName gets a do-over!');
  }

  void announceMulliganReminder() {
    announce('Splash! Use your mulligan?');
  }

  void announceNearWin(String playerName, int leadBy) {
    announce('Final hole! $playerName leads by $leadBy!');
  }

  /// Mirrors [TikiGolfAnnouncementHelper.announceVictory] so tests can
  /// assert both the 1-winner and N-winner (tie) phrasings.
  void announceVictory(List<String> winnerNames) {
    if (winnerNames.isEmpty) return;
    if (winnerNames.length == 1) {
      announce('${winnerNames.first} wins the Golden Tiki!');
      return;
    }
    announce('${_joinWithAnd(winnerNames)} tie for the Golden Tiki!');
  }

  String _joinWithAnd(List<String> parts) {
    if (parts.length == 1) return parts.single;
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';
    final head = parts.sublist(0, parts.length - 1).join(', ');
    return '$head, and ${parts.last}';
  }

  void announceHoleComplete(int nextHoleNumber) {
    announce('On to hole $nextHoleNumber!');
  }

  void announceRemoveDarts(String playerName) {
    announce('Remove your darts');
  }

  /// Mirrors [TikiGolfAnnouncementHelper.pickAndAnnounceMoment] precedence chain
  /// so integration tests can drive the mock without a real queue service.
  void pickAndAnnounceMoment({
    bool victory = false,
    List<String>? victoryWinnerNames,
    bool holeComplete = false,
    int? holeCompleteNextHole,
    bool mulliganReminder = false,
    bool mulliganUsed = false,
    String? mulliganUsedPlayerName,
    String? score,
    String? scorePlayerName,
    bool almostThere = false,
    String? almostTherePlayerName,
    bool miss = false,
    bool gameStart = false,
    bool playerTurn = false,
    String? playerTurnName,
    bool newHole = false,
    int? newHoleNumber,
    int? newHoleTargetNumber,
    bool nearWin = false,
    String? nearWinPlayerName,
    int? nearWinLeadBy,
  }) {
    if (victory &&
        victoryWinnerNames != null &&
        victoryWinnerNames.isNotEmpty) {
      announceVictory(victoryWinnerNames);
    } else if (holeComplete && holeCompleteNextHole != null) {
      announceHoleComplete(holeCompleteNextHole);
    } else if (mulliganReminder) {
      announceMulliganReminder();
    } else if (mulliganUsed && mulliganUsedPlayerName != null) {
      announceMulliganUsed(mulliganUsedPlayerName);
    } else if (score != null && scorePlayerName != null) {
      switch (score) {
        case 'birdie':
          announceBirdie(scorePlayerName);
          break;
        case 'par':
          announcePar(scorePlayerName);
          break;
        case 'bogey':
          announceBogey(scorePlayerName);
          break;
        case 'doubleBogey':
          announceDoubleBogey(scorePlayerName);
          break;
        case 'tripleBogey':
          announceTripleBogey(scorePlayerName);
          break;
        case 'quadrupleBogey':
          announceQuadrupleBogey(scorePlayerName);
          break;
        case 'splash':
          announceSplash(scorePlayerName);
          break;
      }
    } else if (almostThere && almostTherePlayerName != null) {
      announceAlmostThere(almostTherePlayerName);
    } else if (miss) {
      announceMiss();
    } else if (gameStart) {
      announceGameStart();
    } else if (playerTurn && playerTurnName != null) {
      announcePlayerTurn(playerTurnName);
    } else if (newHole && newHoleNumber != null && newHoleTargetNumber != null) {
      announceNewHole(newHoleNumber, newHoleTargetNumber);
    } else if (nearWin && nearWinPlayerName != null && nearWinLeadBy != null) {
      announceNearWin(nearWinPlayerName, nearWinLeadBy);
    }
  }

  void announceGamePaused() {
    announce(
      'Dartboard disconnected. Game paused. Will resume when the connection is restored.',
    );
  }

  void announceConnectionRestored() {
    announce('Dartboard reconnected. Resume play when ready.');
  }

  void dispose() {
    _announcements.clear();
  }
}
