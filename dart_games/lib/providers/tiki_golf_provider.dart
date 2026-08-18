import 'dart:math';
import 'package:flutter/foundation.dart';
import 'round_robin_team_rotation.dart';
import '../models/tiki_golf_game.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import 'game_provider_base.dart';

class TikiGolfProvider extends GameProviderBase<TikiGolfGame> {
  /// Internal alias for [GameProviderBase.game] — same rationale as Treasure
  /// Divide: the game logic below names its locals `game` throughout, so the
  /// alias keeps the storage in the base without rewriting every body.
  TikiGolfGame? get _currentGame => game;
  set _currentGame(TikiGolfGame? value) => game = value;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  TikiGolfGame? get currentGame => _currentGame;

  @override
  bool get isGameActive =>
      _currentGame?.state == TikiGolfGameState.playing;

  /// Tiki Golf's third flag-storage shape (see plan notes Q13): a stored,
  /// serialized model field (`currentTurnEnded`) OR-ed with the derived
  /// winner condition. The setter writes only the stored half — the
  /// `hasWinner` disjunct is monotonic, so writing `currentTurnEnded = false`
  /// while the game is won correctly leaves the prompt up until the results
  /// navigation, exactly as before the migration.
  @override
  bool get shouldPromptTakeout =>
      (_currentGame?.currentTurnEnded ?? false) ||
      (_currentGame?.hasWinner ?? false);

  @override
  set waitingForTakeout(bool value) =>
      _currentGame?.currentTurnEnded = value;

  @override
  bool get hasWinner => _currentGame?.hasWinner ?? false;

  String? get currentPlayerId => _currentGame?.activePlayerId;

  String? get currentTeamId => _currentGame?.activeTeamId;

  // ─── randomDistribution ──────────────────────────────────────────────────────

  /// Pure function. Implements the spec Section 5 Random Team Distribution table
  /// exactly for N players in 3..16.
  ///
  /// Returns ({teamCount, sizes}) where sizes[i] is the player count of team i.
  /// The first `extra` teams get (base+1) players, the rest get base players.
  /// (Caller shuffles the player list and deals sequentially.)
  static ({int teamCount, List<int> sizes}) randomDistribution(int n) {
    assert(n >= 3 && n <= 16, 'randomDistribution: n must be 3..16, got $n');

    int t;
    if (n <= 7) {
      t = (n / 2).ceil(); // pair-fill: 3→2, 4→2, 5→3, 6→3, 7→4
    } else if (n == 8) {
      t = 2; // special case: [4,4]
    } else if (n <= 11) {
      t = 3; // 9→3, 10→3, 11→3
    } else {
      t = 4; // 12→4, 13→4, 14→4, 15→4, 16→4
    }

    final base = n ~/ t;
    final extra = n % t;

    final sizes = [
      for (int i = 0; i < extra; i++) base + 1,
      for (int i = extra; i < t; i++) base,
    ];

    return (teamCount: t, sizes: sizes);
  }

  // ─── startGame ──────────────────────────────────────────────────────────────

  void startGame({
    required List<String> playerIds,
    required int maxStrokes,
    required bool mulliganEnabled,
    required TikiGolfGameMode gameMode,
    required TikiGolfTeamAssignment teamAssignment,
    int? teamCount,
    Map<String, String>? manualTeamAssignments,
    Random? random,
  }) {
    // --- Validation ---
    if (gameMode == TikiGolfGameMode.solo) {
      if (playerIds.length < 2 || playerIds.length > 4) {
        debugPrint(
            '[TikiGolfProvider] Solo mode requires 2-4 players, got ${playerIds.length}');
        return;
      }
    } else {
      if (playerIds.length < 3 || playerIds.length > 16) {
        debugPrint(
            '[TikiGolfProvider] Team mode requires 3-16 players, got ${playerIds.length}');
        return;
      }
    }

    final rng = random ?? Random();

    // --- Build team structures ---
    Map<String, List<String>> teamPlayersMap = {};
    Map<String, String> playerTeamMap = {};
    int resolvedTeamCount = 1;

    if (gameMode == TikiGolfGameMode.team) {
      if (teamAssignment == TikiGolfTeamAssignment.random) {
        // Auto-derive team count + sizes from player count
        final dist = randomDistribution(playerIds.length);
        resolvedTeamCount = dist.teamCount;
        final sizes = dist.sizes;

        // Shuffle players and deal sequentially
        final shuffled = List<String>.from(playerIds)..shuffle(rng);
        int cursor = 0;
        for (int t = 0; t < resolvedTeamCount; t++) {
          final teamId = 'team_${t + 1}';
          final teamMembers = shuffled.sublist(cursor, cursor + sizes[t]);
          cursor += sizes[t];
          teamPlayersMap[teamId] = teamMembers;
          for (final pid in teamMembers) {
            playerTeamMap[pid] = teamId;
          }
        }
      } else {
        // Manual assignment
        resolvedTeamCount = teamCount ?? 2;
        // Build teamPlayers from manualTeamAssignments (playerId → teamId)
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
          // Fallback: all in team_1
          teamPlayersMap['team_1'] = List.from(playerIds);
          for (final pid in playerIds) {
            playerTeamMap[pid] = 'team_1';
          }
          resolvedTeamCount = 1;
        }
      }
    } else {
      // Solo mode — no teams
      resolvedTeamCount = 1;
    }

    // A genuinely new game must not inherit the previous game's saved-game
    // slot — otherwise this game's first save overwrites (and destroys) a
    // still-resumable abandoned game. See F2 in the plan notes.
    clearResumedSavedGameId();

    _currentGame = TikiGolfGame.create(
      playerIds: playerIds,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      gameMode: gameMode,
      teamAssignment: teamAssignment,
      teamCount: resolvedTeamCount,
      teamPlayers: teamPlayersMap,
      playerTeamAssignments: playerTeamMap,
      random: rng,
    );

    // Set the first active player
    _setFirstActivePlayer();

    notifyListeners();
  }

  // ─── processDartThrow ────────────────────────────────────────────────────────

  /// Processes one dart throw.
  ///
  /// [sector] is the raw segment string (e.g. 'S20', 'D20', 'T20', 'Bull',
  /// '25', 'Miss', 'None').
  /// [score] is the face value (1-20, 25, 50, 0 for miss).
  void processDartThrow({required String sector, required int score}) {
    if (_currentGame == null || !isGameActive) return;
    if (_currentGame!.currentTurnEnded) return;

    final game = _currentGame!;
    final playerId = game.activePlayerId;
    if (playerId == null) return;

    final holeIndex = game.currentHole - 1;
    if (holeIndex < 0 || holeIndex >= 9) return;

    final target = game.holeTargets[holeIndex];

    // ── Standard turn increment rule: increment totalTurns on FIRST dart ──
    if ((game.dartsThrown[playerId] ?? 0) == 0) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
    }

    // Increment dart counter
    game.dartsThrown[playerId] = (game.dartsThrown[playerId] ?? 0) + 1;
    final dartsNow = game.dartsThrown[playerId]!;

    // ── Hit detection ──
    // Any Single, Double, or Triple of the target number counts as a hit.
    // Bull/25 only match if target==25 (but spec targets are 1-20, so Bull
    // never matches a target in practice — documented for correctness).
    final hit = _doesDartHitTarget(sector: sector, score: score, target: target);

    if (hit) {
      // Hit: strokes = number of darts used
      game.playerHoleScores[playerId] ??= List.filled(9, null);
      game.playerHoleScores[playerId]![holeIndex] = dartsNow;
      game.currentTurnEnded = true;
    } else if (dartsNow >= game.maxStrokes) {
      // All darts missed: Splash (maxStrokes + 1)
      game.playerHoleScores[playerId] ??= List.filled(9, null);
      game.playerHoleScores[playerId]![holeIndex] = game.maxStrokes + 1;
      game.currentTurnEnded = true;
    }
    // else: turn continues (mid-turn miss, darts remain)

    notifyListeners();
  }

  // ─── _doesDartHitTarget ───────────────────────────────────────────────────────

  bool _doesDartHitTarget({
    required String sector,
    required int score,
    required int target,
  }) {
    // Miss / None always miss
    if (sector == 'Miss' || sector == 'None' || sector.isEmpty) return false;

    // Bull (inner bull = 50) and outer bull (25): only match if target is 25.
    // Since spec targets are 1-20, this is never true in a real game, but
    // implemented correctly for completeness.
    if (sector == 'Bull') return target == 25;
    if (sector == '25') return target == 25;

    // Regular sectors: S<N>, D<N>, T<N>
    // Extract base number from sector string
    final match = RegExp(r'^[SDTsdt](\d+)$').firstMatch(sector);
    if (match == null) return false;

    final baseNumber = int.tryParse(match.group(1)!);
    if (baseNumber == null) return false;

    // Any multiplier (Single, Double, Triple) of the target number counts
    return baseNumber == target;
  }

  // ─── skipTurn ────────────────────────────────────────────────────────────────

  void skipTurn() {
    if (_currentGame == null || !isGameActive) return;
    if (_currentGame!.currentTurnEnded) return;

    final game = _currentGame!;
    final playerId = game.activePlayerId;
    if (playerId == null) return;

    final holeIndex = game.currentHole - 1;
    if (holeIndex < 0 || holeIndex >= 9) return;

    // If no dart thrown yet, this counts as a turn for totalTurns tracking
    if ((game.dartsThrown[playerId] ?? 0) == 0) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
    }

    // Record Splash for the active player on currentHole
    game.playerHoleScores[playerId] ??= List.filled(9, null);
    game.playerHoleScores[playerId]![holeIndex] = game.maxStrokes + 1;
    game.currentTurnEnded = true;

    notifyListeners();
  }

  // ─── useMulligan ────────────────────────────────────────────────────────────

  void useMulligan() {
    if (_currentGame == null) return;
    final game = _currentGame!;
    final playerId = game.activePlayerId;
    if (playerId == null) return;

    // Preconditions:
    // 1. Turn must have ended
    if (!game.currentTurnEnded) return;
    // 2. Mulligan must be enabled
    if (!game.mulliganEnabled) return;
    // 3. Player must not have used their mulligan
    if ((game.playerMulligansUsed[playerId] ?? 0) != 0) return;
    // 4. The current hole must be a Splash (maxStrokes + 1)
    final holeIndex = game.currentHole - 1;
    if (holeIndex < 0 || holeIndex >= 9) return;
    final currentScore = game.playerHoleScores[playerId]?[holeIndex];
    if (currentScore != game.maxStrokes + 1) return;

    // Clear the hole score for this player
    game.playerHoleScores[playerId]![holeIndex] = null;
    // Mark mulligan as used
    game.playerMulligansUsed[playerId] = 1;
    // Reset dart counter (player throws again from dart 1)
    game.dartsThrown[playerId] = 0;
    // Clear turn-ended flag
    game.currentTurnEnded = false;
    // Note: totalTurns will increment again when the player throws their first
    // mulligan dart (since dartsThrown resets to 0, the "== 0" condition in
    // processDartThrow fires again). This is intentional — the mulligan re-throw
    // is a new turn instance.

    notifyListeners();
  }

  // ─── confirmTurnEnd ──────────────────────────────────────────────────────────

  /// Called when the player taps NEXT PLAYER / DARTS REMOVED — standard takeout.
  ///
  /// This is Tiki Golf's [handleTakeoutFinished] under its historical name
  /// (tests call it directly). Like Treasure Divide, it cannot use the base
  /// flow: the game is only finalized *inside* the advance (the last player
  /// completing hole 9 runs `_advanceToNextHole → _endGame`), so the screen
  /// re-checks `hasWinner` after this returns. Note the guard is the stored
  /// `currentTurnEnded` specifically, not the derived [shouldPromptTakeout].
  void confirmTurnEnd() {
    if (_currentGame == null) return;
    if (!_currentGame!.currentTurnEnded) return;

    // If game already has a winner, just clear the flag
    if (_currentGame!.hasWinner) {
      _currentGame!.currentTurnEnded = false;
      notifyListeners();
      return;
    }

    final game = _currentGame!;

    if (game.gameMode == TikiGolfGameMode.solo) {
      _advanceSoloPlayer();
    } else {
      _advanceTeamPlayer();
    }

    notifyListeners();
  }

  @override
  void handleTakeoutFinished() => confirmTurnEnd();

  @override
  void advanceToNextPlayer() {
    if (_currentGame!.gameMode == TikiGolfGameMode.solo) {
      _advanceSoloPlayer();
    } else {
      _advanceTeamPlayer();
    }
  }

  // ─── _advanceSoloPlayer ──────────────────────────────────────────────────────

  void _advanceSoloPlayer() {
    final game = _currentGame!;
    final currentIndex = game.playerIds.indexOf(game.activePlayerId ?? '');
    final nextIndex = currentIndex + 1;

    if (nextIndex >= game.playerIds.length) {
      // All players done with this hole
      _advanceToNextHole();
    } else {
      // Move to next player
      final nextPlayerId = game.playerIds[nextIndex];
      game.activePlayerId = nextPlayerId;
      game.dartsThrown[nextPlayerId] = 0;
      game.currentTurnEnded = false;
    }
  }

  // ─── _advanceTeamPlayer ──────────────────────────────────────────────────────

  void _advanceTeamPlayer() {
    final game = _currentGame!;
    final currentTeamId = game.activeTeamId;
    if (currentTeamId == null) return;

    // Pointer arithmetic is shared with Treasure Divide (WS03 §3.7); the
    // side effects below are Tiki's own.
    final step = RoundRobinTeamRotation.advance(
      teamIds: game.teamPlayers.keys.toList(),
      currentTeamId: currentTeamId,
      currentTeamIndex: game.currentTeamIndex,
      withinPeriodPointer: game.teamWithinHoleRotationPointer,
      teamPlayers: game.teamPlayers,
    );

    // Written back on every outcome — including when the team is finished, or
    // it would replay its last player next hole.
    game.teamWithinHoleRotationPointer[currentTeamId] =
        step.pointerForCurrentTeam;

    switch (step.outcome) {
      case TeamRotationOutcome.periodComplete:
        _advanceToNextHole();
      case TeamRotationOutcome.nextTeam:
        game.currentTeamIndex = step.nextTeamIndex!;
        game.activeTeamId = step.nextTeamId;
        game.teamWithinHoleRotationPointer[step.nextTeamId!] = 0;
        _startTurnFor(step.nextPlayerId!);
      case TeamRotationOutcome.nextPlayerSameTeam:
        _startTurnFor(step.nextPlayerId!);
    }
  }

  /// Hands the turn to [playerId]: fresh dart count, turn no longer ended.
  void _startTurnFor(String playerId) {
    final game = _currentGame!;
    game.activePlayerId = playerId;
    game.dartsThrown[playerId] = 0;
    game.currentTurnEnded = false;
  }

  // ─── _advanceToNextHole ──────────────────────────────────────────────────────

  void _advanceToNextHole() {
    final game = _currentGame!;
    final nextHole = game.currentHole + 1;

    if (nextHole > 9) {
      _endGame();
      return;
    }

    game.currentHole = nextHole;

    // Reset within-hole rotation counters
    for (final teamId in game.teamPlayers.keys) {
      game.teamWithinHoleRotationPointer[teamId] = 0;
    }
    game.currentTeamIndex = 0;
    game.currentTurnEnded = false;

    // Reset to first player/team
    _setFirstActivePlayer();
  }

  // ─── _setFirstActivePlayer ───────────────────────────────────────────────────

  void _setFirstActivePlayer() {
    final game = _currentGame!;

    if (game.gameMode == TikiGolfGameMode.solo) {
      if (game.playerIds.isNotEmpty) {
        game.activePlayerId = game.playerIds.first;
        game.dartsThrown[game.activePlayerId!] = 0;
      }
      game.activeTeamId = null;
    } else {
      // Team mode: first player of first team
      final teamIds = game.teamPlayers.keys.toList();
      if (teamIds.isNotEmpty) {
        final firstTeamId = teamIds.first;
        game.activeTeamId = firstTeamId;
        game.currentTeamIndex = 0;
        final firstTeamPlayers = game.teamPlayers[firstTeamId]!;
        if (firstTeamPlayers.isNotEmpty) {
          game.activePlayerId = firstTeamPlayers.first;
          game.dartsThrown[game.activePlayerId!] = 0;
        }
      }
    }
  }

  // ─── _endGame ───────────────────────────────────────────────────────────────

  void _endGame() {
    final game = _currentGame!;
    game.state = TikiGolfGameState.finished;
    game.gameEndTime = DateTime.now();
    game.currentTurnEnded = false;

    if (game.gameMode == TikiGolfGameMode.solo) {
      _determineSoloWinner();
    } else {
      _determineTeamWinner();
    }
  }

  void _determineSoloWinner() {
    final game = _currentGame!;
    final playerIds = game.playerIds;
    if (playerIds.isEmpty) return;

    // Find the lowest total. Every player tied at that total is a winner.
    int lowestTotal = game.totalForPlayer(playerIds.first);
    for (final id in playerIds) {
      final t = game.totalForPlayer(id);
      if (t < lowestTotal) lowestTotal = t;
    }

    // Preserve turn order in the winners list (matches existing display ranking).
    final tied = [
      for (final id in playerIds)
        if (game.totalForPlayer(id) == lowestTotal) id,
    ];

    game.winnerIds = tied;
    game.winnerId = tied.first; // legacy single-winner reference
  }

  void _determineTeamWinner() {
    final game = _currentGame!;
    final teamIds = game.teamPlayers.keys.toList();
    if (teamIds.isEmpty) return;

    int lowestTotal = game.totalForTeam(teamIds.first);
    for (final id in teamIds) {
      final t = game.totalForTeam(id);
      if (t < lowestTotal) lowestTotal = t;
    }

    final tied = [
      for (final id in teamIds)
        if (game.totalForTeam(id) == lowestTotal) id,
    ];

    game.winnerTeamIds = tied;
    game.winnerTeamId = tied.first; // legacy single-winner reference
  }

  // ─── editPlayerScore ────────────────────────────────────────────────────────

  /// Re-computes a player's hole score from new dart segments.
  ///
  /// [holeIndex] is 0-based.
  /// [newDartSegments] is the list of dart segment strings to replay.
  void editPlayerScore({
    required String playerId,
    required int holeIndex,
    required List<String> newDartSegments,
  }) {
    if (_currentGame == null) return;
    final game = _currentGame!;

    if (holeIndex < 0 || holeIndex >= 9) return;
    if (!game.playerIds.contains(playerId)) return;

    final target = game.holeTargets[holeIndex];
    final oldScore = game.playerHoleScores[playerId]?[holeIndex];

    // Replay darts to determine new score
    int? newScore;
    for (int i = 0; i < newDartSegments.length && i < game.maxStrokes; i++) {
      final seg = newDartSegments[i];
      final hit = _doesDartHitTarget(sector: seg, score: 0, target: target);
      if (hit) {
        newScore = i + 1; // 1-indexed stroke count
        break;
      }
    }
    if (newScore == null) {
      // All darts missed
      newScore = game.maxStrokes + 1; // Splash
    }

    // Update score
    game.playerHoleScores[playerId] ??= List.filled(9, null);
    game.playerHoleScores[playerId]![holeIndex] = newScore;

    // If the old score was Splash and the new score isn't, and this is the
    // current hole — give the mulligan back (edit removed the Splash).
    if (oldScore == game.maxStrokes + 1 &&
        newScore != game.maxStrokes + 1 &&
        holeIndex == game.currentHole - 1) {
      game.playerMulligansUsed[playerId] = 0;
    }

    // Update currentTurnEnded if this edit is for the current hole
    if (holeIndex == game.currentHole - 1 && game.activePlayerId == playerId) {
      game.currentTurnEnded = true; // Player now has a recorded score
    }

    notifyListeners();
  }

  // ─── endGame (public) ───────────────────────────────────────────────────────

  /// Public alias for _endGame(), used by tests and the Results screen.
  void endGame() {
    if (_currentGame == null) return;
    _endGame();
    notifyListeners();
  }

  // ─── Save / Restore ─────────────────────────────────────────────────────────

  /// Saves the current game.
  ///
  /// [playerNamesById] maps player ids to display names. Prefer it over
  /// [playerNames]: the saved-game tile should list the players in THIS game,
  /// and without the ids the provider cannot filter a caller-supplied list
  /// down from the whole roster. Without either, the tile falls back to raw
  /// ids, which are UUIDs.
  Future<void> saveGame(SaveGameService service,
      {List<String>? playerNames,
      Map<String, String>? playerNamesById,
      bool isAutoSave = false}) async {
    await persistSave(service, (existingId) {
      final game = _currentGame!;
      String nameOf(String id) => playerNamesById?[id] ?? id;
      final names = playerNames ?? game.playerIds.map(nameOf).toList();
      final completedHoles = game.currentHole - 1;
      final modeName = game.gameMode == TikiGolfGameMode.solo ? 'Solo' : 'Team';

      return SavedGameMetadata.create(
        gameType: 'tiki_golf',
        playerNames: names,
        progressInfo: 'Hole ${game.currentHole} of 9',
        gameModeName: '$modeName, Max Darts: ${game.maxStrokes}',
        leadingPlayerName:
            game.activePlayerId == null ? '' : nameOf(game.activePlayerId!),
        leadingPlayerScore: '$completedHoles holes completed',
        gameState: game.toJson(),
        // The stored half only — the derived winner half never needs saving
        // (a finished game is deleted from the resume list, not saved).
        waitingForTakeout: game.currentTurnEnded,
        isAutoSave: isAutoSave,
        existingId: existingId,
      );
    });
  }

  @override
  void loadGameState(Map<String, dynamic> json) {
    _currentGame = TikiGolfGame.fromJson(json);
  }
}
