import '../../../../models/pirates_grid_game.dart';

/// Pure utility class for 3-in-a-row detection in a 3x3 grid.
///
/// No state. All methods are static.
class ThreeInARowChecker {
  // All 8 possible winning lines in a 3x3 grid
  static const List<List<GridPosition>> _winningLines = [
    // Horizontal rows
    [GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2)],
    [GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2)],
    [GridPosition(2, 0), GridPosition(2, 1), GridPosition(2, 2)],
    // Vertical columns
    [GridPosition(0, 0), GridPosition(1, 0), GridPosition(2, 0)],
    [GridPosition(0, 1), GridPosition(1, 1), GridPosition(2, 1)],
    [GridPosition(0, 2), GridPosition(1, 2), GridPosition(2, 2)],
    // Diagonals
    [GridPosition(0, 0), GridPosition(1, 1), GridPosition(2, 2)],
    [GridPosition(0, 2), GridPosition(1, 1), GridPosition(2, 0)],
  ];

  /// Returns the 3 grid positions forming a winning line for [playerId],
  /// or null if no winning line exists.
  ///
  /// [claimedBy] is a 3x3 matrix where each entry is the playerId of the
  /// player who claimed that cell, or null if the cell is empty.
  static List<GridPosition>? findWinningLine(
    List<List<String?>> claimedBy,
    String playerId,
  ) {
    for (final line in _winningLines) {
      if (_lineOwnedBy(claimedBy, line, playerId)) {
        return List<GridPosition>.from(line);
      }
    }
    return null;
  }

  /// Returns true if any player in [playerIds] has a winning line.
  static bool hasAnyWinner(
    List<List<String?>> claimedBy,
    List<String> playerIds,
  ) {
    for (final playerId in playerIds) {
      if (findWinningLine(claimedBy, playerId) != null) return true;
    }
    return false;
  }

  static bool _lineOwnedBy(
    List<List<String?>> claimedBy,
    List<GridPosition> line,
    String playerId,
  ) {
    return line.every((pos) => claimedBy[pos.row][pos.col] == playerId);
  }
}
