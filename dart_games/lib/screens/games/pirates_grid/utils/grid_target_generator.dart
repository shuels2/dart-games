import '../../../../models/pirates_grid_game.dart';

/// Pure utility class that builds the 3x3 target layout for a given difficulty.
///
/// No state. All methods are static.
class GridTargetGenerator {
  // ─── Number layout (same for Easy and Medium) ────────────────────────────────
  //
  //  Row 0: [20, 18, 16]
  //  Row 1: [19, 17, 15]
  //  Row 2: [14, 12, 10]
  //
  // Hard layout:
  //  Row 0: [T20, D18, T16]     corners=tripleOnly, edges=doubleOnly
  //  Row 1: [D19, Bull, D15]    center=bull
  //  Row 2: [T14, D12, T10]
  //
  // Corner positions: (0,0), (0,2), (2,0), (2,2)
  // Edge positions:   (0,1), (1,0), (1,2), (2,1)
  // Center position:  (1,1)

  static const List<List<int>> _numbers = [
    [20, 18, 16],
    [19, 17, 15],
    [14, 12, 10],
  ];

  // Hard difficulty: which positions are corners, edges, and center
  static const Set<String> _corners = {'0,0', '0,2', '2,0', '2,2'};
  static const Set<String> _edges   = {'0,1', '1,0', '1,2', '2,1'};
  static const String _center       = '1,1';

  /// Returns the 3x3 target grid for [difficulty].
  ///
  /// Easy:   numbers 20/18/16 / 19/17/15 / 14/12/10 — all `any` requirement
  /// Medium: same numbers, `doubleOrTriple` requirement
  /// Hard:   corners T (triple), edges D (double), center Bull
  static List<List<CellTarget>> generate(TargetDifficulty difficulty) {
    switch (difficulty) {
      case TargetDifficulty.easy:
        return _buildGrid((row, col) => CellTarget(
          number: _numbers[row][col],
          requirement: CellRequirement.any,
        ));

      case TargetDifficulty.medium:
        return _buildGrid((row, col) => CellTarget(
          number: _numbers[row][col],
          requirement: CellRequirement.doubleOrTriple,
        ));

      case TargetDifficulty.hard:
        return _buildGrid((row, col) {
          final key = '$row,$col';
          if (key == _center) {
            return const CellTarget(number: 0, requirement: CellRequirement.bull);
          } else if (_corners.contains(key)) {
            return CellTarget(
              number: _numbers[row][col],
              requirement: CellRequirement.tripleOnly,
            );
          } else if (_edges.contains(key)) {
            return CellTarget(
              number: _numbers[row][col],
              requirement: CellRequirement.doubleOnly,
            );
          } else {
            // Fallback (should never be reached in a 3x3 grid)
            return CellTarget(
              number: _numbers[row][col],
              requirement: CellRequirement.any,
            );
          }
        });
    }
  }

  static List<List<CellTarget>> _buildGrid(
    CellTarget Function(int row, int col) factory,
  ) {
    return List.generate(3, (row) => List.generate(3, (col) => factory(row, col)));
  }
}
