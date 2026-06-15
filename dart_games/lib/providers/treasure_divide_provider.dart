import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/treasure_divide_game.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';

class TreasureDivideProvider extends ChangeNotifier {
  TreasureDivideGame? _currentGame;
  String? _resumedSavedGameId;
  bool _saving = false;

  // Accumulates the haul for the current player's in-progress turn.
  int _currentTurnHaul = 0;

  // ─── Last-dart state (for announcement helper) ────────────────────────────────
  bool _lastDartWasMatched = false;
  int _lastDartScore = 0;
  String _lastDartMultiplier = 'miss';
  String _lastDartSector = 'Miss';

  // ─── Score-before-turn (for halve/quarter announcement decision) ──────────────
  int _scoreBeforeCurrentTurn = 0;

  // ─── Team round-completion state (for team turn-end announcements) ────────────
  String? _justCompletedCrewId;
  int _justCompletedCrewHaul = 0;

  // ─── Round-advance flag (for round-transition announcement) ──────────────────
  bool _roundAdvancedOnLastTakeout = false;
  int _previousRoundIndex = 0;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  TreasureDivideGame? get currentGame => _currentGame;

  bool get isGameActive =>
      _currentGame?.state == TreasureDivideGameState.playing;

  bool get shouldPromptTakeout => _currentGame?.shouldPromptTakeout ?? false;

  bool get hasWinner => _currentGame?.hasWinner ?? false;

  String? get currentPlayerId => _currentGame?.currentPlayerId;

  String? get currentTeamId => _currentGame?.activeTeamId;

  String? get currentTeamCrestPath {
    final game = _currentGame;
    if (game == null || game.gameMode != TreasureDivideGameMode.team) return null;
    final tid = game.activeTeamId;
    if (tid == null) return null;
    final idx = game.teamPlayers.keys.toList().indexOf(tid);
    if (idx < 0 || idx >= game.teamCrestPaths.length) return null;
    return game.teamCrestPaths[idx];
  }

  String? get resumedSavedGameId => _resumedSavedGameId;

  /// The winning crew's display name (team mode). Returns null if no winner yet.
  String? get winningCrewName {
    final game = _currentGame;
    if (game == null || game.winnerTeamIds.isEmpty) return null;
    return crewNameForTeam(game.winnerTeamIds.first);
  }

  /// Returns a human-readable pluralised crew name derived from the crest image
  /// path for [teamId]. Example: "Anchor.png" → "Anchors".
  /// Falls back to "Crew {N}" if the crest path is unrecognised.
  String crewNameForTeam(String teamId) {
    final game = _currentGame;
    if (game == null) return teamId;
    final teamIds = game.teamPlayers.keys.toList();
    final idx = teamIds.indexOf(teamId);
    if (idx < 0 || idx >= game.teamCrestPaths.length) return 'Crew ${idx + 1}';
    final path = game.teamCrestPaths[idx];
    // Derive name from the filename without extension.
    final filename = path.split('/').last.replaceAll('.png', '');
    // Map known crest filenames to their pluralised names.
    const crestNames = {
      'CrossedCutlasses': 'Cutlasses',
      'GoldDoubloon': 'Doubloons',
      'CompassRose': 'Compasses',
      'ShipsWheel': 'Helmsmen',
      'Anchor': 'Anchors',
      'Kraken': 'Krakens',
    };
    return crestNames[filename] ?? 'Crew ${idx + 1}';
  }

  // ─── Announcement-helper accessors (read-only, no game-logic changes) ────────

  /// Whether the last dart thrown by the current player matched the round
  /// target. The screen uses this to drive [pickAndAnnounceMoment].
  ///
  /// Returns true when [_currentTurnHaul] increased vs. the value BEFORE the
  /// most recent dart. Because [_currentTurnHaul] is always ≥ 0 and only
  /// grows on a hit, the screen can compute this by reading [lastDartScore].
  /// Exposed as a separate getter so the screen doesn't need to do arithmetic.
  bool get lastDartWasMatched => _lastDartWasMatched;

  /// The scored value of the most recent dart (post-multiplier, 0 for miss).
  int get lastDartScore => _lastDartScore;

  /// The raw multiplier string of the most recent dart
  /// ('single', 'double', 'triple', 'bull', 'miss').
  String get lastDartMultiplier => _lastDartMultiplier;

  /// The raw sector string of the most recent dart (e.g. 'S20', 'T15', 'Bull').
  String get lastDartSector => _lastDartSector;

  /// The player's cumulative total BEFORE the current turn started.
  /// Used by the screen to decide whether to announce Halved / Quartered.
  int get scoreBeforeCurrentTurn => _scoreBeforeCurrentTurn;

  /// The amount of gold accumulated by the current player on the turn
  /// in progress. Cleared on takeout. Used by the game screen so the
  /// active player's gold total updates after every dart instead of
  /// waiting for the end of the turn.
  int get currentTurnHaul => _currentTurnHaul;

  /// Whether the current player has hit at least one dart so far this turn.
  bool get currentTurnHadAtLeastOneHit => _currentTurnHaul > 0;

  /// Whether all darts thrown so far this turn were misses (0 haul).
  bool get currentTurnAllMissed =>
      (_currentGame?.dartsThrown ?? 0) > 0 && _currentTurnHaul == 0;

  /// The team ID of the crew that JUST completed the round (set during
  /// [_advanceTeamPlayer] when a crew finishes — cleared at the start of the
  /// next turn). Used by the screen for team turn-end announcements.
  String? get justCompletedCrewId => _justCompletedCrewId;

  /// The crew haul for [_justCompletedCrewId] for the round that just ended.
  int get justCompletedCrewHaul => _justCompletedCrewHaul;

  /// Whether the round index advanced during the last [handleTakeoutFinished]
  /// call. The screen uses this to queue round-transition announcements.
  bool get roundAdvancedOnLastTakeout => _roundAdvancedOnLastTakeout;

  /// The round index BEFORE the last [handleTakeoutFinished] advanced it.
  /// Used together with [roundAdvancedOnLastTakeout] to compute what the
  /// new round's properties are.
  int get previousRoundIndex => _previousRoundIndex;

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  // ─── randomDistribution ──────────────────────────────────────────────────────

  /// Pure function. Implements the spec Section 5 Random Team Distribution table
  /// for N players in 3..10.
  ///
  /// Rule: pair-fill, capped at 5 crews. Every crew is size 2; one leftover
  /// pirate (if N is odd) forms a 1-player solo crew at the end.
  ///
  /// Returns ({teamCount, sizes}) where sizes[i] is the player count of team i.
  static ({int teamCount, List<int> sizes}) randomDistribution(int n) {
    assert(n >= 3 && n <= 10, 'randomDistribution: n must be 3..10, got $n');

    final teamCount = (n / 2).ceil(); // 3→2, 4→2, 5→3, 6→3, 7→4, 8→4, 9→5, 10→5
    final pairs = n ~/ 2;
    final hasOdd = (n % 2 == 1);

    final sizes = [
      for (int i = 0; i < pairs; i++) 2,
      if (hasOdd) 1,
    ];

    return (teamCount: teamCount, sizes: sizes);
  }

  // ─── startGame ──────────────────────────────────────────────────────────────

  void startGame({
    required List<String> playerIds,
    required int numberOfRounds,
    required bool quarterItEnabled,
    required bool customTargetsEnabled,
    required TreasureDivideGameMode gameMode,
    required TreasureDivideTeamAssignment teamAssignment,
    int? teamCount,
    Map<String, String>? manualTeamAssignments,
    Random? random,
  }) {
    if (gameMode == TreasureDivideGameMode.solo) {
      if (playerIds.length < 2 || playerIds.length > 8) {
        debugPrint(
            '[TreasureDivideProvider] Solo mode requires 2-8 players, got ${playerIds.length}');
        return;
      }
    } else {
      if (playerIds.length < 3 || playerIds.length > 10) {
        debugPrint(
            '[TreasureDivideProvider] Team mode requires 3-10 players, got ${playerIds.length}');
        return;
      }
    }

    final rng = random ?? Random();

    Map<String, List<String>> teamPlayersMap = {};
    Map<String, String> playerTeamMap = {};
    int resolvedTeamCount = 1;

    if (gameMode == TreasureDivideGameMode.team) {
      if (teamAssignment == TreasureDivideTeamAssignment.random) {
        final dist = randomDistribution(playerIds.length);
        resolvedTeamCount = dist.teamCount;
        final sizes = dist.sizes;

        final shuffled = List<String>.from(playerIds)..shuffle(rng);
        int cursor = 0;
        for (int t = 0; t < resolvedTeamCount; t++) {
          final teamId = 'team_${t + 1}';
          final members = shuffled.sublist(cursor, cursor + sizes[t]);
          cursor += sizes[t];
          teamPlayersMap[teamId] = members;
          for (final pid in members) {
            playerTeamMap[pid] = teamId;
          }
        }
      } else {
        // Manual assignment
        resolvedTeamCount = teamCount ?? 2;
        if (manualTeamAssignments != null) {
          for (final pid in playerIds) {
            final tid = manualTeamAssignments[pid];
            if (tid != null) {
              teamPlayersMap[tid] ??= [];
              teamPlayersMap[tid]!.add(pid);
              playerTeamMap[pid] = tid;
            }
          }
        } else {
          teamPlayersMap['team_1'] = List.from(playerIds);
          for (final pid in playerIds) {
            playerTeamMap[pid] = 'team_1';
          }
          resolvedTeamCount = 1;
        }
      }
    }

    _currentTurnHaul = 0;

    _currentGame = TreasureDivideGame.create(
      playerIds: playerIds,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      gameMode: gameMode,
      teamAssignment: teamAssignment,
      teamCount: resolvedTeamCount,
      teamPlayers: teamPlayersMap,
      playerTeamAssignments: playerTeamMap,
      random: rng,
    );

    notifyListeners();
  }

  // ─── processDartThrow ────────────────────────────────────────────────────────

  /// Processes one dart throw for the currently active player.
  ///
  /// [score] is the numerical score value (e.g. 20, 40, 60, 25, 50, 0 for miss).
  /// [multiplier] is the string multiplier ('single', 'double', 'triple',
  ///   'bull', 'Miss', etc.).
  /// [baseScore] is the segment face number (1-20, 25, 0 for miss).
  /// [sector] is an optional raw sector string (e.g. 'S20', 'D15', 'Bull').
  void processDartThrow({
    required int score,
    required String multiplier,
    required int baseScore,
    String? sector,
  }) {
    if (_currentGame == null || !isGameActive) return;
    if (_currentGame!.shouldPromptTakeout) return;

    final game = _currentGame!;
    final playerId = game.currentPlayerId;
    final roundIndex = game.currentRoundIndex;

    if (roundIndex >= game.numberOfRounds) return;
    final target = game.targetSequence[roundIndex];

    // ── Canonical first-dart turn increment (Rule §3) ──
    if (game.dartsThrown == 0) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
      // Capture score before the first dart so the turn-end announcement knows
      // whether there is something to halve.
      if (game.gameMode == TreasureDivideGameMode.team &&
          game.activeTeamId != null) {
        _scoreBeforeCurrentTurn = game.totalForTeam(game.activeTeamId!);
      } else {
        _scoreBeforeCurrentTurn = game.totalForPlayer(playerId);
      }
    }

    // Increment dart counters
    game.dartsThrown++;
    game.totalDartsThrown[playerId] =
        (game.totalDartsThrown[playerId] ?? 0) + 1;

    // Record the raw segment string
    final segStr = sector ?? _buildSectorStr(baseScore, multiplier, score);
    game.currentTurnDartSegments[playerId] ??= [];
    game.currentTurnDartSegments[playerId]!.add(segStr);

    // ── Hit detection ──
    final hitScore = _computeHitScore(
      target: target,
      baseScore: baseScore,
      multiplier: multiplier,
      score: score,
      sector: sector,
    );

    if (hitScore > 0) {
      _currentTurnHaul += hitScore;
    }

    // ── Capture last-dart announcement facts ──
    _lastDartWasMatched = hitScore > 0;
    _lastDartScore = hitScore;
    _lastDartMultiplier = multiplier;
    _lastDartSector = segStr;

    // End the turn when all darts have been thrown
    if (game.dartsThrown >= game.dartsThisTurn) {
      game.shouldPromptTakeout = true;
    }

    notifyListeners();
  }

  // ─── handleTakeoutFinished ───────────────────────────────────────────────────

  /// Called when the takeout prompt is confirmed (darts removed from the board).
  /// Commits the turn score, applies halving, and advances rotation.
  void handleTakeoutFinished() {
    if (_currentGame == null) return;
    if (!_currentGame!.shouldPromptTakeout) return;

    // Reset per-takeout announcement flags.
    _justCompletedCrewId = null;
    _justCompletedCrewHaul = 0;
    _roundAdvancedOnLastTakeout = false;
    _previousRoundIndex = _currentGame!.currentRoundIndex;

    final game = _currentGame!;
    final playerId = game.currentPlayerId;
    final roundIndex = game.currentRoundIndex;

    // ── Commit this player's round haul ──
    game.playerRoundScores[playerId] ??=
        List.filled(game.numberOfRounds, null);
    game.playerRoundScores[playerId]![roundIndex] = _currentTurnHaul;

    // ── Reset turn-level state ──
    game.dartsThrown = 0;
    game.currentTurnDartSegments[playerId] = [];
    game.shouldPromptTakeout = false;
    _currentTurnHaul = 0;

    // ── Advance rotation ──
    if (game.gameMode == TreasureDivideGameMode.solo) {
      _advanceSoloPlayer();
    } else {
      _advanceTeamPlayer();
    }

    notifyListeners();
  }

  // ─── skipTurn ────────────────────────────────────────────────────────────────

  /// Forfeits remaining darts. Treats any unthrown darts as misses.
  void skipTurn() {
    if (_currentGame == null || !isGameActive) return;
    if (_currentGame!.shouldPromptTakeout) return;

    final game = _currentGame!;
    final playerId = game.currentPlayerId;

    // Ensure totalTurns is incremented if no darts have been thrown yet
    if (game.dartsThrown == 0) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
    }

    // Treat remaining darts as misses — mark turn as done
    game.dartsThrown = game.dartsThisTurn;
    game.shouldPromptTakeout = true;

    notifyListeners();
  }

  // ─── editPlayerScore ────────────────────────────────────────────────────────

  /// Replays a previously-completed round for [playerId] with [newSegments].
  /// [roundIndex] is 0-based.
  ///
  /// Side-effects:
  /// - Updates playerRoundScores for that round.
  /// - Adjusts timesHalvedPerPlayer / timesHalvedPerTeam if halving status
  ///   changed (e.g., was miss → now hit, or was hit → now miss).
  /// - If the edited round was the FINAL round AND the game is finished,
  ///   re-runs _finalizeGame() to recompute winnerIds/winnerTeamIds.
  void editPlayerScore({
    required String playerId,
    required int roundIndex,
    required List<String> newSegments,
  }) {
    if (_currentGame == null) return;
    final game = _currentGame!;

    if (roundIndex < 0 || roundIndex >= game.numberOfRounds) return;
    if (!game.playerIds.contains(playerId)) return;

    final target = game.targetSequence[roundIndex];
    final oldHaul = game.playerRoundScores[playerId]?[roundIndex];

    // Replay darts to compute new haul
    int newHaul = 0;
    for (final seg in newSegments) {
      final parsed = _parseSectorString(seg);
      if (parsed == null) continue;
      final h = _computeHitScore(
        target: target,
        baseScore: parsed.baseScore,
        multiplier: parsed.multiplier,
        score: parsed.score,
        sector: seg,
      );
      newHaul += h;
    }

    // Commit new haul FIRST so recompute sees the updated score
    game.playerRoundScores[playerId] ??=
        List.filled(game.numberOfRounds, null);
    game.playerRoundScores[playerId]![roundIndex] = newHaul;

    // Adjust halve counters if the haul moved across the 0 boundary
    final wasZero = (oldHaul != null && oldHaul == 0);
    final isNowZero = newHaul == 0;

    if (wasZero && !isNowZero) {
      // Was a miss (halved), now is a hit (no halving)
      game.timesHalvedPerPlayer[playerId] =
          ((game.timesHalvedPerPlayer[playerId] ?? 1) - 1).clamp(0, 999);
      // Adjust team halve counter too
      final teamId = game.playerTeamAssignments[playerId];
      if (teamId != null &&
          game.gameMode == TreasureDivideGameMode.team) {
        _recomputeTeamHalveCount(teamId);
      }
    } else if (!wasZero && oldHaul != null && isNowZero) {
      // Was a hit, now is a miss (new halving) — but only count it
      // if there was actually treasure to halve coming into this
      // round. Editing a 0-treasure turn from a hit to a miss
      // should keep the gold at 0 and not claim a halving event.
      if (_totalBeforeRound(playerId, roundIndex) > 0) {
        game.timesHalvedPerPlayer[playerId] =
            (game.timesHalvedPerPlayer[playerId] ?? 0) + 1;
      }
      final teamId = game.playerTeamAssignments[playerId];
      if (teamId != null &&
          game.gameMode == TreasureDivideGameMode.team) {
        _recomputeTeamHalveCount(teamId);
      }
    }

    // If editing the round just completed by this player on active turn
    if (roundIndex == game.currentRoundIndex &&
        game.currentPlayerId == playerId) {
      _currentTurnHaul = newHaul;
    }

    // If the game is finished and this is an edit that may change the winner,
    // re-run finalization
    if (game.state == TreasureDivideGameState.finished) {
      // Rule §20: undo win state, recompute
      game.winnerIds = [];
      game.winnerTeamIds = [];
      game.gameEndTime = null;
      _finalizeGame();
    }

    notifyListeners();
  }

  // ─── _recomputeTeamHalveCount ─────────────────────────────────────────────────

  /// Recounts the number of rounds where the WHOLE crew came up empty for
  /// [teamId] and stores the result in timesHalvedPerTeam[teamId].
  void _recomputeTeamHalveCount(String teamId) {
    final game = _currentGame!;
    final members = game.teamPlayers[teamId] ?? [];
    int count = 0;
    // Replay the crew's treasure round-by-round so we can skip
    // counting halving events that fired when the crew had 0
    // treasure (no-op math; counting them shows a misleading
    // "Quartered N times" in the UI even though gold never dropped).
    int crewTotal = 0;
    final divisor = game.quarterItEnabled ? 4 : 2;
    for (int r = 0; r < game.numberOfRounds; r++) {
      bool allMissed = true;
      bool allThrown = true;
      int crewHaul = 0;
      for (final pid in members) {
        final haul = game.playerRoundScores[pid]?[r];
        if (haul == null) {
          allThrown = false;
          break;
        }
        crewHaul += haul;
        if (haul > 0) allMissed = false;
      }
      if (!allThrown) continue;
      if (allMissed) {
        if (crewTotal > 0) {
          count++;
          crewTotal = (crewTotal / divisor).floor();
        }
      } else {
        crewTotal += crewHaul;
      }
    }
    game.timesHalvedPerTeam[teamId] = count;
  }

  // ─── _advanceSoloPlayer ──────────────────────────────────────────────────────

  void _advanceSoloPlayer() {
    final game = _currentGame!;
    final currentIndex = game.playerIds.indexOf(game.currentPlayerId);
    final nextIndex = currentIndex + 1;

    if (nextIndex >= game.playerIds.length) {
      // All players done with this round — apply halving + advance round
      _applyRoundResultsSolo();
    } else {
      game.currentPlayerId = game.playerIds[nextIndex];
    }
  }

  // ─── _applyRoundResultsSolo ──────────────────────────────────────────────────

  void _applyRoundResultsSolo() {
    final game = _currentGame!;
    final roundIndex = game.currentRoundIndex;

    // For each player: if their haul was 0 AND they had treasure to
    // halve coming into this round, increment the halving counter.
    // A player who misses with a 0 balance has nothing to lose
    // (totalForPlayer's `total = (0 / divisor).floor() = 0` is a
    // no-op), so counting it as a halving event misleads the UI
    // ("Quartered 1 time" appearing on a player whose gold never
    // dropped). The player-tile counter is display-only; the actual
    // treasure math is reconstructed in `totalForPlayer` from the
    // round haul list and is unaffected by this guard.
    for (final pid in game.playerIds) {
      final haul = game.playerRoundScores[pid]?[roundIndex] ?? 0;
      if (haul == 0 && _totalBeforeRound(pid, roundIndex) > 0) {
        game.timesHalvedPerPlayer[pid] =
            (game.timesHalvedPerPlayer[pid] ?? 0) + 1;
      }
    }

    _advanceToNextRound();
  }

  /// Replays [playerId]'s round hauls from round 0 up to (but not
  /// including) [roundIndex] to compute the treasure they had walking
  /// INTO that round — same formula as
  /// `TreasureDivideGame.totalForPlayer` but stopping early. Used to
  /// decide whether an all-miss turn should bump the display-only
  /// halving counter (no-op on 0 → don't count).
  int _totalBeforeRound(String playerId, int roundIndex) {
    final game = _currentGame!;
    final scores =
        game.playerRoundScores[playerId] ?? const <int?>[];
    int total = 0;
    final divisor = game.quarterItEnabled ? 4 : 2;
    for (int i = 0; i < roundIndex && i < scores.length; i++) {
      final h = scores[i];
      if (h == null) continue;
      if (h > 0) {
        total += h;
      } else {
        total = (total / divisor).floor();
      }
    }
    return total;
  }

  // ─── _advanceTeamPlayer ──────────────────────────────────────────────────────

  void _advanceTeamPlayer() {
    final game = _currentGame!;
    final teamIds = game.teamPlayers.keys.toList();
    final currentTeamId = game.activeTeamId;
    if (currentTeamId == null) return;

    final currentPointer =
        (game.teamWithinRoundRotationPointer[currentTeamId] ?? 0) + 1;
    final teamMembers = game.teamPlayers[currentTeamId] ?? [];
    final teamSize = teamMembers.length;

    if (currentPointer < teamSize) {
      // More players on this crew
      game.teamWithinRoundRotationPointer[currentTeamId] = currentPointer;
      game.currentPlayerId = teamMembers[currentPointer];
    } else {
      // This crew is done with the round — apply crew-wide halving.
      _applyCrewRoundResult(currentTeamId);

      // Capture crew completion state for announcement helper.
      final roundIdx = game.currentRoundIndex;
      int crewHaul = 0;
      for (final pid in teamMembers) {
        crewHaul += game.playerRoundScores[pid]?[roundIdx] ?? 0;
      }
      _justCompletedCrewId = currentTeamId;
      _justCompletedCrewHaul = crewHaul;

      // Move to next crew
      final nextTeamIndex = game.currentTeamIndex + 1;
      if (nextTeamIndex >= teamIds.length) {
        // All crews done — advance to next round
        _advanceToNextRound();
      } else {
        game.currentTeamIndex = nextTeamIndex;
        final nextTeamId = teamIds[nextTeamIndex];
        game.activeTeamId = nextTeamId;
        game.teamWithinRoundRotationPointer[nextTeamId] = 0;
        final nextPlayers = game.teamPlayers[nextTeamId]!;
        game.currentPlayerId = nextPlayers.first;
      }
    }
  }

  // ─── _applyCrewRoundResult ───────────────────────────────────────────────────

  void _applyCrewRoundResult(String teamId) {
    final game = _currentGame!;
    final roundIndex = game.currentRoundIndex;
    final members = game.teamPlayers[teamId] ?? [];

    // Check if any member had a hit this round
    bool anyHit = false;
    for (final pid in members) {
      final haul = game.playerRoundScores[pid]?[roundIndex] ?? 0;
      if (haul > 0) {
        anyHit = true;
        break;
      }
    }

    if (!anyHit) {
      // Whole crew came up empty — increment crew halve counter,
      // but only if the crew had treasure to halve coming into this
      // round. Same rationale as the solo guard above: halving 0 is a
      // no-op, so the display counter shouldn't claim "Quartered 1
      // time" against a crew whose treasure never actually dropped.
      if (game.totalForTeam(teamId) > 0 ||
          _crewTreasureBefore(teamId, roundIndex) > 0) {
        game.timesHalvedPerTeam[teamId] =
            (game.timesHalvedPerTeam[teamId] ?? 0) + 1;
      }
    }
  }

  /// Returns the crew treasure for [teamId] computed across rounds
  /// 0..roundIndex-1 (i.e. BEFORE the just-finished round). Used by
  /// `_applyCrewRoundResult` to skip incrementing the halve counter
  /// when there was nothing to halve. Replays the same `anyHit`-based
  /// halving rule that `totalForTeam` uses internally.
  int _crewTreasureBefore(String teamId, int roundIndex) {
    final game = _currentGame!;
    final members = game.teamPlayers[teamId] ?? [];
    int total = 0;
    final divisor = game.quarterItEnabled ? 4 : 2;
    for (int round = 0; round < roundIndex; round++) {
      bool allThrown = members.every((pid) {
        final scores = game.playerRoundScores[pid];
        if (scores == null || round >= scores.length) return false;
        return scores[round] != null;
      });
      if (!allThrown) continue;
      int crewHaul = 0;
      bool anyHit = false;
      for (final pid in members) {
        final h = game.playerRoundScores[pid]?[round] ?? 0;
        crewHaul += h;
        if (h > 0) anyHit = true;
      }
      if (anyHit) {
        total += crewHaul;
      } else {
        total = (total / divisor).floor();
      }
    }
    return total;
  }

  // ─── _advanceToNextRound ─────────────────────────────────────────────────────

  void _advanceToNextRound() {
    final game = _currentGame!;
    final nextRound = game.currentRoundIndex + 1;

    if (nextRound >= game.numberOfRounds) {
      _finalizeGame();
      return;
    }

    game.currentRoundIndex = nextRound;
    _roundAdvancedOnLastTakeout = true;

    // Reset within-round rotation pointers
    for (final teamId in game.teamPlayers.keys) {
      game.teamWithinRoundRotationPointer[teamId] = 0;
    }
    game.currentTeamIndex = 0;

    // Set first player/team for the new round
    if (game.gameMode == TreasureDivideGameMode.solo) {
      game.currentPlayerId = game.playerIds.first;
    } else {
      final teamIds = game.teamPlayers.keys.toList();
      if (teamIds.isNotEmpty) {
        final firstTeamId = teamIds.first;
        game.activeTeamId = firstTeamId;
        game.currentTeamIndex = 0;
        game.currentPlayerId = game.teamPlayers[firstTeamId]!.first;
      }
    }
  }

  // ─── _finalizeGame ───────────────────────────────────────────────────────────

  void _finalizeGame() {
    final game = _currentGame!;
    game.state = TreasureDivideGameState.finished;
    game.gameEndTime = DateTime.now();
    game.shouldPromptTakeout = false;

    if (game.gameMode == TreasureDivideGameMode.solo) {
      _determineSoloWinner();
    } else {
      _determineTeamWinner();
    }
  }

  void _determineSoloWinner() {
    final game = _currentGame!;
    final playerIds = game.playerIds;
    if (playerIds.isEmpty) return;

    // Find highest total
    int highestTotal = game.totalForPlayer(playerIds.first);
    for (final id in playerIds) {
      final t = game.totalForPlayer(id);
      if (t > highestTotal) highestTotal = t;
    }

    // Players tied at highest total
    final topPlayers = [
      for (final id in playerIds)
        if (game.totalForPlayer(id) == highestTotal) id,
    ];

    if (topPlayers.length == 1) {
      game.winnerIds = topPlayers;
      return;
    }

    // Tiebreaker: fewer times halved
    int fewestHalved = game.timesHalvedPerPlayer[topPlayers.first] ?? 0;
    for (final id in topPlayers) {
      final h = game.timesHalvedPerPlayer[id] ?? 0;
      if (h < fewestHalved) fewestHalved = h;
    }

    final finalWinners = [
      for (final id in topPlayers)
        if ((game.timesHalvedPerPlayer[id] ?? 0) == fewestHalved) id,
    ];

    game.winnerIds = finalWinners; // May be >1 if genuine tie
  }

  void _determineTeamWinner() {
    final game = _currentGame!;
    final teamIds = game.teamPlayers.keys.toList();
    if (teamIds.isEmpty) return;

    // Find highest crew treasure
    int highestTreasure = game.totalForTeam(teamIds.first);
    for (final id in teamIds) {
      final t = game.totalForTeam(id);
      if (t > highestTreasure) highestTreasure = t;
    }

    final topTeams = [
      for (final id in teamIds)
        if (game.totalForTeam(id) == highestTreasure) id,
    ];

    if (topTeams.length == 1) {
      game.winnerTeamIds = topTeams;
      // winnerIds = all members of the single winning crew
      game.winnerIds = game.teamPlayers[topTeams.first] ?? [];
      return;
    }

    // Tiebreaker: fewer times halved (team)
    int fewestHalved = game.timesHalvedPerTeam[topTeams.first] ?? 0;
    for (final id in topTeams) {
      final h = game.timesHalvedPerTeam[id] ?? 0;
      if (h < fewestHalved) fewestHalved = h;
    }

    final finalWinners = [
      for (final id in topTeams)
        if ((game.timesHalvedPerTeam[id] ?? 0) == fewestHalved) id,
    ];

    game.winnerTeamIds = finalWinners; // May be >1 if genuine tie

    // winnerIds = all members of all tied winning crews
    final allWinnerPlayers = <String>[];
    for (final tid in finalWinners) {
      allWinnerPlayers.addAll(game.teamPlayers[tid] ?? []);
    }
    game.winnerIds = allWinnerPlayers;
  }

  // ─── _computeHitScore ────────────────────────────────────────────────────────

  /// Determines the score value of a dart against [target].
  /// Returns 0 if the dart does not hit the target.
  int _computeHitScore({
    required int target,
    required int baseScore,
    required String multiplier,
    required int score,
    String? sector,
  }) {
    final seg = sector ?? '';

    // Miss
    if (multiplier.toLowerCase() == 'miss' ||
        multiplier.toLowerCase() == 'none' ||
        seg == 'Miss' ||
        seg == 'None' ||
        seg.isEmpty) {
      return 0;
    }

    if (target == kTargetAnyDouble) {
      // Any double — any double segment
      if (_isDouble(multiplier, seg)) {
        return baseScore * 2;
      }
      return 0;
    }

    if (target == kTargetAnyTriple) {
      // Any triple — any triple segment
      if (_isTriple(multiplier, seg)) {
        return baseScore * 3;
      }
      return 0;
    }

    if (target == kTargetBull) {
      // Bull round — outer bull (25) or inner bull (50)
      if (seg == 'Bull' || score == 50) return 50;
      if (seg == '25' || score == 25) return 25;
      return 0;
    }

    // Number round — any multiplier of the target number
    final segBase = _extractBase(seg);
    if (segBase != null && segBase == target) {
      return score; // score already has multiplier applied
    }

    // Fallback: check baseScore matches target
    if (baseScore == target && baseScore > 0) {
      return score;
    }

    return 0;
  }

  bool _isDouble(String multiplier, String sector) {
    if (multiplier.toLowerCase() == 'double') return true;
    if (sector.startsWith('D') || sector.startsWith('d')) {
      return RegExp(r'^[Dd]\d+$').hasMatch(sector);
    }
    return false;
  }

  bool _isTriple(String multiplier, String sector) {
    if (multiplier.toLowerCase() == 'triple') return true;
    if (sector.startsWith('T') || sector.startsWith('t')) {
      return RegExp(r'^[Tt]\d+$').hasMatch(sector);
    }
    return false;
  }

  int? _extractBase(String sector) {
    final match = RegExp(r'^[SDTsdt](\d+)$').firstMatch(sector);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String _buildSectorStr(int baseScore, String multiplier, int score) {
    if (baseScore == 0 || multiplier.toLowerCase() == 'miss') return 'Miss';
    if (baseScore == 25 && score == 50) return 'Bull';
    if (baseScore == 25) return '25';
    switch (multiplier.toLowerCase()) {
      case 'double':
        return 'D$baseScore';
      case 'triple':
        return 'T$baseScore';
      default:
        return 'S$baseScore';
    }
  }

  // ─── _parseSectorString ──────────────────────────────────────────────────────

  ({int baseScore, String multiplier, int score})? _parseSectorString(
      String seg) {
    if (seg == 'Miss' || seg == 'None' || seg.isEmpty) {
      return (baseScore: 0, multiplier: 'miss', score: 0);
    }
    if (seg == 'Bull') {
      return (baseScore: 25, multiplier: 'bull', score: 50);
    }
    if (seg == '25') {
      return (baseScore: 25, multiplier: 'single', score: 25);
    }
    final match = RegExp(r'^([SDTsdt])(\d+)$').firstMatch(seg);
    if (match == null) return null;
    final prefix = match.group(1)!.toUpperCase();
    final num = int.tryParse(match.group(2)!);
    if (num == null) return null;
    switch (prefix) {
      case 'S':
        return (baseScore: num, multiplier: 'single', score: num);
      case 'D':
        return (baseScore: num, multiplier: 'double', score: num * 2);
      case 'T':
        return (baseScore: num, multiplier: 'triple', score: num * 3);
    }
    return null;
  }

  // ─── endGame (public) ───────────────────────────────────────────────────────

  void endGame() {
    if (_currentGame == null) return;
    _finalizeGame();
    notifyListeners();
  }

  void clearGame() {
    _currentGame = null;
    _resumedSavedGameId = null;
    _currentTurnHaul = 0;
    notifyListeners();
  }

  // ─── Save / Restore ─────────────────────────────────────────────────────────

  Future<void> saveGame(
    SaveGameService service, {
    List<String>? playerNames,
    bool isAutoSave = false,
  }) async {
    if (_currentGame == null || _saving) return;
    _saving = true;
    try {
      final game = _currentGame!;
      final names = playerNames ?? game.playerIds;
      final modeName =
          game.gameMode == TreasureDivideGameMode.solo ? 'Solo' : 'Team';
      final roundDisplay =
          'Round ${game.currentRoundIndex + 1} of ${game.numberOfRounds}';

      final metadata = SavedGameMetadata.create(
        gameType: 'treasure_divide',
        playerNames: names,
        progressInfo: roundDisplay,
        gameModeName: '$modeName, ${game.numberOfRounds} Rounds',
        leadingPlayerName: game.currentPlayerId,
        leadingPlayerScore: '${game.currentRoundIndex + 1} rounds played',
        gameState: game.toJson(),
        waitingForTakeout: game.shouldPromptTakeout,
        isAutoSave: isAutoSave,
        existingId: _resumedSavedGameId,
      );

      final saved = await service.saveGame(metadata);
      if (saved) {
        _resumedSavedGameId = metadata.id;
      }
    } finally {
      _saving = false;
    }
  }

  void restoreGame(SavedGameMetadata savedGame) {
    _currentGame = TreasureDivideGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _currentGame!.shouldPromptTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    _currentTurnHaul = 0;
    notifyListeners();
  }
}
