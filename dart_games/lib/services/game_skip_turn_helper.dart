/// Helper class for consistent skip turn behavior across all games.
///
/// Skip turn behavior:
/// - Adds visual "Skip" markers for remaining darts
/// - Does NOT increment dart throw counters
/// - Does NOT increment turn counters
/// - Does NOT call game-specific dart processing methods
class GameSkipTurnHelper {
  /// Handles skip turn for any game.
  ///
  /// Parameters:
  /// - currentDartCount: How many darts the player has thrown this turn
  /// - maxDartsPerTurn: Maximum darts per turn (usually 3)
  /// - addVisualMarker: Callback to add "Skip" marker to game state
  ///
  /// Returns:
  /// - Number of darts that were skipped (for logging/debugging)
  static int skipRemainingDarts({
    required int currentDartCount,
    required int maxDartsPerTurn,
    required void Function(String marker) addVisualMarker,
  }) {
    if (currentDartCount >= maxDartsPerTurn) {
      return 0; // Already threw all darts
    }

    final remainingDarts = maxDartsPerTurn - currentDartCount;

    // Add visual "Skip" markers only (do NOT process as dart throws)
    for (int i = 0; i < remainingDarts; i++) {
      addVisualMarker('Skip');
    }

    return remainingDarts;
  }

  /// Validates skip turn conditions.
  ///
  /// Returns true if skip turn is allowed, false otherwise.
  static bool canSkipTurn({
    required bool gameActive,
    required bool waitingForTakeout,
    required int currentDartCount,
    required int maxDartsPerTurn,
  }) {
    if (!gameActive) return false;
    if (waitingForTakeout) return false;
    if (currentDartCount >= maxDartsPerTurn) return false;
    return true;
  }
}
