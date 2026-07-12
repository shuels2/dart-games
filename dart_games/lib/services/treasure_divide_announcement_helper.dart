import 'game_announcement_queue_service.dart';
import 'treasure_divide_sound_effects.dart';

/// Treasure Divide announcement helper.
///
/// Wraps [GameAnnouncementQueueService] with convenience methods for every
/// Section 9 announcement event. Implements the full stacking-precedence
/// chain from the orchestrator design document.
///
/// Key design decisions:
/// - Crew names use the crest-derived display name (e.g. "Anchors", "Krakens").
///   The screen passes the already-computed crew name string; this helper does
///   not reference the model directly.
/// - When "Last Round" matches AND a sentinel round also matches (e.g. the last
///   round is the Bull round), ONLY "Last Round" fires — it is more dramatic.
/// - Crew-turn announcements fire on the FIRST player of a crew for that round
///   ("The Anchors are up — Alice, grab yer darts!"). The SECOND player of the
///   same crew gets a standard Player Turn announcement so gameplay pacing stays
///   clear without silencing the hand-off entirely.
/// - For a solo crew (1 member throwing 6 darts): only one Crew Turn
///   announcement fires at the start; no mid-turn hand-off chatter between
///   dart 3 and dart 4.
class TreasureDivideAnnouncementHelper {
  final GameAnnouncementQueueService _queueService;

  TreasureDivideAnnouncementHelper(this._queueService);

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  /// "Set sail! {rounds} islands to plunder!" — fired once at game start.
  void announceGameStart(int rounds) {
    _queueService.announce(
      'Set sail! $rounds islands to plunder!',
      AudioPriority.statusChange,
      soundEffect: TreasureDivideSoundEffects.mapUnfurl,
    );
  }

  // ─── Turn announcements ───────────────────────────────────────────────────────

  /// "{playerName}, grab your darts!" — fired for any solo-mode player turn
  /// and for the SECOND (and beyond) player within a crew in team mode.
  void announcePlayerTurn(String playerName) {
    _queueService.announce(
      '$playerName, grab your darts!',
      AudioPriority.turnTransition,
      soundEffect: TreasureDivideSoundEffects.turnBell,
    );
  }

  /// "The {crewName} are up — {playerName}, grab yer darts!" — fired on the
  /// FIRST player of a crew taking the floor for that round (team mode only).
  void announceCrewTurn(String crewName, String playerName) {
    _queueService.announce(
      'The $crewName are up — $playerName, grab yer darts!',
      AudioPriority.turnTransition,
      soundEffect: TreasureDivideSoundEffects.turnBell,
    );
  }

  // ─── Round transition ─────────────────────────────────────────────────────────

  /// Picks exactly ONE round-transition announcement (highest priority first).
  ///
  /// Precedence:
  /// 1. Last Round — "Final island! Last chance for treasure!"
  /// 2. Bull Round — target == 25 (kTargetBull)
  /// 3. Triple Round — target == -2 (kTargetAnyTriple)
  /// 4. Double Round — target == -1 (kTargetAnyDouble)
  /// 5. Custom reveal — customTargetsEnabled + randomized target
  /// 6. Standard New Round — fallback
  ///
  /// If "Last Round" matches AND a sentinel also matches (e.g. last round is
  /// the Bull round), ONLY "Last Round" fires — the more dramatic message wins.
  void announceNewRound({
    required int roundIndex,  // 0-based
    required int target,
    required int totalRounds,
    required bool isLastRound,
    required bool customTargetsEnabled,
  }) {
    if (isLastRound) {
      _queueService.announce(
        'Final island! Last chance for treasure!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.mapUnfurl,
      );
      return;
    }

    if (target == 25) {
      // kTargetBull
      _queueService.announce(
        'Treasure Island! Hit the bullseye!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.mapUnfurl,
      );
      return;
    }

    if (target == -2) {
      // kTargetAnyTriple
      _queueService.announce(
        'Triple Treasure round! Hit any triple!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.mapUnfurl,
      );
      return;
    }

    if (target == -1) {
      // kTargetAnyDouble
      _queueService.announce(
        'Double Doubloon round! Hit any double!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.mapUnfurl,
      );
      return;
    }

    if (customTargetsEnabled) {
      _queueService.announce(
        'The map reveals... $target!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.mapUnfurl,
      );
      return;
    }

    // Standard fallback (1-indexed round for display)
    _queueService.announce(
      'Island ${roundIndex + 1}: Target is $target!',
      AudioPriority.statusChange,
      soundEffect: TreasureDivideSoundEffects.mapUnfurl,
    );
  }

  // ─── Per-dart moment picker ───────────────────────────────────────────────────

  /// Picks exactly ONE per-dart moment announcement from the ranked precedence
  /// chain and fires it.
  ///
  /// Precedence (highest first):
  /// 1. Bull Hit — sector is Bull/25 AND dart was matched
  /// 2. Big Hit (Triple) — multiplier is 'triple' AND dart was matched
  /// 3. Hit Target — dart was matched (any other sector)
  /// 4. Miss — dart was NOT matched
  ///
  /// Exactly one fires per dart event. [value] is the actual scored value
  /// (already multiplied) — used in the announcement text.
  ///
  /// Remove Darts is NOT part of this method — it is always called
  /// unconditionally by the game screen's takeout handler.
  void pickAndAnnounceMoment({
    required bool wasMatched,
    required String multiplier,   // 'single' | 'double' | 'triple' | 'bull' | 'miss'
    required String sector,       // raw sector string e.g. 'Bull', '25', 'T20', 'S15'
    required int value,           // scored value (0 for miss)
  }) {
    final isBull = sector == 'Bull' || sector == '25';

    if (wasMatched && isBull) {
      // Rank 1: Bull Hit
      _queueService.announce(
        'X marks the spot! $value gold!',
        AudioPriority.hitConfirm,
        soundEffect: TreasureDivideSoundEffects.coinShower,
      );
    } else if (wasMatched && multiplier.toLowerCase() == 'triple') {
      // Rank 2: Big Hit (Triple)
      _queueService.announce(
        'Triple treasure! $value gold!',
        AudioPriority.hitConfirm,
        soundEffect: TreasureDivideSoundEffects.coinShower,
      );
    } else if (wasMatched) {
      // Rank 3: Hit Target
      _queueService.announce(
        'Plunder! $value gold coins!',
        AudioPriority.hitConfirm,
        soundEffect: TreasureDivideSoundEffects.coinClink,
      );
    } else {
      // Rank 4: Miss
      _queueService.announce(
        "Splash! That one's in the ocean!",
        AudioPriority.hitConfirm,
        soundEffect: TreasureDivideSoundEffects.missSplash,
      );
    }
  }

  // ─── Turn-end announcements ───────────────────────────────────────────────────

  /// Picks ONE turn-end announcement for Solo mode.
  ///
  /// Precedence (highest first):
  /// 1. Score Quartered — allMissed AND quarterItEnabled AND hadScoreBefore > 0
  /// 2. Score Halved — allMissed AND !quarterItEnabled AND hadScoreBefore > 0
  /// 3. Safe — at least one hit this turn (allMissed == false)
  ///
  /// If allMissed AND hadScoreBefore == 0, fires Safe (nothing to halve — the
  /// missed-all result is 0÷2=0 which the user can see on screen; a penalty
  /// announcement would be confusing when the score stays at 0).
  void announceTurnEndSolo({
    required bool allMissed,
    required bool quarterItEnabled,
    required int scoreBeforeTurn,
  }) {
    if (allMissed && scoreBeforeTurn > 0) {
      if (quarterItEnabled) {
        _queueService.announce(
          'A storm hits! Three-quarters of the treasure is lost!',
          AudioPriority.statusChange,
          soundEffect: TreasureDivideSoundEffects.quarterStorm,
        );
      } else {
        _queueService.announce(
          'Treasure overboard! Half the loot is gone!',
          AudioPriority.statusChange,
          soundEffect: TreasureDivideSoundEffects.splash,
        );
      }
    } else {
      // Safe — at least one hit, OR score was already 0 (no penalty to announce)
      _queueService.announce(
        'The treasure holds! Moving on!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.coinClink,
      );
    }
  }

  /// Picks ONE turn-end announcement for Team mode.
  ///
  /// Called ONLY after the LAST player of the crew finishes the round.
  /// Mid-crew turn-ends (crew not yet complete) fire NO turn-end announcement.
  ///
  /// Precedence (highest first):
  /// 1. Crew Wipeout — whole crew missed every dart AND crewTreasureBefore > 0
  /// 2. Crew Plunder — at least one crew member had a hit this round
  ///
  /// [crewHaulThisRound] is the SUM of all crew members' hauls for the round.
  /// [crewName] is the pluralised crest-derived name (e.g. "Anchors").
  void announceTurnEndTeam({
    required bool crewAllMissed,
    required int crewTreasureBefore,
    required int crewHaulThisRound,
    required String crewName,
  }) {
    if (crewAllMissed && crewTreasureBefore > 0) {
      // Crew Wipeout — combine into one announcement (no separate Halved on top)
      _queueService.announce(
        "All hands lost! The $crewName's treasure spills overboard!",
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.splash,
      );
    } else {
      // Crew Plunder — at least one hit (crewAllMissed==false) OR score was 0
      _queueService.announce(
        'The $crewName haul in $crewHaulThisRound gold!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.coinShower,
      );
    }
  }

  // ─── Leader change ────────────────────────────────────────────────────────────

  /// Single-leader announcement. Queued AFTER the turn-end announcement.
  ///   Solo: "{name} leads with {value} gold!"
  ///   Team: "The {crewName} lead with {value} gold!"
  void announceLeaderChange(
    String name,
    int value, {
    required bool isTeam,
  }) {
    if (isTeam) {
      _queueService.announce(
        'The $name lead with $value gold!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.coinShower,
      );
    } else {
      _queueService.announce(
        '$name leads with $value gold!',
        AudioPriority.statusChange,
        soundEffect: TreasureDivideSoundEffects.coinShower,
      );
    }
  }

  /// Tied-leaders announcement. Used when ≥ 2 players (Solo) or ≥ 2 crews
  /// (Team) are tied at the top of the leaderboard — we deliberately don't
  /// enumerate names here to keep the read-out short and avoid arbitrarily
  /// picking one. The score itself is enough information.
  void announceLeadersTied(int value) {
    _queueService.announce(
      'The leaders have $value gold!',
      AudioPriority.statusChange,
      soundEffect: TreasureDivideSoundEffects.coinShower,
    );
  }

  // ─── Remove darts ─────────────────────────────────────────────────────────────

  /// "Remove your darts!" — TTS-only, ALWAYS called unconditionally.
  void announceRemoveDarts() {
    _queueService.announce(
      'Remove your darts!',
      AudioPriority.statusChange,
    );
  }

  // ─── Victory ─────────────────────────────────────────────────────────────────

  /// Solo-mode victory. Accepts a list of winning player names so ties are
  /// announced with EVERY name spoken (matches the user's stated UX:
  /// "victory should say all the names").
  ///
  /// - 1 winner:  "{name} is crowned Pirate Captain! Richest on the seas!"
  /// - 2 winners: "Divided treasure! {a} and {b} share the captain's title!"
  /// - 3+ winners: "Divided treasure! {a}, {b}, and {c} share the captain's title!"
  void announceVictory(List<String> winnerNames) {
    if (winnerNames.isEmpty) return;
    if (winnerNames.length == 1) {
      _queueService.announce(
        '${winnerNames.first} is crowned Pirate Captain! '
            'Richest on the seas!',
        AudioPriority.victory,
        soundEffect: TreasureDivideSoundEffects.victoryFanfare,
      );
      return;
    }
    final names = _joinWithAnd(winnerNames);
    _queueService.announce(
      "Divided treasure! $names share the captain's title!",
      AudioPriority.victory,
      soundEffect: TreasureDivideSoundEffects.victoryFanfare,
    );
  }

  /// Team-mode victory. Accepts a list of winning crew names so ties are
  /// announced with EVERY crew spoken.
  ///
  /// - 1 crew:  "The {crew} are crowned Captain's Crew! Richest on the seas!"
  /// - 2 crews: "Divided treasure! The {a} and the {b} share the captain's title!"
  /// - 3+ crews: "Divided treasure! The {a}, the {b}, and the {c} share the captain's title!"
  void announceTeamVictory(List<String> crewNames) {
    if (crewNames.isEmpty) return;
    if (crewNames.length == 1) {
      _queueService.announce(
        "The ${crewNames.first} are crowned Captain's Crew! "
            'Richest on the seas!',
        AudioPriority.victory,
        soundEffect: TreasureDivideSoundEffects.victoryFanfare,
      );
      return;
    }
    // Each crew gets its own "the" prefix so the read-out sounds natural.
    final prefixed = crewNames.map((c) => 'the $c').toList();
    final crews = _joinWithAnd(prefixed);
    _queueService.announce(
      "Divided treasure! $crews share the captain's title!",
      AudioPriority.victory,
      soundEffect: TreasureDivideSoundEffects.victoryFanfare,
    );
  }

  /// Joins a list of strings with commas + "and" at the end:
  /// ['A']            => 'A'
  /// ['A', 'B']       => 'A and B'
  /// ['A', 'B', 'C']  => 'A, B, and C' (Oxford comma)
  String _joinWithAnd(List<String> parts) {
    if (parts.length == 1) return parts.single;
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';
    final head = parts.sublist(0, parts.length - 1).join(', ');
    return '$head, and ${parts.last}';
  }

  // ─── Idle / dispose ───────────────────────────────────────────────────────────

  Future<void> whenIdle() => _queueService.whenIdle();

  void dispose() {
    _queueService.dispose();
  }
}
