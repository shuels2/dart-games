import '../models/horse_race_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/api/api_client.dart';
import 'game_provider_base.dart';

class HorseRaceProvider extends GameProviderBase<HorseRaceGame> {
  /// Internal alias for [GameProviderBase.game] — keeps the game logic below
  /// untouched while the storage lives in the base.
  HorseRaceGame? get _currentGame => game;
  set _currentGame(HorseRaceGame? value) => game = value;

  final ApiClient? _apiClient;

  HorseRaceProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // Getters
  HorseRaceGame? get currentGame => _currentGame;
  @override
  bool get isGameActive => _currentGame?.state == GameState.playing;

  Player? getCurrentPlayer(List<Player> players) {
    if (_currentGame == null) return null;
    return _currentGame!.getCurrentPlayer(players);
  }

  String? getCurrentPlayerId() {
    return _currentGame?.getCurrentPlayerId();
  }

  int getCurrentPlayerDartsThrown() {
    return _currentGame?.getCurrentPlayerDartsThrown() ?? 0;
  }

  int getPlayerScore(String playerId) {
    return _currentGame?.getPlayerScore(playerId) ?? 0;
  }

  List<String> getCurrentTurnDartScores(String playerId) {
    return _currentGame?.getCurrentTurnDartScores(playerId) ?? [];
  }

  @override
  bool get hasWinner => _currentGame?.hasWinner() ?? false;

  bool get currentPlayerBusted => _currentGame?.currentPlayerBusted ?? false;

  Player? getWinner(List<Player> players) {
    return _currentGame?.getWinner(players);
  }

  // Start a new game
  void startGame(List<Player> players, int targetScore, {bool exactScoreMode = false}) {
    if (players.isEmpty) {
      print('Cannot start game with no players');
      return;
    }

    if (targetScore < 20 || targetScore > 250) {
      print('Target score must be between 20 and 250');
      return;
    }

    final playerIds = players.map((p) => p.id).toList();
    // A genuinely new game must not inherit the previous game's saved-game
    // slot — otherwise this game's first save overwrites (and destroys) a
    // still-resumable abandoned game. See F2 in the plan notes.
    clearResumedSavedGameId();

    _currentGame = HorseRaceGame.create(
      playerIds: playerIds,
      targetScore: targetScore,
      exactScoreMode: exactScoreMode,
    );
    waitingForTakeout = false;

    notifyListeners();
  }

  // Process a dart throw
  void processDartThrow(int score, {String? dartDisplay}) {
    if (_currentGame == null || !isGameActive) return;
    if (shouldPromptTakeout) return; // Don't accept throws while waiting for takeout

    final currentPlayerId = _currentGame!.getCurrentPlayerId();
    _currentGame!.recordDartThrow(currentPlayerId, score, dartDisplay: dartDisplay);

    // Check if player busted (in exact score mode)
    if (_currentGame!.currentPlayerBusted) {
      waitingForTakeout = true;
      notifyListeners();
      return;
    }

    // Check if this was the 3rd dart or if there's a winner
    checkTakeoutCondition(
      dartsThrown: _currentGame!.getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: 3,
    );

    notifyListeners();
  }

  // Skip remaining darts in current turn
  void skipTurn() {
    if (_currentGame == null) return;

    final currentPlayerId = _currentGame!.getCurrentPlayerId();

    runSkipTurn(
      dartsThrown: _currentGame!.getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
      addVisualMarker: (marker) {
        _currentGame!.currentTurnDartScores[currentPlayerId] ??= [];
        _currentGame!.currentTurnDartScores[currentPlayerId]!.add(marker);
      },
    );
  }

  // Update all three dart scores at once and recalculate turn
  void updateAllDartScores(String playerId, List<String> newDartSegments) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;
    if (newDartSegments.length != 3) return;

    // Store current game state to restore player index after recalculation
    final currentPlayerIndex = _currentGame!.currentPlayerIndex;

    // Clear the current turn data for this player
    _currentGame!.currentTurnDartScores[playerId] = [];
    _currentGame!.dartsThrown[playerId] = 0;

    // Reset game state to start of turn
    _currentGame!.resetToStartOfTurn(playerId);

    // Replay all three darts with the new values in order
    // This ensures each dart is processed with the correct game state
    for (int i = 0; i < 3; i++) {
      final segment = newDartSegments[i];

      // Parse the segment to get score and display
      final parsed = _parseSegment(segment);
      if (parsed == null) {
        // Miss
        _currentGame!.recordDartThrow(playerId, 0, dartDisplay: 'Miss');
      } else {
        final score = parsed['score'] as int;
        _currentGame!.recordDartThrow(playerId, score, dartDisplay: segment);
      }
    }

    // Restore player index
    _currentGame!.currentPlayerIndex = currentPlayerIndex;

    // Check if turn should end
    checkTakeoutCondition(
      dartsThrown: _currentGame!.getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: 3,
    );

    notifyListeners();
  }

  // Parse dartboard segment string (e.g., "S20", "D15", "T19", "Bull", "25", "Miss")
  Map<String, dynamic>? _parseSegment(String segment) {
    // Handle bulls
    if (segment == 'Bull') {
      return {'score': 50};
    }
    if (segment == '25') {
      return {'score': 25};
    }
    if (segment == 'Miss' || segment == 'None' || segment.isEmpty) {
      return null; // Treat as miss
    }

    // Parse regular segments (S20, D15, T19, etc.)
    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(segment);
    if (match == null) return null;

    final baseNumber = int.parse(match.group(1)!);
    int multiplier = 1;

    if (segment.startsWith('D') || segment.startsWith('d')) {
      multiplier = 2;
    } else if (segment.startsWith('T') || segment.startsWith('t')) {
      multiplier = 3;
    }

    return {'score': baseNumber * multiplier};
  }

  // Handle takeout finished event.
  //
  // Overrides the base flow: horse race deliberately KEEPS the takeout flag
  // latched on a win (the base clears it) — the screen navigates to results
  // with the prompt still up — and it requires an active game up front.
  @override
  void handleTakeoutFinished() {
    if (_currentGame == null || !isGameActive) return;
    if (!shouldPromptTakeout) return;

    // Check if there's a winner before advancing
    if (_currentGame!.hasWinner()) {
      // Game is over, don't advance
      notifyListeners();
      return;
    }

    // Advance to next player
    _currentGame!.advanceToNextPlayer();
    waitingForTakeout = false;

    notifyListeners();
  }

  // Manually advance to next player (for testing or manual mode)
  @override
  void advanceToNextPlayer() {
    if (_currentGame == null || !isGameActive) return;

    if (_currentGame!.hasWinner()) {
      return;
    }

    _currentGame!.advanceToNextPlayer();
    waitingForTakeout = false;

    notifyListeners();
  }

  // --- Save/Restore ---

  Future<void> saveGame(List<Player> players, {bool isAutoSave = false}) async {
    await persistSave(SaveGameService(_apiClient), (existingId) {
      final game = _currentGame!;

      // Find leading player
      final sorted = game.getSortedScores();
      final leaderId =
          sorted.isNotEmpty ? sorted.first.key : game.playerIds.first;
      final leaderPlayer = players.firstWhere((p) => p.id == leaderId,
          orElse: () => players.first);
      final leaderScore = game.getPlayerScore(leaderId);

      return SavedGameMetadata.create(
        gameType: 'carnival_derby',
        playerNames: players
            .where((p) => game.playerIds.contains(p.id))
            .map((p) => p.name)
            .toList(),
        progressInfo: 'Leading: $leaderScore pts',
        gameModeName:
            'Target: ${game.targetScore}${game.exactScoreMode ? ' (Perfect Finish)' : ''}',
        leadingPlayerName: leaderPlayer.name,
        leadingPlayerScore: '$leaderScore pts',
        gameState: game.toJson(),
        waitingForTakeout: shouldPromptTakeout,
        isAutoSave: isAutoSave,
        existingId: existingId,
      );
    });
  }

  @override
  void loadGameState(Map<String, dynamic> json) {
    _currentGame = HorseRaceGame.fromJson(json);
  }

  // End the current game
  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = GameState.finished;
    }
    notifyListeners();
  }

  // Get final standings (sorted by score)
  List<MapEntry<String, int>> getFinalStandings() {
    if (_currentGame == null) return [];
    return _currentGame!.getSortedScores();
  }

  // Calculate horse position as a percentage (0.0 to 1.0)
  double getHorsePosition(String playerId) {
    if (_currentGame == null) return 0.0;

    final score = _currentGame!.getPlayerScore(playerId);
    final targetScore = _currentGame!.targetScore;

    if (targetScore == 0) return 0.0;

    final position = score / targetScore;
    return position.clamp(0.0, 1.0);
  }
}
