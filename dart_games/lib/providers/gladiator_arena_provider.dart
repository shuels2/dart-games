import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/gladiator_arena_game.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/api/api_client.dart';

class GladiatorArenaProvider extends ChangeNotifier {
  GladiatorArenaGame? _currentGame;
  bool _waitingForTakeout = false;
  ApiClient? _apiClient;

  /// Wall-clock time when the current game started (for gameDuration).
  DateTime? _gameStartTime;

  String? _resumedSavedGameId;
  bool _saving = false;

  // ─── Pending menu settings (persisted across menu back/forward navigation) ──

  /// Last-used menu settings, saved by the menu screen on every change.
  /// Used to restore settings when a NEW menu screen instance is created
  /// (e.g. after navigating home and back) without a game being in progress.
  int? _pendingTargetScore;
  bool? _pendingDoubleFinishEnabled;
  bool? _pendingShieldRoundEnabled;
  bool? _pendingSpeedPlayEnabled;

  int? get pendingTargetScore => _pendingTargetScore;
  bool? get pendingDoubleFinishEnabled => _pendingDoubleFinishEnabled;
  bool? get pendingShieldRoundEnabled => _pendingShieldRoundEnabled;
  bool? get pendingSpeedPlayEnabled => _pendingSpeedPlayEnabled;

  void saveMenuSettings({
    required int targetScore,
    required bool doubleFinishEnabled,
    required bool shieldRoundEnabled,
    required bool speedPlayEnabled,
  }) {
    _pendingTargetScore = targetScore;
    _pendingDoubleFinishEnabled = doubleFinishEnabled;
    _pendingShieldRoundEnabled = shieldRoundEnabled;
    _pendingSpeedPlayEnabled = speedPlayEnabled;
    // No notifyListeners() needed — menu reads these on initState only.
  }

  // ─── Per-turn state tracking (for editPlayerScore revert) ─────────────────

  /// Score each player had at the START of the current player's turn.
  /// Populated on the first dart of each turn.
  final Map<String, int> _preTurnScores = {};

  /// Opponent scores BEFORE each knockoff that occurred this turn.
  /// Map: victimId → score before knockoff.
  final Map<String, int> _preKnockoffScores = {};

  /// Victims knocked off during this turn (cleared on advance/reset).
  final List<String> _knockoffVictimsThisTurn = [];

  // ─── Constructor ─────────────────────────────────────────────────────────────

  GladiatorArenaProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  GladiatorArenaGame? get currentGame => _currentGame;

  bool get isGameActive =>
      _currentGame?.state == GladiatorArenaGameState.playing;

  bool get hasWinner => _currentGame?.winnerId != null;

  /// True when the takeout prompt should be shown.
  /// Fires when the active player has thrown 3 darts, called skipTurn, or won.
  bool get shouldPromptTakeout => _waitingForTakeout;

  String? get currentPlayerId => _currentGame?.currentPlayerId;

  String? get resumedSavedGameId => _resumedSavedGameId;

  Duration? get gameDuration {
    if (_gameStartTime == null) return null;
    return DateTime.now().difference(_gameStartTime!);
  }

  int getCurrentPlayerDartsThrown() {
    if (_currentGame == null) return 0;
    return _currentGame!.dartsThrown[_currentGame!.currentPlayerId] ?? 0;
  }

  List<String> getCurrentTurnDartSegments(String playerId) {
    return _currentGame?.currentTurnDartSegments[playerId] ?? [];
  }

  // ─── startGame ───────────────────────────────────────────────────────────────

  void startGame({
    required List<String> playerIds,
    required int targetScore,
    required bool doubleFinishEnabled,
    required bool shieldRoundEnabled,
    required bool speedPlayEnabled,
    Map<String, String>? playerCharacterPaths,
    Random? random,
  }) {
    if (playerIds.length < 2) {
      debugPrint(
          '[GladiatorArenaProvider] Cannot start game with fewer than 2 players');
      return;
    }
    if (playerIds.length > 8) {
      debugPrint(
          '[GladiatorArenaProvider] Cannot start game with more than 8 players');
      return;
    }

    final rng = random ?? Random();
    final startIndex = rng.nextInt(playerIds.length);

    _currentGame = GladiatorArenaGame.create(
      playerIds: playerIds,
      targetScore: targetScore,
      doubleFinishEnabled: doubleFinishEnabled,
      shieldRoundEnabled: shieldRoundEnabled,
      speedPlayEnabled: speedPlayEnabled,
      playerCharacterPaths: playerCharacterPaths,
    );
    _currentGame!.currentPlayerIndex = startIndex;

    _waitingForTakeout = false;
    _resumedSavedGameId = null;
    _gameStartTime = DateTime.now();
    _clearTurnTracking();

    notifyListeners();
  }

  // ─── processDartThrow ────────────────────────────────────────────────────────

  /// Processes one dart throw.
  ///
  /// [score] is the face value (1–20, 25 for outer bull, 50 for inner bull, 0 for miss).
  /// [multiplier] is one of: 'single', 'double', 'triple', 'bull', 'miss'.
  /// [sector] is the raw segment string, e.g. 'S20', 'D20', 'T20', 'Bull', '25', 'Miss'.
  void processDartThrow({
    required int score,
    required String multiplier,
    required String sector,
  }) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    final game = _currentGame!;
    final playerId = game.currentPlayerId;

    // Guard: do not process more than 3 darts per turn
    if ((game.dartsThrown[playerId] ?? 0) >= 3) return;

    // 1. Compute dart value
    final dartValue = _computeDartValue(score: score, multiplier: multiplier);

    // 2. Standard turn increment rule: increment totalTurns on the FIRST dart
    //    of the turn — at this exact location, before bumping dartsThrown.
    //    Pattern per target_tag_game.dart:347-352.
    if ((game.dartsThrown[playerId] ?? 0) == 0) {
      // Snapshot pre-turn scores for all players (used in editPlayerScore revert)
      for (final id in game.playerIds) {
        _preTurnScores[id] = game.scores[id] ?? 0;
      }
      // Increment turn counter NOW (first dart only)
      game.totalTurns[playerId] =
          (game.totalTurns[playerId] ?? 0) + 1; // LINE: turn increment
    }

    // 3. Bump dart counters and record values/segments
    game.dartsThrown[playerId] = (game.dartsThrown[playerId] ?? 0) + 1;
    game.totalDartsThrown[playerId] =
        (game.totalDartsThrown[playerId] ?? 0) + 1;
    game.currentTurnDartValues[playerId]!.add(dartValue);
    game.currentTurnDartSegments[playerId]!.add(sector);

    // 4. Per-dart evaluation: a dart can win or bust the turn at any point —
    //    matches the pattern used by Lunar Lander, Carnival Derby, etc.
    //    `isLastDart` only controls whether a non-winning, non-busting turn
    //    commits its accumulated score (which still happens after dart 3,
    //    skipTurn, or the speed-play timer expiring).
    final dartsThrown = game.dartsThrown[playerId] ?? 0;
    _processTurnEnd(playerId, isLastDart: dartsThrown >= 3);

    notifyListeners();
  }

  // ─── _computeDartValue ──────────────────────────────────────────────────────

  /// Computes the point value for a dart throw.
  int _computeDartValue({required int score, required String multiplier}) {
    switch (multiplier) {
      case 'miss':
        return 0;
      case 'bull':
        return 50; // inner bull
      case 'single':
        return score; // outer bull (25) handled by score=25,multiplier=single
      case 'double':
        return score * 2;
      case 'triple':
        return score * 3;
      default:
        return score;
    }
  }

  // ─── _processTurnEnd ──────────────────────────────────────────────────────────

  /// Evaluates victory / bust / advance conditions per dart.
  ///
  /// Called after EVERY dart (per-dart evaluation, matching the pattern used
  /// by Lunar Lander, Carnival Derby, etc.) and from skipTurn /
  /// onSpeedPlayTimerExpired. A dart can:
  ///   - Win the game immediately (commit score, trigger win, end turn)
  ///   - Bust the turn immediately (revert / no commit, end turn)
  ///   - Continue (no state change until [isLastDart] is true, at which
  ///     point the accumulated turn total commits and the next player gets
  ///     the takeout prompt).
  void _processTurnEnd(String playerId, {required bool isLastDart}) {
    final game = _currentGame!;
    final currentScore = game.scores[playerId] ?? 0;
    final turnTotal = (game.currentTurnDartValues[playerId] ?? [])
        .fold<int>(0, (sum, v) => sum + v);
    final prospective = currentScore + turnTotal;

    if (game.doubleFinishEnabled) {
      // --- Double Finish ON path ---
      if (prospective > game.targetScore) {
        // BUST: overshoot at any point — score stays at preTurnScore.
        // Forfeit remaining darts so takeout fires immediately.
        game.dartsThrown[playerId] = 3;
        _waitingForTakeout = true;
        return;
      }
      if (prospective == game.targetScore) {
        // Hit target exactly — must be on a double for the win.
        final segments = game.currentTurnDartSegments[playerId] ?? [];
        final lastSegment = segments.isNotEmpty ? segments.last : '';
        final isDouble = lastSegment.startsWith('D');
        if (isDouble) {
          // VICTORY!
          game.scores[playerId] = game.targetScore;
          _triggerWin(playerId);
          game.dartsThrown[playerId] = 3;
          _waitingForTakeout = true;
          return;
        }
        // BUST: reached target but not on a double — forfeit remaining darts.
        game.dartsThrown[playerId] = 3;
        _waitingForTakeout = true;
        return;
      }
      // prospective < targetScore — only commit at turn end
      if (isLastDart) {
        game.scores[playerId] = prospective;
        _runKnockoffCheck(playerId);
        _waitingForTakeout = true;
      }
    } else {
      // --- Double Finish OFF path ---
      if (prospective >= game.targetScore) {
        // VICTORY at any dart that reaches or exceeds target.
        game.scores[playerId] = game.targetScore; // cap at target for display
        _triggerWin(playerId);
        game.dartsThrown[playerId] = 3;
        _waitingForTakeout = true;
        return;
      }
      if (isLastDart) {
        game.scores[playerId] = prospective;
        _runKnockoffCheck(playerId);
        _waitingForTakeout = true;
      }
    }
  }

  // ─── _triggerWin ─────────────────────────────────────────────────────────────

  void _triggerWin(String playerId) {
    _currentGame!.winnerId = playerId;
    _currentGame!.state = GladiatorArenaGameState.finished;
    _currentGame!.endedAt = DateTime.now();
  }

  // ─── _runKnockoffCheck ────────────────────────────────────────────────────────

  /// After a turn's score is updated (not VICTORY), checks if any other player
  /// has the exact same score → knockoff!
  void _runKnockoffCheck(String playerId) {
    final game = _currentGame!;
    final myScore = game.scores[playerId] ?? 0;

    // Guard: no knockoff if score is 0 (players start at 0, no point in knocking)
    if (myScore <= 0) return;

    // Guard: no knockoffs during shield rounds
    if (game.isShieldRound) return;

    for (final otherId in game.playerIds) {
      if (otherId == playerId) continue;
      if ((game.scores[otherId] ?? 0) == myScore) {
        // Save pre-knockoff score for undo support
        _preKnockoffScores[otherId] = game.scores[otherId]!;
        _knockoffVictimsThisTurn.add(otherId);

        // Knock off!
        game.scores[otherId] = 0;
        game.knockoffsDealt[playerId] =
            (game.knockoffsDealt[playerId] ?? 0) + 1;
        game.knockoffsReceived[otherId] =
            (game.knockoffsReceived[otherId] ?? 0) + 1;

        // Record for Elimination Zone display
        game.lastKnockoffVictimId = otherId;
        game.lastKnockoffAttackerId = playerId;
        game.lastKnockoffAt = DateTime.now();
      }
    }
  }

  // ─── skipTurn ─────────────────────────────────────────────────────────────────

  /// Skips the remaining darts of the current turn.
  /// Any darts already thrown count; remaining slots are treated as misses (0 pts).
  void skipTurn() {
    if (_currentGame == null) return;
    if (!isGameActive) return;
    if (_waitingForTakeout) return;

    final game = _currentGame!;
    final playerId = game.currentPlayerId;
    final thrown = game.dartsThrown[playerId] ?? 0;

    // If 0 darts thrown, we still need to count this as a turn
    if (thrown == 0) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
      // Snapshot pre-turn scores
      for (final id in game.playerIds) {
        _preTurnScores[id] = game.scores[id] ?? 0;
      }
    }

    // Fill remaining dart slots with 'Skip' markers (0 value)
    final remaining = 3 - thrown;
    for (int i = 0; i < remaining; i++) {
      game.currentTurnDartValues[playerId]!.add(0);
      game.currentTurnDartSegments[playerId]!.add('Skip');
      // Do NOT increment totalDartsThrown for skipped darts
    }
    // Bump dartsThrown to 3 so _processTurnEnd sees a full turn
    game.dartsThrown[playerId] = 3;

    _processTurnEnd(playerId, isLastDart: true);

    notifyListeners();
  }

  // ─── advanceToNextPlayer ─────────────────────────────────────────────────────

  /// Advances to the next player. Called by the screen after takeout is complete
  /// (via handleTakeoutFinished). Do NOT call directly from _processTurnEnd —
  /// the screen orchestrates the takeout-then-advance flow.
  void advanceToNextPlayer() {
    if (_currentGame == null) return;

    final game = _currentGame!;
    final currentId = game.currentPlayerId;

    // Clear per-turn tracking for the completed turn
    game.dartsThrown[currentId] = 0;
    game.currentTurnDartValues[currentId] = [];
    game.currentTurnDartSegments[currentId] = [];

    // Advance index
    game.currentPlayerIndex =
        (game.currentPlayerIndex + 1) % game.playerIds.length;

    // Increment round when wrapping back to index 0
    if (game.currentPlayerIndex == 0) {
      game.round++;
    }

    // Clear turn-level knockoff tracking
    _clearTurnTracking();

    // Reset Speed Play timer for new player
    if (game.speedPlayEnabled) {
      game.speedPlayTimeRemaining = 25;
    }

    _waitingForTakeout = false;

    notifyListeners();
  }

  // ─── handleTakeoutFinished ────────────────────────────────────────────────────

  /// Called by the screen when the dartboard signals takeout is complete.
  /// If the game has a winner, this is a no-op (screen handles navigation).
  /// Otherwise, advances to the next player.
  void handleTakeoutFinished() {
    if (hasWinner) return;
    advanceToNextPlayer();
  }

  // ─── editPlayerScore ──────────────────────────────────────────────────────────

  /// Replays the current player's turn with [newSegments] (raw segment strings).
  /// Undoes all win/knockoff side-effects from the original turn per Rule 20.
  void editPlayerScore(String playerId, List<String> newSegments) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.currentPlayerId) return;

    final game = _currentGame!;

    // 1. Capture whether this player won on this turn
    final wonThisTurn = game.winnerId == playerId;

    // 2. Undo win side-effects
    if (wonThisTurn) {
      game.winnerId = null; // LINE: win-undo block
      game.state = GladiatorArenaGameState.playing;
      game.endedAt = null;
    }

    // 3. Restore pre-turn scores for all players
    for (final id in game.playerIds) {
      if (_preTurnScores.containsKey(id)) {
        game.scores[id] = _preTurnScores[id]!;
      }
    }

    // 4. Undo knockoffs that happened this turn
    for (final victimId in _knockoffVictimsThisTurn) {
      // knockoffsDealt[playerId]-- (clamped to 0)
      game.knockoffsDealt[playerId] =
          ((game.knockoffsDealt[playerId] ?? 0) - 1).clamp(0, 9999);
      // knockoffsReceived[victimId]--
      game.knockoffsReceived[victimId] =
          ((game.knockoffsReceived[victimId] ?? 0) - 1).clamp(0, 9999);
      // Victim score is already restored via _preTurnScores above (but restore
      // explicitly from preKnockoffScores in case pre-turn wasn't snapshotted)
      if (_preKnockoffScores.containsKey(victimId)) {
        game.scores[victimId] = _preKnockoffScores[victimId]!;
      }
    }

    // 5. Undo totalDartsThrown for this turn's darts
    // Count only real darts (not Skip/X markers)
    int realDartsThisTurn = 0;
    for (final seg in game.currentTurnDartSegments[playerId] ?? []) {
      if (seg != 'Skip' && seg != 'X') realDartsThisTurn++;
    }
    game.totalDartsThrown[playerId] =
        ((game.totalDartsThrown[playerId] ?? 0) - realDartsThisTurn)
            .clamp(0, 9999);

    // 6. Save totalTurns so we can restore it after replay (replay's first dart would
    //    increment totalTurns again, double-counting the turn)
    final savedTotalTurns = game.totalTurns[playerId] ?? 0;

    // 7. Reset current turn data (do NOT decrement totalTurns — turn still happened)
    game.dartsThrown[playerId] = 0;
    game.currentTurnDartValues[playerId] = [];
    game.currentTurnDartSegments[playerId] = [];

    // 8. Clear knockoff side-effects tracking for this turn (will re-accumulate
    //    during replay)
    _preKnockoffScores.clear();
    _knockoffVictimsThisTurn.clear();

    // 9. Reset takeout flag so processDartThrow doesn't early-return during replay
    _waitingForTakeout = false;

    // 10. Replay the turn with new segments
    for (final segment in newSegments) {
      if (!isGameActive) break;
      // Don't replay beyond 3 real darts
      final currentDarts = game.dartsThrown[playerId] ?? 0;
      if (currentDarts >= 3) break;
      if (_waitingForTakeout) break;

      final parsed = _parseSegment(segment);
      processDartThrow(
        score: parsed.score,
        multiplier: parsed.multiplier,
        sector: segment,
      );
    }

    // 11. Restore totalTurns to pre-replay value (processDartThrow increments it
    //     on first dart of replay, but this is the SAME turn — not a new one)
    game.totalTurns[playerId] = savedTotalTurns;

    notifyListeners();
  }

  // ─── _parseSegment ────────────────────────────────────────────────────────────

  _SegmentParsed _parseSegment(String segment) {
    if (segment == 'Miss' || segment == 'Skip') {
      return _SegmentParsed(score: 0, multiplier: 'miss');
    }
    if (segment == 'Bull') {
      return _SegmentParsed(score: 50, multiplier: 'bull');
    }
    if (segment == '25') {
      return _SegmentParsed(score: 25, multiplier: 'single');
    }
    // Accept BOTH upper- and lowercase prefixes. The mock dartboard emits
    // lowercase 's<N>' for inner-single sectors (`_convertToScoliaFormat`),
    // and the screen's `_parseSector` preserves that casing when it passes
    // the sector through to `processDartThrow`, so edit-score replays must
    // round-trip lowercase segments. Without this, `'s20'` falls through to
    // `int.tryParse` and becomes a 0-score dart on replay.
    if (segment.startsWith('T') || segment.startsWith('t')) {
      final val = int.tryParse(segment.substring(1)) ?? 0;
      return _SegmentParsed(score: val, multiplier: 'triple');
    }
    if (segment.startsWith('D') || segment.startsWith('d')) {
      final val = int.tryParse(segment.substring(1)) ?? 0;
      return _SegmentParsed(score: val, multiplier: 'double');
    }
    if (segment.startsWith('S') || segment.startsWith('s')) {
      final val = int.tryParse(segment.substring(1)) ?? 0;
      return _SegmentParsed(score: val, multiplier: 'single');
    }
    // Fallback: try parse as int
    final val = int.tryParse(segment) ?? 0;
    return _SegmentParsed(score: val, multiplier: 'single');
  }

  // ─── Speed Play ───────────────────────────────────────────────────────────────

  /// Called by the screen each second to persist the remaining time for save/restore.
  void setSpeedPlayTimeRemaining(int? seconds) {
    if (_currentGame == null) return;
    _currentGame!.speedPlayTimeRemaining = seconds;
    // No notifyListeners() needed — screen drives the timer UI directly
  }

  /// Called by the screen when the Speed Play timer reaches 0.
  /// Processes the turn with whatever darts were already thrown.
  void onSpeedPlayTimerExpired() {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    final game = _currentGame!;
    final playerId = game.currentPlayerId;
    final thrown = game.dartsThrown[playerId] ?? 0;

    // If no darts thrown, count this as a turn with 0 points
    if (thrown == 0) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
      for (final id in game.playerIds) {
        _preTurnScores[id] = game.scores[id] ?? 0;
      }
    }

    // Fill remaining dart slots with timeout markers
    final remaining = 3 - thrown;
    for (int i = 0; i < remaining; i++) {
      game.currentTurnDartValues[playerId]!.add(0);
      game.currentTurnDartSegments[playerId]!.add('X');
    }
    game.dartsThrown[playerId] = 3;
    game.speedPlayTimeRemaining = null;

    _processTurnEnd(playerId, isLastDart: true);

    notifyListeners();
  }

  // ─── endGame ─────────────────────────────────────────────────────────────────

  void endGame() {
    if (_currentGame == null) return;
    if (_currentGame!.state != GladiatorArenaGameState.finished) {
      _currentGame!.state = GladiatorArenaGameState.finished;
      _currentGame!.endedAt = DateTime.now();
    }
    _resumedSavedGameId = null;
    notifyListeners();
  }

  // ─── clearGame ───────────────────────────────────────────────────────────────

  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
    _gameStartTime = null;
    _resumedSavedGameId = null;
    _clearTurnTracking();
    notifyListeners();
  }

  // ─── clearResumedSavedGameId ─────────────────────────────────────────────────

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  void toggleShieldRoundOverride() {
    if (_currentGame == null) return;
    final current = _currentGame!.shieldRoundOverride;
    _currentGame!.shieldRoundOverride = current == true ? null : true;
    notifyListeners();
  }

  // ─── saveGame ─────────────────────────────────────────────────────────────────

  Future<void> saveGame(List<dynamic> players, {bool isAutoSave = false}) async {
    if (_currentGame == null || _saving) return;
    _saving = true;
    try {
      final game = _currentGame!;

      // Find the leading player (highest score)
      String leaderId = game.playerIds.first;
      int highestScore = game.scores[leaderId] ?? 0;
      for (final id in game.playerIds) {
        final s = game.scores[id] ?? 0;
        if (s > highestScore) {
          highestScore = s;
          leaderId = id;
        }
      }

      // Resolve leader name from players list
      String leaderName = leaderId;
      String leaderScore = '$highestScore';
      try {
        // players is List<Player> at runtime but typed as dynamic to avoid
        // importing Player model (keep dependency minimal)
        final leader = (players as List).firstWhere(
          (p) => (p as dynamic).id == leaderId,
          orElse: () => players.first,
        );
        leaderName = (leader as dynamic).name as String;
      } catch (_) {}

      final playerNames = <String>[];
      for (final p in players) {
        if (game.playerIds.contains((p as dynamic).id)) {
          playerNames.add((p as dynamic).name as String);
        }
      }

      final modes = <String>['T${game.targetScore}'];
      if (game.doubleFinishEnabled) modes.add('DF');
      if (game.shieldRoundEnabled) modes.add('SR');
      if (game.speedPlayEnabled) modes.add('SP');

      final metadata = SavedGameMetadata.create(
        gameType: 'gladiator_arena',
        playerNames: playerNames,
        // Compact format: ~16-20 chars max (peer games use 10-18 chars)
        progressInfo: 'R${game.round}: $leaderName $highestScore pts',
        // Compact game mode: ~12 chars max (was ~30 chars)
        gameModeName: modes.join('/'),
        leadingPlayerName: leaderName,
        leadingPlayerScore: leaderScore,
        gameState: game.toJson(),
        waitingForTakeout: _waitingForTakeout,
        isAutoSave: isAutoSave,
        existingId: _resumedSavedGameId,
      );

      final saved = await SaveGameService(_apiClient).saveGame(metadata);
      if (saved) {
        _resumedSavedGameId = metadata.id;
      }
    } finally {
      _saving = false;
    }
  }

  // ─── restoreGame ──────────────────────────────────────────────────────────────

  Future<void> restoreGame(SavedGameMetadata savedGame) async {
    _currentGame = GladiatorArenaGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    _gameStartTime = DateTime.now();
    _clearTurnTracking();
    notifyListeners();
  }

  // ─── _clearTurnTracking ──────────────────────────────────────────────────────

  void _clearTurnTracking() {
    _preTurnScores.clear();
    _preKnockoffScores.clear();
    _knockoffVictimsThisTurn.clear();
  }
}

// ─── Internal helper ─────────────────────────────────────────────────────────

class _SegmentParsed {
  final int score;
  final String multiplier;
  const _SegmentParsed({required this.score, required this.multiplier});
}
