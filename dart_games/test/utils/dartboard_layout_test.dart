import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/utils/dartboard_layout.dart';

void main() {
  group('DartboardLayout - clockwiseOrder', () {
    test('contains exactly 20 segments', () {
      expect(DartboardLayout.clockwiseOrder.length, 20);
    });

    test('contains all numbers 1 through 20', () {
      final sorted = List<int>.from(DartboardLayout.clockwiseOrder)..sort();
      expect(sorted, List.generate(20, (i) => i + 1));
    });

    test('starts with 20 at the top', () {
      expect(DartboardLayout.clockwiseOrder.first, 20);
    });

    test('has correct full clockwise sequence', () {
      expect(
        DartboardLayout.clockwiseOrder,
        [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5],
      );
    });
  });

  group('DartboardLayout - getNeighbors', () {
    test('returns neighbors of 20 (top, wraps around)', () {
      // 20 is at index 0; left wraps to index 19 (5), right is index 1 (1)
      expect(DartboardLayout.getNeighbors(20), [5, 1]);
    });

    test('returns neighbors of 5 (last element, wraps around)', () {
      // 5 is at index 19; left is index 18 (12), right wraps to index 0 (20)
      expect(DartboardLayout.getNeighbors(5), [12, 20]);
    });

    test('returns neighbors of 1 (second element)', () {
      // 1 is at index 1; left is index 0 (20), right is index 2 (18)
      expect(DartboardLayout.getNeighbors(1), [20, 18]);
    });

    test('returns neighbors of 6', () {
      // 6 is at index 5; left is index 4 (13), right is index 6 (10)
      expect(DartboardLayout.getNeighbors(6), [13, 10]);
    });

    test('returns neighbors of 11', () {
      // 11 is at index 15; left is index 14 (8), right is index 16 (14)
      expect(DartboardLayout.getNeighbors(11), [8, 14]);
    });

    test('returns empty list for invalid number 0', () {
      expect(DartboardLayout.getNeighbors(0), []);
    });

    test('returns empty list for invalid number 21', () {
      expect(DartboardLayout.getNeighbors(21), []);
    });

    test('returns empty list for negative number', () {
      expect(DartboardLayout.getNeighbors(-1), []);
    });
  });

  group('DartboardLayout - isNeighbor', () {
    test('returns true when thrown is left neighbor of target', () {
      // 20 neighbors are [5, 1], so 5 is a neighbor of 20
      expect(DartboardLayout.isNeighbor(5, 20), isTrue);
    });

    test('returns true when thrown is right neighbor of target', () {
      // 20 neighbors are [5, 1], so 1 is a neighbor of 20
      expect(DartboardLayout.isNeighbor(1, 20), isTrue);
    });

    test('returns false when not a neighbor', () {
      // 20 neighbors are [5, 1]; 18 is not a neighbor of 20
      expect(DartboardLayout.isNeighbor(18, 20), isFalse);
    });

    test('returns false when same number (not a neighbor of itself)', () {
      expect(DartboardLayout.isNeighbor(20, 20), isFalse);
    });

    test('returns false for thrown out of range (0)', () {
      expect(DartboardLayout.isNeighbor(0, 20), isFalse);
    });

    test('returns false for target out of range (21)', () {
      expect(DartboardLayout.isNeighbor(1, 21), isFalse);
    });

    test('returns false for both out of range', () {
      expect(DartboardLayout.isNeighbor(0, 25), isFalse);
    });

    test('returns false for negative thrown', () {
      expect(DartboardLayout.isNeighbor(-1, 5), isFalse);
    });

    test('returns false for negative target', () {
      expect(DartboardLayout.isNeighbor(5, -1), isFalse);
    });

    test('wraparound neighbor check: 12 is neighbor of 5', () {
      // 5 neighbors are [12, 20]
      expect(DartboardLayout.isNeighbor(12, 5), isTrue);
    });

    test('wraparound neighbor check: 20 is neighbor of 5', () {
      // 5 neighbors are [12, 20]
      expect(DartboardLayout.isNeighbor(20, 5), isTrue);
    });
  });

  group('DartboardLayout - findNeighborTarget', () {
    test('returns first matching target', () {
      // 1 neighbors of 20 are [5, 1], so thrown=5 is neighbor of 20
      final result = DartboardLayout.findNeighborTarget(5, [20, 12]);
      expect(result, 20);
    });

    test('returns null when no targets match', () {
      // 10 neighbors are [6, 15]; 3 is not adjacent to any of these targets
      final result = DartboardLayout.findNeighborTarget(3, [10, 6, 15]);
      // 3 neighbors: [17, 19]; none of [10, 6, 15] are 17 or 19
      // Wait - isNeighbor checks if thrown is neighbor of target
      // isNeighbor(3, 10) => getNeighbors(10) = [6, 15], 3 not in [6, 15] => false
      // isNeighbor(3, 6) => getNeighbors(6) = [13, 10], 3 not in [13, 10] => false
      // isNeighbor(3, 15) => getNeighbors(15) = [10, 2], 3 not in [10, 2] => false
      expect(result, isNull);
    });

    test('returns first match when multiple targets could match', () {
      // thrown = 1; targets = [20, 18]
      // isNeighbor(1, 20) => getNeighbors(20) = [5, 1], 1 in [5, 1] => true
      // So first match is 20
      final result = DartboardLayout.findNeighborTarget(1, [20, 18]);
      expect(result, 20);
    });

    test('skips non-matching targets and finds later match', () {
      // thrown = 1; targets = [6, 18]
      // isNeighbor(1, 6) => getNeighbors(6) = [13, 10], 1 not in => false
      // isNeighbor(1, 18) => getNeighbors(18) = [1, 4], 1 in => true
      final result = DartboardLayout.findNeighborTarget(1, [6, 18]);
      expect(result, 18);
    });

    test('returns null for empty target list', () {
      final result = DartboardLayout.findNeighborTarget(1, []);
      expect(result, isNull);
    });

    test('ignores targets outside 1-20 range', () {
      final result = DartboardLayout.findNeighborTarget(1, [0, 21, 25]);
      expect(result, isNull);
    });
  });

  group('DartboardLayout - findAllNeighborTargets', () {
    test('returns all matching targets', () {
      // thrown = 1; targets = [20, 18, 6]
      // isNeighbor(1, 20) => neighbors of 20 are [5, 1] => true
      // isNeighbor(1, 18) => neighbors of 18 are [1, 4] => true
      // isNeighbor(1, 6) => neighbors of 6 are [13, 10] => false
      final result = DartboardLayout.findAllNeighborTargets(1, [20, 18, 6]);
      expect(result, [20, 18]);
    });

    test('returns empty list when no targets match', () {
      // thrown = 7; targets = [1, 2]
      // isNeighbor(7, 1) => neighbors of 1 are [20, 18] => false
      // isNeighbor(7, 2) => neighbors of 2 are [15, 17] => false
      final result = DartboardLayout.findAllNeighborTargets(7, [1, 2]);
      expect(result, isEmpty);
    });

    test('returns empty list for empty target list', () {
      final result = DartboardLayout.findAllNeighborTargets(1, []);
      expect(result, isEmpty);
    });

    test('filters out invalid targets', () {
      // thrown = 1; targets = [0, 20, 21]
      // 0 and 21 are filtered out by target >= 1 && target <= 20
      // isNeighbor(1, 20) => true
      final result = DartboardLayout.findAllNeighborTargets(1, [0, 20, 21]);
      expect(result, [20]);
    });

    test('returns single match when only one target neighbors', () {
      // thrown = 13; targets = [4, 6, 20]
      // neighbors of 4 are [18, 13] => true (13 is in neighbors of 4)
      // neighbors of 6 are [13, 10] => true (13 is in neighbors of 6)
      // neighbors of 20 are [5, 1] => false
      final result = DartboardLayout.findAllNeighborTargets(13, [4, 6, 20]);
      expect(result, [4, 6]);
    });
  });
}
