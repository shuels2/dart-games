import 'package:flutter/foundation.dart';
import 'package:dart_games/services/game_announcement_models.dart';

/// A captured announcement record — text + priority + optional sound asset path.
class CapturedAnnouncement {
  final String text;
  final AudioPriority priority;
  final String? soundAssetPath;

  const CapturedAnnouncement({
    required this.text,
    required this.priority,
    this.soundAssetPath,
  });

  @override
  String toString() =>
      'CapturedAnnouncement(text: "$text", priority: ${priority.name}'
      '${soundAssetPath != null ? ", sound: $soundAssetPath" : ""})';
}

/// Mock audio queue service for Treasure Divide that records every announce
/// call for assertion in tests instead of playing through web audio APIs.
class MockTreasureDivideAudioQueueService {
  final List<CapturedAnnouncement> _captured = [];

  /// All announcements that have been captured (in FIFO order).
  List<CapturedAnnouncement> get captured =>
      List.unmodifiable(_captured);

  /// Convenience: just the announcement texts (for simple text matching).
  List<String> get announcements =>
      _captured.map((a) => a.text).toList();

  /// Clears all captured announcements.
  void clear() => _captured.clear();

  // ─── Low-level capture ────────────────────────────────────────────────────────

  void _record(String text, AudioPriority priority, {String? soundAssetPath}) {
    final a = CapturedAnnouncement(
      text: text,
      priority: priority,
      soundAssetPath: soundAssetPath,
    );
    _captured.add(a);
    debugPrint('[Mock-TD-Audio] "$text" (${priority.name}'
        '${soundAssetPath != null ? ", ${soundAssetPath.split("/").last}" : ""})');
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  void announceGameStart(int rounds) {
    _record(
      'Set sail! $rounds islands to plunder!',
      AudioPriority.statusChange,
      soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
    );
  }

  // ─── Turn announcements ───────────────────────────────────────────────────────

  void announcePlayerTurn(String playerName) {
    _record(
      '$playerName, grab your darts!',
      AudioPriority.turnTransition,
      soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Bell.mp3',
    );
  }

  void announceCrewTurn(String crewName, String playerName) {
    _record(
      'The $crewName are up — $playerName, grab yer darts!',
      AudioPriority.turnTransition,
      soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Bell.mp3',
    );
  }

  // ─── Round transition ─────────────────────────────────────────────────────────

  void announceNewRound({
    required int roundIndex,
    required int target,
    required int totalRounds,
    required bool isLastRound,
    required bool customTargetsEnabled,
  }) {
    if (isLastRound) {
      _record(
        'Final island! Last chance for treasure!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
      );
      return;
    }
    if (target == 25) {
      _record(
        'Treasure Island! Hit the bullseye!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
      );
      return;
    }
    if (target == -2) {
      _record(
        'Triple Treasure round! Hit any triple!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
      );
      return;
    }
    if (target == -1) {
      _record(
        'Double Doubloon round! Hit any double!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
      );
      return;
    }
    if (customTargetsEnabled) {
      _record(
        'The map reveals... $target!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
      );
      return;
    }
    _record(
      'Island ${roundIndex + 1}: Target is $target!',
      AudioPriority.statusChange,
      soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MapUnfurl.mp3',
    );
  }

  // ─── Per-dart moment picker ───────────────────────────────────────────────────

  void pickAndAnnounceMoment({
    required bool wasMatched,
    required String multiplier,
    required String sector,
    required int value,
  }) {
    final isBull = sector == 'Bull' || sector == '25';
    if (wasMatched && isBull) {
      _record(
        'X marks the spot! $value gold!',
        AudioPriority.hitConfirm,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    } else if (wasMatched && multiplier.toLowerCase() == 'triple') {
      _record(
        'Triple treasure! $value gold!',
        AudioPriority.hitConfirm,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    } else if (wasMatched) {
      _record(
        'Plunder! $value gold coins!',
        AudioPriority.hitConfirm,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    } else {
      _record(
        "Splash! That one's in the ocean!",
        AudioPriority.hitConfirm,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-MissSplash.mp3',
      );
    }
  }

  // ─── Turn-end announcements ───────────────────────────────────────────────────

  void announceTurnEndSolo({
    required bool allMissed,
    required bool quarterItEnabled,
    required int scoreBeforeTurn,
  }) {
    if (allMissed && scoreBeforeTurn > 0) {
      if (quarterItEnabled) {
        _record(
          'A storm hits! Three-quarters of the treasure is lost!',
          AudioPriority.statusChange,
          soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Storm.mp3',
        );
      } else {
        _record(
          'Treasure overboard! Half the loot is gone!',
          AudioPriority.statusChange,
          soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Splash.mp3',
        );
      }
    } else {
      _record(
        'The treasure holds! Moving on!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    }
  }

  void announceTurnEndTeam({
    required bool crewAllMissed,
    required int crewTreasureBefore,
    required int crewHaulThisRound,
    required String crewName,
  }) {
    if (crewAllMissed && crewTreasureBefore > 0) {
      _record(
        "All hands lost! The $crewName's treasure spills overboard!",
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Splash.mp3',
      );
    } else {
      _record(
        'The $crewName haul in $crewHaulThisRound gold!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    }
  }

  // ─── Leader change ────────────────────────────────────────────────────────────

  void announceLeaderChange(String name, int value, {required bool isTeam}) {
    if (isTeam) {
      _record(
        'The $name lead with $value gold!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    } else {
      _record(
        '$name leads with $value gold!',
        AudioPriority.statusChange,
        soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-CoinClink.mp3',
      );
    }
  }

  // ─── Remove darts ─────────────────────────────────────────────────────────────

  void announceRemoveDarts() {
    _record('Remove your darts!', AudioPriority.statusChange);
  }

  // ─── Victory ─────────────────────────────────────────────────────────────────

  void announceVictory(String winnerName) {
    _record(
      '$winnerName is crowned Pirate Captain! Richest on the seas!',
      AudioPriority.victory,
      soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Fanfare.mp3',
    );
  }

  void announceTeamVictory(String crewName) {
    _record(
      "The $crewName are crowned Captain's Crew! Richest on the seas!",
      AudioPriority.victory,
      soundAssetPath: 'games/treasure_divide/sounds/TreasureDivide-Fanfare.mp3',
    );
  }

  // ─── Idle / dispose ───────────────────────────────────────────────────────────

  Future<void> whenIdle() => Future.value();

  void dispose() => _captured.clear();
}
