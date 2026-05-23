import 'game_announcement_queue_service.dart';
import 'tiki_golf_sound_effects.dart';

/// Tiki Golf announcement helper.
///
/// Wraps [GameAnnouncementQueueService] with convenience methods for every
/// Section 9 announcement event.  The [pickAndAnnounceMoment] method
/// implements the stacking-precedence chain from the orchestrator design.
class TikiGolfAnnouncementHelper {
  final GameAnnouncementQueueService _queueService;

  TikiGolfAnnouncementHelper(this._queueService);

  // ─── Individual announcement methods ─────────────────────────────────────────

  void announceGameStart() {
    _queueService.announce(
      "Welcome to Tiki Golf! Let's tee off!",
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.ukulele,
    );
  }

  void announceNewHole(int holeNumber, int targetNumber) {
    _queueService.announce(
      'Hole $holeNumber: Aim for number $targetNumber!',
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.tikiChime,
    );
  }

  void announcePlayerTurn(String playerName) {
    _queueService.announce(
      "$playerName, you're on the tee!",
      AudioPriority.turnTransition,
      soundEffect: TikiGolfSoundEffects.ukulele,
    );
  }

  void announceBirdie(String playerName) {
    _queueService.announce(
      'Birdie! $playerName sinks it on the first dart!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.clap,
    );
  }

  void announcePar(String playerName) {
    _queueService.announce(
      'Par! Solid shot, $playerName!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.ballDrop,
    );
  }

  void announceBogey(String playerName) {
    _queueService.announce(
      'Bogey! Just squeaked that one in!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.putt,
    );
  }

  void announceDoubleBogey(String playerName) {
    _queueService.announce(
      'Double bogey! Squeaked it out, $playerName!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.putt,
    );
  }

  void announceTripleBogey(String playerName) {
    _queueService.announce(
      'Triple bogey! Barely hung in, $playerName!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.putt,
    );
  }

  void announceQuadrupleBogey(String playerName) {
    _queueService.announce(
      'Quadruple bogey! That was a wild one, $playerName!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.putt,
    );
  }

  void announceSplash(String playerName) {
    _queueService.announce(
      'Splash! $playerName misses them all!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.splash,
    );
  }

  void announceMiss() {
    _queueService.announce(
      'That one went wide!',
      AudioPriority.hitConfirm,
      soundEffect: TikiGolfSoundEffects.splash,
    );
  }

  void announceAlmostThere(String playerName) {
    _queueService.announce(
      '$playerName, one dart left to save par!',
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.tikiChime,
    );
  }

  void announceMulliganUsed(String playerName) {
    _queueService.announce(
      'Mulligan! $playerName gets a do-over!',
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.mulligan,
    );
  }

  void announceMulliganReminder() {
    _queueService.announce(
      'Splash! Use your mulligan?',
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.tikiChime,
    );
  }

  void announceNearWin(String playerName, int leadBy) {
    _queueService.announce(
      'Final hole! $playerName leads by $leadBy!',
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.ukulele,
    );
  }

  void announceVictory(String winnerName) {
    _queueService.announce(
      '$winnerName wins the Golden Tiki!',
      AudioPriority.victory,
      soundEffect: TikiGolfSoundEffects.victoryFanfare,
    );
  }

  void announceHoleComplete(int nextHoleNumber) {
    _queueService.announce(
      'On to hole $nextHoleNumber!',
      AudioPriority.statusChange,
      soundEffect: TikiGolfSoundEffects.tikiChime,
    );
  }

  /// Unconditional remove-darts announcement.  Called by the game screen on
  /// every turn-end, OUTSIDE the precedence chain.
  void announceRemoveDarts(String playerName) {
    _queueService.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // ─── Master moment selector ───────────────────────────────────────────────────

  /// Picks exactly ONE moment announcement from the ranked precedence chain and
  /// fires it.  The caller provides all fact flags; this method applies the
  /// if/else-if cascade (rank 1 → rank 11) and calls the winning method.
  ///
  /// Remove Darts is NOT part of this method — it is always called
  /// unconditionally by the game screen's takeout handler.
  ///
  /// [victory]          rank 1 — game-end win caused by this dart
  /// [holeComplete]     rank 2 — last player's last dart on the current hole
  /// [mulliganReminder] rank 3 — Splash + mulligan available
  /// [mulliganUsed]     rank 4 — useMulligan() was just invoked
  /// [score]            rank 5 — turn-end score: 'birdie'|'par'|'bogey'|'splash'|null
  /// [almostThere]      rank 6 — penultimate dart, no hit
  /// [miss]             rank 7 — mid-turn non-hit dart (no turn-end)
  /// [gameStart]        rank 8 — game lifecycle start
  /// [playerTurn]       rank 9 — turn-change
  /// [newHole]          rank 10 — hole-change
  /// [nearWin]          rank 11 — start of final hole, leader is far ahead
  ///
  /// Per-event params are required only when the corresponding flag is true.
  void pickAndAnnounceMoment({
    // Rank 1
    bool victory = false,
    String? victoryWinnerName,
    // Rank 2
    bool holeComplete = false,
    int? holeCompleteNextHole,
    // Rank 3
    bool mulliganReminder = false,
    // Rank 4
    bool mulliganUsed = false,
    String? mulliganUsedPlayerName,
    // Rank 5
    String? score, // 'birdie' | 'par' | 'bogey' | 'doubleBogey' | 'tripleBogey' | 'quadrupleBogey' | 'splash' | null
    String? scorePlayerName,
    // Rank 6
    bool almostThere = false,
    String? almostTherePlayerName,
    // Rank 7
    bool miss = false,
    // Rank 8
    bool gameStart = false,
    // Rank 9
    bool playerTurn = false,
    String? playerTurnName,
    // Rank 10
    bool newHole = false,
    int? newHoleNumber,
    int? newHoleTargetNumber,
    // Rank 11
    bool nearWin = false,
    String? nearWinPlayerName,
    int? nearWinLeadBy,
  }) {
    // ── Rank 1: Victory ────────────────────────────────────────────────────────
    if (victory && victoryWinnerName != null) {
      announceVictory(victoryWinnerName);
    }
    // ── Rank 2: Hole Complete ──────────────────────────────────────────────────
    else if (holeComplete && holeCompleteNextHole != null) {
      announceHoleComplete(holeCompleteNextHole);
    }
    // ── Rank 3: Mulligan Reminder ──────────────────────────────────────────────
    else if (mulliganReminder) {
      announceMulliganReminder();
    }
    // ── Rank 4: Mulligan Used ──────────────────────────────────────────────────
    else if (mulliganUsed && mulliganUsedPlayerName != null) {
      announceMulliganUsed(mulliganUsedPlayerName);
    }
    // ── Rank 5: Score announcement ─────────────────────────────────────────────
    else if (score != null && scorePlayerName != null) {
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
    }
    // ── Rank 6: Almost there! ──────────────────────────────────────────────────
    else if (almostThere && almostTherePlayerName != null) {
      announceAlmostThere(almostTherePlayerName);
    }
    // ── Rank 7: Miss (mid-turn) ────────────────────────────────────────────────
    else if (miss) {
      announceMiss();
    }
    // ── Rank 8: Game Start ────────────────────────────────────────────────────
    else if (gameStart) {
      announceGameStart();
    }
    // ── Rank 9: Player Turn ───────────────────────────────────────────────────
    else if (playerTurn && playerTurnName != null) {
      announcePlayerTurn(playerTurnName);
    }
    // ── Rank 10: New Hole ─────────────────────────────────────────────────────
    else if (newHole &&
        newHoleNumber != null &&
        newHoleTargetNumber != null) {
      announceNewHole(newHoleNumber, newHoleTargetNumber);
    }
    // ── Rank 11: Near Win ─────────────────────────────────────────────────────
    else if (nearWin && nearWinPlayerName != null && nearWinLeadBy != null) {
      announceNearWin(nearWinPlayerName, nearWinLeadBy);
    }
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  void dispose() {
    _queueService.dispose();
  }
}
