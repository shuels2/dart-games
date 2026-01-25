import 'package:flutter/foundation.dart';
import '../models/horse_race_game.dart';
import '../models/player.dart';

class HorseRaceProvider extends ChangeNotifier {
  HorseRaceGame? _currentGame;
  bool _waitingForTakeout = false;

  // Getters
  HorseRaceGame? get currentGame => _currentGame;
  bool get isGameActive => _currentGame?.state == GameState.playing;
  bool get shouldPromptTakeout => _waitingForTakeout;

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

  bool get hasWinner => _currentGame?.hasWinner() ?? false;

  Player? getWinner(List<Player> players) {
    return _currentGame?.getWinner(players);
  }

  // Start a new game
  void startGame(List<Player> players, int targetScore) {
    if (players.isEmpty) {
      print('Cannot start game with no players');
      return;
    }

    if (targetScore < 20 || targetScore > 250) {
      print('Target score must be between 20 and 250');
      return;
    }

    final playerIds = players.map((p) => p.id).toList();
    _currentGame = HorseRaceGame.create(
      playerIds: playerIds,
      targetScore: targetScore,
    );
    _waitingForTakeout = false;

    notifyListeners();
  }

  // Process a dart throw
  void processDartThrow(int score) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return; // Don't accept throws while waiting for takeout

    final currentPlayerId = _currentGame!.getCurrentPlayerId();
    _currentGame!.recordDartThrow(currentPlayerId, score);

    // Check if this was the 3rd dart
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // Handle takeout finished event
  void handleTakeoutFinished() {
    if (_currentGame == null || !isGameActive) return;
    if (!_waitingForTakeout) return;

    // Check if there's a winner before advancing
    if (_currentGame!.hasWinner()) {
      // Game is over, don't advance
      notifyListeners();
      return;
    }

    // Advance to next player
    _currentGame!.advanceToNextPlayer();
    _waitingForTakeout = false;

    notifyListeners();
  }

  // Manually advance to next player (for testing or manual mode)
  void advanceToNextPlayer() {
    if (_currentGame == null || !isGameActive) return;

    if (_currentGame!.hasWinner()) {
      return;
    }

    _currentGame!.advanceToNextPlayer();
    _waitingForTakeout = false;

    notifyListeners();
  }

  // End the current game
  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = GameState.finished;
    }
    notifyListeners();
  }

  // Reset/clear the current game
  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
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
