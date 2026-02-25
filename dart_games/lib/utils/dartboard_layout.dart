/// Utility class for dartboard physical layout and neighbor number lookups.
class DartboardLayout {
  /// Standard dartboard clockwise order starting from the top (20).
  static const List<int> clockwiseOrder = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  ];

  /// Get the two adjacent numbers on the physical dartboard for a given number (1-20).
  static List<int> getNeighbors(int number) {
    final index = clockwiseOrder.indexOf(number);
    if (index == -1) return [];
    final left = clockwiseOrder[(index - 1 + 20) % 20];
    final right = clockwiseOrder[(index + 1) % 20];
    return [left, right];
  }

  /// Check if [thrown] is physically adjacent to [target] on the dartboard.
  static bool isNeighbor(int thrown, int target) {
    if (thrown < 1 || thrown > 20 || target < 1 || target > 20) return false;
    return getNeighbors(target).contains(thrown);
  }

  /// Find which target (from a list) a thrown number is a neighbor of.
  /// Returns the first matching target, or null if not a neighbor of any.
  static int? findNeighborTarget(int thrown, List<int> targets) {
    for (final target in targets) {
      if (target >= 1 && target <= 20 && isNeighbor(thrown, target)) {
        return target;
      }
    }
    return null;
  }
}
