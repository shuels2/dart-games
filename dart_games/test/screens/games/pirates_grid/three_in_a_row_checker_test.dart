import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/pirates_grid_game.dart';
import 'package:dart_games/screens/games/pirates_grid/utils/three_in_a_row_checker.dart';

/// Builds an empty 3x3 null matrix.
List<List<String?>> _emptyGrid() =>
    List.generate(3, (_) => List.generate(3, (_) => null));

/// Sets a cell in [grid] to [playerId].
void _set(List<List<String?>> grid, int row, int col, String playerId) {
  grid[row][col] = playerId;
}

void main() {
  group('ThreeInARowChecker', () {
    test('Empty grid returns null', () {
      final grid = _emptyGrid();
      expect(ThreeInARowChecker.findWinningLine(grid, 'p1'), isNull);
    });

    group('Horizontal wins', () {
      test('Top row win detected', () {
        final grid = _emptyGrid();
        _set(grid, 0, 0, 'p1');
        _set(grid, 0, 1, 'p1');
        _set(grid, 0, 2, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result, containsAll([
          const GridPosition(0, 0),
          const GridPosition(0, 1),
          const GridPosition(0, 2),
        ]));
      });

      test('Middle row win detected', () {
        final grid = _emptyGrid();
        _set(grid, 1, 0, 'p1');
        _set(grid, 1, 1, 'p1');
        _set(grid, 1, 2, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
        expect(result!.length, equals(3));
      });

      test('Bottom row win detected', () {
        final grid = _emptyGrid();
        _set(grid, 2, 0, 'p1');
        _set(grid, 2, 1, 'p1');
        _set(grid, 2, 2, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
        expect(result!.length, equals(3));
      });
    });

    group('Vertical wins', () {
      test('Left column win detected', () {
        final grid = _emptyGrid();
        _set(grid, 0, 0, 'p1');
        _set(grid, 1, 0, 'p1');
        _set(grid, 2, 0, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result, containsAll([
          const GridPosition(0, 0),
          const GridPosition(1, 0),
          const GridPosition(2, 0),
        ]));
      });

      test('Middle column win detected', () {
        final grid = _emptyGrid();
        _set(grid, 0, 1, 'p1');
        _set(grid, 1, 1, 'p1');
        _set(grid, 2, 1, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
      });

      test('Right column win detected', () {
        final grid = _emptyGrid();
        _set(grid, 0, 2, 'p1');
        _set(grid, 1, 2, 'p1');
        _set(grid, 2, 2, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
      });
    });

    group('Diagonal wins', () {
      test('Top-left to bottom-right diagonal win detected', () {
        final grid = _emptyGrid();
        _set(grid, 0, 0, 'p1');
        _set(grid, 1, 1, 'p1');
        _set(grid, 2, 2, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result, containsAll([
          const GridPosition(0, 0),
          const GridPosition(1, 1),
          const GridPosition(2, 2),
        ]));
      });

      test('Top-right to bottom-left diagonal win detected', () {
        final grid = _emptyGrid();
        _set(grid, 0, 2, 'p1');
        _set(grid, 1, 1, 'p1');
        _set(grid, 2, 0, 'p1');

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNotNull);
        expect(result!.length, equals(3));
        expect(result, containsAll([
          const GridPosition(0, 2),
          const GridPosition(1, 1),
          const GridPosition(2, 0),
        ]));
      });
    });

    group('Non-win states', () {
      test('2-in-a-row returns null (not yet a winner)', () {
        final grid = _emptyGrid();
        _set(grid, 0, 0, 'p1');
        _set(grid, 0, 1, 'p1');
        // (0,2) is empty

        final result = ThreeInARowChecker.findWinningLine(grid, 'p1');
        expect(result, isNull);
      });

      test('Mixed grid with no winner returns null', () {
        final grid = _emptyGrid();
        // Alternating pattern: no 3-in-a-row for either player
        _set(grid, 0, 0, 'p1');
        _set(grid, 0, 1, 'p2');
        _set(grid, 0, 2, 'p1');
        _set(grid, 1, 0, 'p2');
        _set(grid, 1, 1, 'p1');
        _set(grid, 1, 2, 'p2');
        _set(grid, 2, 0, 'p2');
        _set(grid, 2, 1, 'p1');
        _set(grid, 2, 2, 'p2');

        expect(ThreeInARowChecker.findWinningLine(grid, 'p1'), isNull);
        expect(ThreeInARowChecker.findWinningLine(grid, 'p2'), isNull);
      });

      test('hasAnyWinner returns false for empty grid', () {
        final grid = _emptyGrid();
        expect(ThreeInARowChecker.hasAnyWinner(grid, ['p1', 'p2']), isFalse);
      });

      test('hasAnyWinner returns true when a player has 3 in a row', () {
        final grid = _emptyGrid();
        _set(grid, 0, 0, 'p1');
        _set(grid, 0, 1, 'p1');
        _set(grid, 0, 2, 'p1');
        expect(ThreeInARowChecker.hasAnyWinner(grid, ['p1', 'p2']), isTrue);
      });

      test('Win for one player is not reported for other player', () {
        final grid = _emptyGrid();
        _set(grid, 0, 0, 'p1');
        _set(grid, 0, 1, 'p1');
        _set(grid, 0, 2, 'p1');

        expect(ThreeInARowChecker.findWinningLine(grid, 'p1'), isNotNull);
        expect(ThreeInARowChecker.findWinningLine(grid, 'p2'), isNull);
      });
    });
  });
}
