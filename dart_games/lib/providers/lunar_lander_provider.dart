import 'package:flutter/foundation.dart';
import '../models/lunar_lander_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/api/api_client.dart';

class LunarLanderProvider extends ChangeNotifier {
  LunarLanderGame? _currentGame;
  bool _waitingForTakeout = false;
  ApiClient? _apiClient;

  /// Wall-clock time when the current game started (for gameDuration).
  DateTime? _gameStartTime;

  String? _resumedSavedGameId;
  bool _saving = false;

  LunarLanderProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  LunarLanderGame? get currentGame => _currentGame;

  bool get isGameActive =>
      _currentGame?.state == LunarLanderGameState.playing;

  bool get shouldPromptTakeout => _waitingForTakeout;

  bool get hasWinner => _currentGame?.hasWinner() ?? false;

  Player? getCurrentPlayer(List<Player> players) {
    if (_currentGame == null) return null;
    return _currentGame!.getCurrentPlayer(players);
  }

  String? getCurrentPlayerId() => _currentGame?.getCurrentPlayerId();

  int getCurrentPlayerDartsThrown() =>
      _currentGame?.getCurrentPlayerDartsThrown() ?? 0;

  int getCurrentAltitude(String playerId) =>
      _currentGame?.getCurrentAltitude(playerId) ??
      (_currentGame?.startingAltitude ?? 0);

  LunarLanderCharacter? getCharacter(String playerId) =>
      _currentGame?.getCharacter(playerId);

  List<int> getCurrentTurnDartScores(String playerId) =>
      _currentGame?.getCurrentTurnDartScores(playerId) ?? [];

  List<bool> getDartThrowWasBust(String playerId) =>
      _currentGame?.getDartThrowWasBust(playerId) ?? [];

  /// Duration since game started (null until startGame is called).
  Duration? get gameDuration {
    if (_gameStartTime == null) return null;
    return DateTime.now().difference(_gameStartTime!);
  }

  String? get resumedSavedGameId => _resumedSavedGameId;

  // ─── startGame ───────────────────────────────────────────────────────────────

  void startGame({
    required List<String> playerIds,
    required int startingAltitude, // CONSUMES OPTION: startingAltitude
    required bool hardLandingEnabled, // CONSUMES OPTION: hardLandingEnabled
  }) {
    if (playerIds.length < 2) {
      debugPrint('[LunarLanderProvider] Cannot start game with fewer than 2 players');
      return;
    }
    if (playerIds.length > 8) {
      debugPrint('[LunarLanderProvider] Cannot start game with more than 8 players');
      return;
    }

    _currentGame = LunarLanderGame.create(
      playerIds: playerIds,
      startingAltitude: startingAltitude,
      hardLandingEnabled: hardLandingEnabled,
    );
    _waitingForTakeout = false;
    _gameStartTime = DateTime.now();

    // Snapshot the initial turn start state
    _currentGame!.saveTurnStartState();

    notifyListeners();
  }

  // ─── processDartThrow ────────────────────────────────────────────────────────

  /// Processes one dart throw from the dartboard hardware/emulator.
  ///
  /// [score] is the face value (1–20, 25 for outer bull, 50 for inner bull).
  /// [multiplier] is 1 (single), 2 (double), or 3 (triple).
  ///
  /// Implements the spec Section 5 dart processing logic:
  ///   1. Compute dart value = score × multiplier.
  ///   2. Subtract from current player's altitude.
  ///   3. alt == 0 → TOUCHDOWN (win).
  ///      alt > 0  → continue descent.
  ///      alt < 0 + hardLandingEnabled ON  → CRASH (bust, revert).
  ///      alt < 0 + hardLandingEnabled OFF → TOUCHDOWN (overshoot wins).
  void processDartThrow({
    required int score,
    required int multiplier,
  }) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    final game = _currentGame!;
    final playerId = game.getCurrentPlayerId();

    // Guard: do not process more than maxDartsPerTurn darts
    if ((game.dartsThrown[playerId] ?? 0) >= game.maxDartsPerTurn) return;

    // 1. Compute dart value
    final dartValue = game.dartScore(score: score, multiplier: multiplier);

    // 2. Subtract from current altitude
    final prevAltitude = game.currentAltitudes[playerId]!;
    final newAltitude = prevAltitude - dartValue;

    // Increment dart counters
    game.dartsThrown[playerId] = (game.dartsThrown[playerId] ?? 0) + 1;
    game.totalDartsThrown[playerId] =
        (game.totalDartsThrown[playerId] ?? 0) + 1;

    // Increment totalTurns on the FIRST dart of the turn
    if (game.dartsThrown[playerId] == 1) {
      game.totalTurns[playerId] =
          (game.totalTurns[playerId] ?? 0) + 1;
    }

    // 3. Determine result
    bool wasBust = false;

    if (newAltitude == 0) {
      // TOUCHDOWN — exact landing
      game.currentAltitudes[playerId] = 0;
      game.currentTurnDartScores[playerId]!.add(dartValue);
      game.dartThrowWasBust[playerId]!.add(false);
      _triggerWin(playerId);
    } else if (newAltitude > 0) {
      // Continue descent
      game.currentAltitudes[playerId] = newAltitude;
      game.currentTurnDartScores[playerId]!.add(dartValue);
      game.dartThrowWasBust[playerId]!.add(false);
    } else {
      // newAltitude < 0
      if (game.hardLandingEnabled) {
        // CONSUMES OPTION: hardLandingEnabled
        // CRASH — bust: revert altitude to turn-start value, forfeit remaining darts
        wasBust = true;
        game.currentAltitudes[playerId] =
            game.turnStartAltitude[playerId]!;
        game.currentTurnDartScores[playerId]!.add(dartValue);
        game.dartThrowWasBust[playerId]!.add(true);
        // Forfeit remaining darts by setting counter to maxDartsPerTurn
        game.dartsThrown[playerId] = game.maxDartsPerTurn;
      } else {
        // Hard Landing OFF: overshoot still counts as touchdown (spec §5 d)
        // CONSUMES OPTION: hardLandingEnabled (false branch)
        game.currentAltitudes[playerId] = newAltitude;
        game.currentTurnDartScores[playerId]!.add(dartValue);
        game.dartThrowWasBust[playerId]!.add(false);
        _triggerWin(playerId);
      }
    }

    // End-of-turn check: 3 darts thrown, bust, or win
    if ((game.dartsThrown[playerId] ?? 0) >= game.maxDartsPerTurn ||
        game.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  void _triggerWin(String playerId) {
    _currentGame!.winnerId = playerId;
    _currentGame!.state = LunarLanderGameState.finished;
  }

  // ─── advanceTurn ─────────────────────────────────────────────────────────────

  /// Advances to the next player after takeout is complete.
  void advanceTurn() {
    if (_currentGame == null) return;
    if (!_waitingForTakeout) return;

    if (_currentGame!.hasWinner()) {
      _waitingForTakeout = false;
      notifyListeners();
      return;
    }

    if (!isGameActive) return;

    _currentGame!.advanceToNextPlayer();
    _waitingForTakeout = false;
    notifyListeners();
  }

  // ─── skipTurn ────────────────────────────────────────────────────────────────

  void skipTurn() {
    if (_currentGame == null) return;

    final playerId = _currentGame!.getCurrentPlayerId();
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

    if (!GameSkipTurnHelper.canSkipTurn(
      gameActive: isGameActive,
      waitingForTakeout: _waitingForTakeout,
      currentDartCount: dartsThrown,
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    )) {
      return;
    }

    // Visual skip markers for dart slots
    GameSkipTurnHelper.skipRemainingDarts(
      currentDartCount: dartsThrown,
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
      addVisualMarker: (marker) {
        _currentGame!.currentTurnDartScores[playerId] ??= [];
        // Store a 0 score as a skip placeholder in the score list
        _currentGame!.currentTurnDartScores[playerId]!.add(0);
        _currentGame!.dartThrowWasBust[playerId]!.add(false);
      },
    );

    _waitingForTakeout = true;
    notifyListeners();
  }

  // ─── checkWinCondition ───────────────────────────────────────────────────────

  bool checkWinCondition() {
    return _currentGame?.hasWinner() ?? false;
  }

  // ─── endGame ─────────────────────────────────────────────────────────────────

  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = LunarLanderGameState.finished;
    }
    notifyListeners();
  }

  // ─── editPlayerScore ─────────────────────────────────────────────────────────

  /// Edit a previously thrown dart score and replay the turn from turn-start altitude.
  void editPlayerScore({
    required String playerId,
    required int dartIndex,
    required int newScore,
    required int newMultiplier,
  }) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;

    final game = _currentGame!;
    final scores = List<int>.from(
        game.currentTurnDartScores[playerId] ?? []);
    if (dartIndex >= scores.length) return;

    // Save current player index so replay doesn't shift it
    final savedPlayerIndex = game.currentPlayerIndex;

    // Reset this player's turn state
    game.dartsThrown[playerId] = 0;
    game.currentTurnDartScores[playerId] = [];
    game.dartThrowWasBust[playerId] = [];

    // Revert altitude + game state to turn-start
    game.resetToStartOfTurn();

    // Replay all darts with the edited value substituted at dartIndex
    for (int i = 0; i < scores.length; i++) {
      if (game.hasWinner()) break;
      if ((game.dartsThrown[playerId] ?? 0) >= game.maxDartsPerTurn) break;

      int replayScore;
      int replayMultiplier;
      if (i == dartIndex) {
        replayScore = newScore;
        replayMultiplier = newMultiplier;
      } else {
        // Reconstruct original dart: scores[i] is already the dartValue
        // We stored dartValue (score×mult) so we replay as score=dartValue, mult=1
        replayScore = scores[i];
        replayMultiplier = 1;
      }

      final dartValue = game.dartScore(
          score: replayScore, multiplier: replayMultiplier);
      final prevAlt = game.currentAltitudes[playerId]!;
      final newAlt = prevAlt - dartValue;

      game.dartsThrown[playerId] =
          (game.dartsThrown[playerId] ?? 0) + 1;
      game.totalDartsThrown[playerId] =
          (game.totalDartsThrown[playerId] ?? 0) + 1;

      if (newAlt == 0) {
        game.currentAltitudes[playerId] = 0;
        game.currentTurnDartScores[playerId]!.add(dartValue);
        game.dartThrowWasBust[playerId]!.add(false);
        _triggerWin(playerId);
      } else if (newAlt > 0) {
        game.currentAltitudes[playerId] = newAlt;
        game.currentTurnDartScores[playerId]!.add(dartValue);
        game.dartThrowWasBust[playerId]!.add(false);
      } else {
        if (game.hardLandingEnabled) {
          game.currentAltitudes[playerId] =
              game.turnStartAltitude[playerId]!;
          game.currentTurnDartScores[playerId]!.add(dartValue);
          game.dartThrowWasBust[playerId]!.add(true);
          game.dartsThrown[playerId] = game.maxDartsPerTurn;
        } else {
          game.currentAltitudes[playerId] = newAlt;
          game.currentTurnDartScores[playerId]!.add(dartValue);
          game.dartThrowWasBust[playerId]!.add(false);
          _triggerWin(playerId);
        }
      }
    }

    // Restore player index
    game.currentPlayerIndex = savedPlayerIndex;

    // Re-evaluate takeout condition
    if ((game.dartsThrown[playerId] ?? 0) >= game.maxDartsPerTurn ||
        game.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // ─── Save / Restore ──────────────────────────────────────────────────────────

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  Future<void> saveGame(List<Player> players) async {
    debugPrint(
        '[LunarLanderProvider] saveGame called — _saving=$_saving, resumedId=$_resumedSavedGameId');
    if (_currentGame == null || _saving) {
      debugPrint(
          '[LunarLanderProvider] saveGame BLOCKED — game=${_currentGame != null}, _saving=$_saving');
      return;
    }
    _saving = true;
    try {
      final game = _currentGame!;

      // Find leading player (lowest altitude)
      String leaderId = game.playerIds.first;
      int lowestAlt = game.currentAltitudes[leaderId]!;
      for (final id in game.playerIds) {
        final alt = game.currentAltitudes[id] ?? game.startingAltitude;
        if (alt < lowestAlt) {
          lowestAlt = alt;
          leaderId = id;
        }
      }

      final leaderPlayer = players.firstWhere(
        (p) => p.id == leaderId,
        orElse: () => players.first,
      );

      final metadata = SavedGameMetadata.create(
        gameType: 'lunar_lander',
        playerNames: players
            .where((p) => game.playerIds.contains(p.id))
            .map((p) => p.name)
            .toList(),
        progressInfo:
            'Altitude: $lowestAlt / ${game.startingAltitude}',
        gameModeName:
            'Alt: ${game.startingAltitude}${game.hardLandingEnabled ? ", Hard Landing" : ""}',
        leadingPlayerName: leaderPlayer.name,
        leadingPlayerScore: 'Alt: $lowestAlt',
        gameState: game.toJson(),
        waitingForTakeout: _waitingForTakeout,
        existingId: _resumedSavedGameId,
      );

      debugPrint(
          '[LunarLanderProvider] saving with id=${metadata.id}');
      final saved = await SaveGameService(_apiClient).saveGame(metadata);
      if (saved) {
        _resumedSavedGameId = metadata.id;
      }
      debugPrint(
          '[LunarLanderProvider] saveGame completed — saved=$saved, resumedId=$_resumedSavedGameId');
    } finally {
      _saving = false;
    }
  }

  Future<void> restoreGame(SavedGameMetadata savedGame) async {
    _currentGame = LunarLanderGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    _gameStartTime = DateTime.now(); // Resume timing from now
    notifyListeners();
  }

  // ─── clearGame ───────────────────────────────────────────────────────────────

  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
    _gameStartTime = null;
    notifyListeners();
  }
}
