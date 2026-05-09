import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/pirates_grid_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/api/api_client.dart';
import '../screens/games/pirates_grid/utils/three_in_a_row_checker.dart';
import '../screens/games/pirates_grid/utils/grid_target_generator.dart';

class PiratesGridProvider extends ChangeNotifier {
  PiratesGridGame? _currentGame;
  bool _waitingForTakeout = false;
  String? _resumedSavedGameId;
  ApiClient? _apiClient;
  bool _saving = false;

  PiratesGridProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  PiratesGridGame? get currentGame => _currentGame;

  bool get isGameActive => _currentGame?.state == GameState.playing;

  bool get shouldPromptTakeout {
    if (_currentGame == null) return false;
    if (_waitingForTakeout) return true;
    if (getCurrentPlayerDartsThrown() >= 3) return true;
    if (isCurrentRoundFinished) return true;
    return false;
  }

  bool get hasWinner => _currentGame?.hasWinner() ?? false;

  bool get isCurrentRoundFinished {
    if (_currentGame == null) return false;
    return _currentGame!.winnerId != null || _currentGame!.isDraw;
  }

  String? get resumedSavedGameId => _resumedSavedGameId;

  // ─── startGame ───────────────────────────────────────────────────────────────

  void startGame(
    List<String> playerIds,
    TargetDifficulty difficulty,
    int bestOf,
    bool stealMode,
    bool speedPlay,
  ) {
    if (playerIds.length != 2) {
      debugPrint('[PiratesGridProvider] startGame requires exactly 2 players');
      return;
    }

    final grid = _buildGrid(difficulty);

    _currentGame = PiratesGridGame(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      playerIds: List<String>.from(playerIds),
      targetDifficulty: difficulty,
      bestOf: bestOf,
      stealMode: stealMode,
      speedPlay: speedPlay,
      grid: grid,
      currentPlayerIndex: 0,
      currentRoundStartingPlayerIndex: 0,
      state: GameState.playing,
    );

    _waitingForTakeout = false;
    notifyListeners();
  }

  // ─── processDartThrow ────────────────────────────────────────────────────────

  /// Main dart processing logic.
  ///
  /// [score]      — base number (1–20, 25, or 50)
  /// [multiplier] — 1=single, 2=double, 3=triple
  /// [sector]     — display string (e.g. "T20", "D18", "S15", "Bull")
  void processDartThrow({
    required int score,
    required int multiplier,
    required String sector,
  }) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    final game = _currentGame!;
    final playerId = game.getCurrentPlayerId();

    // ── Step 1: Increment dartsThrown ────────────────────────────────────────
    game.dartsThrown[playerId] = (game.dartsThrown[playerId] ?? 0) + 1;
    final dartCount = game.dartsThrown[playerId]!;

    // ── Step 2: Increment totalTurns on FIRST dart only (mandatory rule) ─────
    if (dartCount == 1) {
      game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
    }

    // ── Step 3: Increment totalDartsThrown ───────────────────────────────────
    game.totalDartsThrown[playerId] = (game.totalDartsThrown[playerId] ?? 0) + 1;

    // ── Step 4: Append sector to currentTurnDartSegments ─────────────────────
    game.currentTurnDartSegments[playerId] ??= [];
    game.currentTurnDartSegments[playerId]!.add(sector);

    // ── Step 5: If round already won/drawn, dart is ignored ──────────────────
    if (game.winnerId != null || game.isDraw) {
      _checkTakeout(game, playerId);
      notifyListeners();
      return;
    }

    // ── Step 6: Find matching cell ────────────────────────────────────────────
    GridCell? matchedCell;
    int matchedRow = -1;
    int matchedCol = -1;

    outer:
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final cell = game.grid[r][c];
        if (cell.target.matches(score, multiplier)) {
          matchedCell = cell;
          matchedRow = r;
          matchedCol = c;
          break outer;
        }
      }
    }

    if (matchedCell == null) {
      // Miss — no matching cell
      _checkTakeout(game, playerId);
      notifyListeners();
      return;
    }

    // ── Step 7: Apply flag placement / steal logic ────────────────────────────
    final opponentId = game.getOpponentPlayerId(playerId);
    bool flagChanged = false;

    if (matchedCell.claimedBy == null) {
      // Empty cell — plant flag
      game.grid[matchedRow][matchedCol].claimedBy = playerId;
      flagChanged = true;
    } else if (matchedCell.claimedBy == playerId) {
      // Already own this cell — no effect
    } else if (matchedCell.claimedBy == opponentId) {
      if (game.stealMode) {
        // Steal mode ON — replace opponent flag (mutiny!)
        game.grid[matchedRow][matchedCol].claimedBy = playerId;
        flagChanged = true;
      }
      // Steal mode OFF — no effect
    }

    // ── Step 8: Check for win condition ──────────────────────────────────────
    if (flagChanged) {
      _checkRoundEnd(game);
    }

    _checkTakeout(game, playerId);
    notifyListeners();
  }

  // ─── skipTurn ────────────────────────────────────────────────────────────────

  void skipTurn() {
    if (_currentGame == null) return;

    final game = _currentGame!;
    final playerId = game.getCurrentPlayerId();
    final dartCount = game.getCurrentPlayerDartsThrown();

    if (!GameSkipTurnHelper.canSkipTurn(
      gameActive: isGameActive,
      waitingForTakeout: _waitingForTakeout,
      currentDartCount: dartCount,
      maxDartsPerTurn: 3,
    )) {
      return;
    }

    GameSkipTurnHelper.skipRemainingDarts(
      currentDartCount: dartCount,
      maxDartsPerTurn: 3,
      addVisualMarker: (marker) {
        game.currentTurnDartSegments[playerId] ??= [];
        game.currentTurnDartSegments[playerId]!.add(marker);
      },
    );

    _waitingForTakeout = true;
    notifyListeners();
  }

  // ─── advanceToNextPlayer ─────────────────────────────────────────────────────

  void advanceToNextPlayer() {
    if (_currentGame == null) return;

    final game = _currentGame!;
    final currentPlayerId = game.getCurrentPlayerId();

    // Reset current player's dart tracking
    game.dartsThrown[currentPlayerId] = 0;
    game.currentTurnDartSegments[currentPlayerId] = [];

    // Move to next player (simple 2-player rotation)
    game.currentPlayerIndex = (game.currentPlayerIndex + 1) % 2;

    notifyListeners();
  }

  // ─── handleTakeoutFinished ───────────────────────────────────────────────────

  void handleTakeoutFinished() {
    if (_currentGame == null) return;
    if (!_waitingForTakeout) return;

    final game = _currentGame!;

    // If the match is over (winner or match draw), just clear waiting state
    if (game.hasWinner()) {
      _waitingForTakeout = false;
      notifyListeners();
      return;
    }

    // If round ended (round winner or round draw), handle round transition
    if (isCurrentRoundFinished) {
      _handleRoundTransition(game);
      _waitingForTakeout = false;
      notifyListeners();
      return;
    }

    // Normal end of turn — advance to next player
    if (!isGameActive) return;

    advanceToNextPlayer();
    _waitingForTakeout = false;

    notifyListeners();
  }

  // ─── editPlayerScore ─────────────────────────────────────────────────────────

  /// Replays the current turn with [newSegments] for [playerId].
  void editPlayerScore({
    required String playerId,
    required List<String> newSegments,
  }) {
    if (_currentGame == null) return;
    final game = _currentGame!;
    if (playerId != game.getCurrentPlayerId()) return;

    // Save player index before replay
    final savedPlayerIndex = game.currentPlayerIndex;

    // Reset the turn state for this player
    _resetTurnForPlayer(game, playerId);

    // Restore player index to allow processDartThrow to work
    game.currentPlayerIndex = savedPlayerIndex;

    // Replay all segments
    for (final segment in newSegments) {
      if (segment == 'Skip') {
        // Skip marker: add to segments but do not process as dart
        game.currentTurnDartSegments[playerId]!.add(segment);
        continue;
      }

      final parsed = _parseSector(segment);
      if (parsed == null) {
        // Miss or unparseable
        game.dartsThrown[playerId] = (game.dartsThrown[playerId] ?? 0) + 1;
        final dartCount = game.dartsThrown[playerId]!;
        if (dartCount == 1) {
          game.totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
        }
        game.totalDartsThrown[playerId] = (game.totalDartsThrown[playerId] ?? 0) + 1;
        game.currentTurnDartSegments[playerId]!.add(segment);
        // Reset takeout to avoid processDartThrow guard blocking replay
        _waitingForTakeout = false;
        continue;
      }

      // Reset takeout to allow processing each dart in sequence
      _waitingForTakeout = false;

      processDartThrow(
        score: parsed['score'] as int,
        multiplier: parsed['multiplier'] as int,
        sector: segment,
      );
    }

    // Restore player index
    game.currentPlayerIndex = savedPlayerIndex;

    // Determine whether takeout is still needed
    final dartCount = game.getCurrentPlayerDartsThrown();
    if (dartCount >= 3 || isCurrentRoundFinished) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // ─── getCurrentPlayerDartsThrown ─────────────────────────────────────────────

  int getCurrentPlayerDartsThrown() {
    return _currentGame?.getCurrentPlayerDartsThrown() ?? 0;
  }

  // ─── getCurrentTurnDartSegments ──────────────────────────────────────────────

  List<String> getCurrentTurnDartSegments(String playerId) {
    return _currentGame?.getCurrentTurnDarts(playerId) ?? [];
  }

  // ─── Save / Restore ──────────────────────────────────────────────────────────

  Future<void> saveGame(List<Player> players) async {
    if (_currentGame == null || _saving) return;
    _saving = true;
    try {
      final game = _currentGame!;

      final p1 = game.playerIds[0];
      final p2 = game.playerIds[1];
      final p1Wins = game.roundsWon[p1] ?? 0;
      final p2Wins = game.roundsWon[p2] ?? 0;

      final p1Name = players
              .where((p) => p.id == p1)
              .map((p) => p.name)
              .firstOrNull ??
          'Player 1';
      final p2Name = players
              .where((p) => p.id == p2)
              .map((p) => p.name)
              .firstOrNull ??
          'Player 2';

      String leadName = p1Name;
      int leadWins = p1Wins;
      if (p2Wins > p1Wins) {
        leadName = p2Name;
        leadWins = p2Wins;
      }

      final metadata = SavedGameMetadata.create(
        gameType: 'pirates_grid',
        playerNames: [p1Name, p2Name],
        progressInfo: 'Round ${game.currentRound}/${game.bestOf} — '
            '$p1Name: $p1Wins  $p2Name: $p2Wins',
        gameModeName: '${_difficultyLabel(game.targetDifficulty)}, '
            'Best Of ${game.bestOf}'
            '${game.stealMode ? ", Steal" : ""}'
            '${game.speedPlay ? ", Speed" : ""}',
        leadingPlayerName: leadName,
        leadingPlayerScore: '$leadWins round${leadWins == 1 ? "" : "s"} won',
        gameState: game.toJson(),
        waitingForTakeout: _waitingForTakeout,
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

  void restoreGame(SavedGameMetadata savedGame) {
    _currentGame = PiratesGridGame.fromJson(
      Map<String, dynamic>.from(savedGame.gameState),
    );
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    notifyListeners();
  }

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
    notifyListeners();
  }

  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = GameState.finished;
      _currentGame!.gameEndTime = DateTime.now();
    }
    notifyListeners();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  /// Builds a fresh 3x3 grid of [GridCell]s for the given difficulty.
  List<List<GridCell>> _buildGrid(TargetDifficulty difficulty) {
    final targets = GridTargetGenerator.generate(difficulty);
    return List.generate(
        3, (r) => List.generate(3, (c) => GridCell(target: targets[r][c])));
  }

  /// Sets _waitingForTakeout if 3 darts thrown or round has ended.
  void _checkTakeout(PiratesGridGame game, String playerId) {
    final dartCount = game.dartsThrown[playerId] ?? 0;
    if (dartCount >= 3 || game.winnerId != null || game.isDraw) {
      _waitingForTakeout = true;
    }
  }

  /// Extracts the claimed-by matrix from the current grid.
  List<List<String?>> _getClaimedByMatrix(PiratesGridGame game) {
    return List.generate(
        3, (r) => List.generate(3, (c) => game.grid[r][c].claimedBy));
  }

  /// Checks whether the round has ended after a flag change.
  void _checkRoundEnd(PiratesGridGame game) {
    final claimedBy = _getClaimedByMatrix(game);
    final currentPlayerId = game.getCurrentPlayerId();

    // Check for 3-in-a-row
    final winningLine =
        ThreeInARowChecker.findWinningLine(claimedBy, currentPlayerId);
    if (winningLine != null) {
      game.winnerId = currentPlayerId;
      game.winningLine = winningLine;
      _applyRoundResult(game, winnerId: currentPlayerId);
      return;
    }

    // Check for draw (grid full, no winner)
    if (game.isGridFull()) {
      game.isDraw = true;
      _applyRoundResult(game, winnerId: null);
    }
  }

  /// Updates roundsWon and checks for match end.
  void _applyRoundResult(PiratesGridGame game, {required String? winnerId}) {
    if (winnerId != null) {
      game.roundsWon[winnerId] = (game.roundsWon[winnerId] ?? 0) + 1;
    }

    final roundsToWin = _roundsToWin(game.bestOf);

    // Check for match winner
    for (final playerId in game.playerIds) {
      if ((game.roundsWon[playerId] ?? 0) >= roundsToWin) {
        game.matchWinnerId = playerId;
        game.state = GameState.finished;
        game.gameEndTime = DateTime.now();
        return;
      }
    }

    // Check for match draw: all rounds played, no player reached required wins
    if (game.currentRound >= game.bestOf) {
      game.isMatchDraw = true;
      game.state = GameState.finished;
      game.gameEndTime = DateTime.now();
    }
    // Otherwise, the match continues — round transition in handleTakeoutFinished
  }

  /// Handles transition to the next round.
  void _handleRoundTransition(PiratesGridGame game) {
    // If match is already finished, do nothing
    if (game.state == GameState.finished) return;

    // Prepare next round
    game.currentRound++;
    game.grid = _buildGrid(game.targetDifficulty);
    game.winnerId = null;
    game.winningLine = null;
    game.isDraw = false;

    // Alternate starting player
    game.currentRoundStartingPlayerIndex =
        1 - game.currentRoundStartingPlayerIndex;
    game.currentPlayerIndex = game.currentRoundStartingPlayerIndex;

    // Reset dart tracking for all players
    for (final playerId in game.playerIds) {
      game.dartsThrown[playerId] = 0;
      game.currentTurnDartSegments[playerId] = [];
    }
  }

  int _roundsToWin(int bestOf) => (bestOf ~/ 2) + 1;

  String _difficultyLabel(TargetDifficulty d) {
    switch (d) {
      case TargetDifficulty.easy:
        return 'Easy';
      case TargetDifficulty.medium:
        return 'Medium';
      case TargetDifficulty.hard:
        return 'Hard';
    }
  }

  /// Resets the current turn for [playerId] by undoing any cell claims
  /// made during this turn, and zeroing out the per-turn counters.
  ///
  /// The total turn count is decremented by 1 (to be re-incremented on
  /// replay's first dart). Total darts thrown is reduced by the number of
  /// real darts in the current turn segments.
  void _resetTurnForPlayer(PiratesGridGame game, String playerId) {
    final currentSegments = List<String>.from(
      game.currentTurnDartSegments[playerId] ?? [],
    );

    // Capture round/match-win state CAUSED by this turn before we clear
    // the round-level fields below. Any winnerId set on the current game
    // must have been set during this turn — there's no path that sets
    // winnerId between turns. Same for matchWinnerId/isMatchDraw, since
    // those are downstream of _applyRoundResult during this turn.
    final thisTurnWonRound = game.winnerId == playerId;
    final thisTurnWonMatch = game.matchWinnerId == playerId;
    final thisTurnDrewMatch = game.isMatchDraw && !thisTurnWonMatch;

    // Count real darts (non-Skip segments) to adjust totalDartsThrown
    final realDartCount =
        currentSegments.where((s) => s != 'Skip').length;

    // Subtract turn and dart counters
    game.totalTurns[playerId] =
        ((game.totalTurns[playerId] ?? 0) - 1).clamp(0, 99999);
    game.totalDartsThrown[playerId] =
        ((game.totalDartsThrown[playerId] ?? 0) - realDartCount).clamp(0, 99999);
    game.dartsThrown[playerId] = 0;
    game.currentTurnDartSegments[playerId] = [];

    // Also reset round win state caused by this turn
    game.winnerId = null;
    game.winningLine = null;
    game.isDraw = false;

    // Undo cell claims made during this turn:
    // For each dart segment, find the cell it matched and clear this
    // player's claim if it was set during this turn.
    for (final segment in currentSegments) {
      if (segment == 'Skip' || segment == 'Miss') continue;
      final parsed = _parseSector(segment);
      if (parsed == null) continue;

      final score = parsed['score'] as int;
      final mult = parsed['multiplier'] as int;

      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          final cell = game.grid[r][c];
          if (cell.target.matches(score, mult) && cell.claimedBy == playerId) {
            game.grid[r][c].claimedBy = null;
          }
        }
      }
    }

    // If this turn caused round/match-win side-effects, undo them too.
    // Without this, an edit that removes the winning hit leaves
    // matchWinnerId/state=finished set, hasWinner returns true, and
    // processDartThrow rejects the replayed segments via !isGameActive.
    if (thisTurnWonRound) {
      game.roundsWon[playerId] =
          ((game.roundsWon[playerId] ?? 0) - 1).clamp(0, 99999);
    }
    if (thisTurnWonMatch || thisTurnDrewMatch) {
      game.matchWinnerId = null;
      game.isMatchDraw = false;
      game.state = GameState.playing;
      game.gameEndTime = null;
    }
  }

  /// Parses a dart sector string into {score, multiplier} integers.
  /// Returns null if the sector represents a miss or is unparseable.
  Map<String, int>? _parseSector(String sector) {
    if (sector.isEmpty ||
        sector == 'None' ||
        sector == 'Miss' ||
        sector == 'Skip') {
      return null;
    }

    // Inner bull
    if (sector == 'Bull') {
      return {'score': 25, 'multiplier': 1};
    }
    if (sector == 'DBull' || sector == '50') {
      return {'score': 50, 'multiplier': 2};
    }
    // Outer bull as plain '25'
    if (sector == '25') {
      return {'score': 25, 'multiplier': 1};
    }

    // Standard sectors: S20, D20, T20
    final match =
        RegExp(r'^([SDT])(\d+)$', caseSensitive: false).firstMatch(sector);
    if (match == null) return null;

    final prefix = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);

    int mult;
    switch (prefix) {
      case 'D':
        mult = 2;
        break;
      case 'T':
        mult = 3;
        break;
      default:
        mult = 1;
        break; // 'S'
    }

    return {'score': number, 'multiplier': mult};
  }
}
