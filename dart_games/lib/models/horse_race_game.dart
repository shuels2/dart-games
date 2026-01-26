import 'package:uuid/uuid.dart';
import 'player.dart';

enum GameState {
  setup,    // Configuring game
  playing,  // Active game
  finished, // Game over
}

class HorseRaceGame {
  final String id;
  final List<String> playerIds;
  final int targetScore;
  final bool exactScoreMode;
  final DateTime startedAt;

  // Runtime state
  GameState state;
  int currentPlayerIndex;
  Map<String, int> scores;
  Map<String, int> dartsThrown;
  String? winnerId;
  bool currentPlayerBusted;

  HorseRaceGame({
    required this.id,
    required this.playerIds,
    required this.targetScore,
    this.exactScoreMode = false,
    required this.startedAt,
    this.state = GameState.setup,
    this.currentPlayerIndex = 0,
    Map<String, int>? scores,
    Map<String, int>? dartsThrown,
    this.winnerId,
    this.currentPlayerBusted = false,
  })  : scores = scores ?? {},
        dartsThrown = dartsThrown ?? {} {
    // Initialize scores and darts thrown for each player
    for (var playerId in playerIds) {
      this.scores[playerId] ??= 0;
      this.dartsThrown[playerId] ??= 0;
    }
  }

  // Factory constructor to create a new game
  factory HorseRaceGame.create({
    required List<String> playerIds,
    required int targetScore,
    bool exactScoreMode = false,
  }) {
    return HorseRaceGame(
      id: const Uuid().v4(),
      playerIds: playerIds,
      targetScore: targetScore,
      exactScoreMode: exactScoreMode,
      startedAt: DateTime.now(),
      state: GameState.playing,
      currentPlayerIndex: 0,
    );
  }

  // Record a dart throw for the current player
  void recordDartThrow(String playerId, int score) {
    if (state != GameState.playing) return;
    if (playerId != playerIds[currentPlayerIndex]) return;

    final currentScore = scores[playerId] ?? 0;
    final newScore = currentScore + score;

    // Handle exact score mode
    if (exactScoreMode) {
      if (newScore > targetScore) {
        // Player busted - don't update score, mark as busted
        currentPlayerBusted = true;
        dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
        return;
      } else if (newScore == targetScore) {
        // Player hit exact score - they win!
        scores[playerId] = newScore;
        dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
        winnerId = playerId;
        state = GameState.finished;
        return;
      }
    }

    // Normal mode or exact mode without bust/win
    scores[playerId] = newScore;
    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;

    // Check if player has won (greater or equal mode)
    if (!exactScoreMode && scores[playerId]! >= targetScore) {
      winnerId = playerId;
      state = GameState.finished;
    }
  }

  // Check if there's a winner
  bool hasWinner() {
    return winnerId != null;
  }

  // Get the winner from a list of players
  Player? getWinner(List<Player> players) {
    if (winnerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == winnerId);
    } catch (e) {
      return null;
    }
  }

  // Get the current player
  String getCurrentPlayerId() {
    return playerIds[currentPlayerIndex];
  }

  // Get current player from list
  Player getCurrentPlayer(List<Player> players) {
    final currentPlayerId = getCurrentPlayerId();
    return players.firstWhere((p) => p.id == currentPlayerId);
  }

  // Advance to the next player
  void advanceToNextPlayer() {
    if (state != GameState.playing) return;

    // Reset darts thrown for current player
    final currentPlayerId = getCurrentPlayerId();
    dartsThrown[currentPlayerId] = 0;

    // Reset bust flag
    currentPlayerBusted = false;

    // Move to next player
    currentPlayerIndex = (currentPlayerIndex + 1) % playerIds.length;
  }

  // Get current turn darts thrown
  int getCurrentPlayerDartsThrown() {
    final currentPlayerId = getCurrentPlayerId();
    return dartsThrown[currentPlayerId] ?? 0;
  }

  // Get score for a specific player
  int getPlayerScore(String playerId) {
    return scores[playerId] ?? 0;
  }

  // Get sorted list of players by score (for final standings)
  List<MapEntry<String, int>> getSortedScores() {
    final entries = scores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // Convert to JSON for storage (if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerIds': playerIds,
      'targetScore': targetScore,
      'exactScoreMode': exactScoreMode,
      'startedAt': startedAt.toIso8601String(),
      'state': state.toString(),
      'currentPlayerIndex': currentPlayerIndex,
      'scores': scores,
      'dartsThrown': dartsThrown,
      'winnerId': winnerId,
      'currentPlayerBusted': currentPlayerBusted,
    };
  }

  // Create from JSON
  factory HorseRaceGame.fromJson(Map<String, dynamic> json) {
    return HorseRaceGame(
      id: json['id'],
      playerIds: List<String>.from(json['playerIds']),
      targetScore: json['targetScore'],
      exactScoreMode: json['exactScoreMode'] ?? false,
      startedAt: DateTime.parse(json['startedAt']),
      state: GameState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => GameState.setup,
      ),
      currentPlayerIndex: json['currentPlayerIndex'],
      scores: Map<String, int>.from(json['scores']),
      dartsThrown: Map<String, int>.from(json['dartsThrown']),
      winnerId: json['winnerId'],
      currentPlayerBusted: json['currentPlayerBusted'] ?? false,
    );
  }
}
