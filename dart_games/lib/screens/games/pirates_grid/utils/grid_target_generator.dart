import 'dart:math';
import '../../../../models/pirates_grid_game.dart';

/// Pure utility class that builds the 3x3 target layout for a given difficulty.
///
/// Numbers are randomly selected from 1–20 each game so every grid is unique
/// and every dartboard number is eligible. No state — all methods are static.
class GridTargetGenerator {
  // Hard difficulty position sets
  static const Set<String> _corners = {'0,0', '0,2', '2,0', '2,2'};
  static const Set<String> _edges   = {'0,1', '1,0', '1,2', '2,1'};

  /// Returns the 3x3 target grid for [difficulty].
  ///
  /// Each call shuffles 1–20 and picks 9 unique numbers (8 for Hard, since
  /// the center is always Bull). The [random] parameter is exposed for tests
  /// that need a deterministic seed.
  ///
  /// Easy:   9 random numbers — all `any` requirement
  /// Medium: 9 random numbers — `doubleOrTriple` requirement
  /// Hard:   corners T (triple), edges D (double), center Bull; 8 random numbers
  static List<List<CellTarget>> generate(
    TargetDifficulty difficulty, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final pool = List.generate(20, (i) => i + 1)..shuffle(rng);

    switch (difficulty) {
      case TargetDifficulty.easy:
        final nums = pool.take(9).toList();
        return List.generate(3, (r) => List.generate(3, (c) => CellTarget(
          number: nums[r * 3 + c],
          requirement: CellRequirement.any,
        )));

      case TargetDifficulty.medium:
        final nums = pool.take(9).toList();
        return List.generate(3, (r) => List.generate(3, (c) => CellTarget(
          number: nums[r * 3 + c],
          requirement: CellRequirement.doubleOrTriple,
        )));

      case TargetDifficulty.hard:
        // Center is always Bull; pick 8 numbers for the remaining 8 cells.
        final nums = pool.take(8).toList();
        int idx = 0;
        return List.generate(3, (r) => List.generate(3, (c) {
          final key = '$r,$c';
          if (key == '1,1') {
            return const CellTarget(number: 0, requirement: CellRequirement.bull);
          }
          final n = nums[idx++];
          if (_corners.contains(key)) {
            return CellTarget(number: n, requirement: CellRequirement.tripleOnly);
          } else {
            return CellTarget(number: n, requirement: CellRequirement.doubleOnly);
          }
        }));
    }
  }
}
