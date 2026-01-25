import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/interactive_dartboard.dart';
import 'dart:math' as math;

void main() {
  // Standard dartboard number sequence (clockwise from top)
  const List<int> dartboardNumbers = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  ];

  group('Dartboard Segment Tests', () {
    const double boardSize = 600.0;
    const double radius = boardSize / 2;
    final center = const Offset(boardSize / 2, boardSize / 2);

    /// Helper function to calculate position at a given angle and distance
    Offset calculatePosition(int segmentIndex, double radiusMultiplier) {
      final segmentAngle = (2 * math.pi) / 20;
      final angle = (segmentIndex * segmentAngle) - math.pi / 2;
      final distance = radius * radiusMultiplier;
      return Offset(
        center.dx + distance * math.cos(angle),
        center.dy + distance * math.sin(angle),
      );
    }

    group('Bullseye Tests', () {
      testWidgets('Bullseye (50) - center hit', (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveDartboard(
                size: boardSize,
                onDartThrow: (score, multiplier, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        );

        // Tap exactly at center
        await tester.tapAt(center);
        await tester.pump();

        expect(capturedScore, 50);
        expect(capturedMultiplier, 'bullseye');
      });

      testWidgets('Bullseye (50) - edge of bullseye', (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveDartboard(
                size: boardSize,
                onDartThrow: (score, multiplier, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        );

        // Tap at edge of bullseye (radius * 0.036, just inside 0.037)
        final position = Offset(center.dx + radius * 0.036, center.dy);
        await tester.tapAt(position);
        await tester.pump();

        expect(capturedScore, 50);
        expect(capturedMultiplier, 'bullseye');
      });
    });

    group('Outer Bull Tests', () {
      testWidgets('Outer bull (25)', (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveDartboard(
                size: boardSize,
                onDartThrow: (score, multiplier, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        );

        // Tap in outer bull area (radius * 0.065, between 0.037 and 0.094)
        final position = Offset(center.dx + radius * 0.065, center.dy);
        await tester.tapAt(position);
        await tester.pump();

        expect(capturedScore, 25);
        expect(capturedMultiplier, 'outer_bull');
      });
    });

    group('Single Segment Tests', () {
      for (int i = 0; i < dartboardNumbers.length; i++) {
        final number = dartboardNumbers[i];

        testWidgets('Single $number (segment $i) - inner single area',
            (WidgetTester tester) async {
          int? capturedScore;
          String? capturedMultiplier;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: InteractiveDartboard(
                  size: boardSize,
                  onDartThrow: (score, multiplier, position) {
                    capturedScore = score;
                    capturedMultiplier = multiplier;
                  },
                ),
              ),
            ),
          );

          // Test inner single area (radius * 0.38, between 0.094 and 0.582)
          final position = calculatePosition(i, 0.38);
          await tester.tapAt(position);
          await tester.pump();

          expect(capturedScore, number,
              reason: 'Inner single area for segment $i should score $number');
          expect(capturedMultiplier, 'single');
        });

        testWidgets('Single $number (segment $i) - outer single area',
            (WidgetTester tester) async {
          int? capturedScore;
          String? capturedMultiplier;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: InteractiveDartboard(
                  size: boardSize,
                  onDartThrow: (score, multiplier, position) {
                    capturedScore = score;
                    capturedMultiplier = multiplier;
                  },
                ),
              ),
            ),
          );

          // Test outer single area (radius * 0.79, between 0.676 and 0.906)
          final position = calculatePosition(i, 0.79);
          await tester.tapAt(position);
          await tester.pump();

          expect(capturedScore, number,
              reason: 'Outer single area for segment $i should score $number');
          expect(capturedMultiplier, 'single');
        });
      }
    });

    group('Double Segment Tests', () {
      for (int i = 0; i < dartboardNumbers.length; i++) {
        final number = dartboardNumbers[i];
        final expectedScore = number * 2;

        testWidgets('Double $number = $expectedScore (segment $i)',
            (WidgetTester tester) async {
          int? capturedScore;
          String? capturedMultiplier;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: InteractiveDartboard(
                  size: boardSize,
                  onDartThrow: (score, multiplier, position) {
                    capturedScore = score;
                    capturedMultiplier = multiplier;
                  },
                ),
              ),
            ),
          );

          // Test double ring (radius * 0.953, between 0.906 and 1.0)
          final position = calculatePosition(i, 0.953);
          await tester.tapAt(position);
          await tester.pump();

          expect(capturedScore, expectedScore,
              reason: 'Double ring for segment $i should score $expectedScore');
          expect(capturedMultiplier, 'double');
        });
      }
    });

    group('Triple Segment Tests', () {
      for (int i = 0; i < dartboardNumbers.length; i++) {
        final number = dartboardNumbers[i];
        final expectedScore = number * 3;

        testWidgets('Triple $number = $expectedScore (segment $i)',
            (WidgetTester tester) async {
          int? capturedScore;
          String? capturedMultiplier;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: InteractiveDartboard(
                  size: boardSize,
                  onDartThrow: (score, multiplier, position) {
                    capturedScore = score;
                    capturedMultiplier = multiplier;
                  },
                ),
              ),
            ),
          );

          // Test triple ring (radius * 0.629, between 0.582 and 0.676)
          final position = calculatePosition(i, 0.629);
          await tester.tapAt(position);
          await tester.pump();

          expect(capturedScore, expectedScore,
              reason: 'Triple ring for segment $i should score $expectedScore');
          expect(capturedMultiplier, 'triple');
        });
      }
    });

    group('Miss Tests', () {
      testWidgets('Miss - just outside board edge', (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: boardSize * 1.5,
                  height: boardSize * 1.5,
                  child: InteractiveDartboard(
                    size: boardSize,
                    onDartThrow: (score, multiplier, position) {
                      capturedScore = score;
                      capturedMultiplier = multiplier;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // Tap just outside the board edge (radius * 1.01, outside 1.0)
        final widgetCenter = Offset(boardSize * 1.5 / 2, boardSize * 1.5 / 2);
        final dartboardOffset = Offset(
          (boardSize * 1.5 - boardSize) / 2,
          (boardSize * 1.5 - boardSize) / 2,
        );
        final dartboardCenter = Offset(
          dartboardOffset.dx + boardSize / 2,
          dartboardOffset.dy + boardSize / 2,
        );
        final position = Offset(
          dartboardCenter.dx + radius * 1.01,
          dartboardCenter.dy,
        );

        await tester.tapAt(position);
        await tester.pump();

        expect(capturedScore, 0);
        expect(capturedMultiplier, 'miss');
      });
    });

    group('Edge Case Tests', () {
      testWidgets('Boundary between bullseye and outer bull',
          (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveDartboard(
                size: boardSize,
                onDartThrow: (score, multiplier, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        );

        // Just outside bullseye radius (0.038, just outside 0.037)
        final position = Offset(center.dx + radius * 0.038, center.dy);
        await tester.tapAt(position);
        await tester.pump();

        expect(capturedScore, 25);
        expect(capturedMultiplier, 'outer_bull');
      });

      testWidgets('Boundary between triple and single',
          (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveDartboard(
                size: boardSize,
                onDartThrow: (score, multiplier, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        );

        // Just outside triple ring (0.677, just outside 0.676)
        // Should hit segment 0 which is 20
        final position = calculatePosition(0, 0.677);
        await tester.tapAt(position);
        await tester.pump();

        expect(capturedScore, 20);
        expect(capturedMultiplier, 'single');
      });

      testWidgets('Boundary between double and miss',
          (WidgetTester tester) async {
        int? capturedScore;
        String? capturedMultiplier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveDartboard(
                size: boardSize,
                onDartThrow: (score, multiplier, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        );

        // Just inside board (0.999, just inside 1.0)
        // Should hit segment 0 double which is 40
        final position = calculatePosition(0, 0.999);
        await tester.tapAt(position);
        await tester.pump();

        expect(capturedScore, 40);
        expect(capturedMultiplier, 'double');
      });
    });

    group('Comprehensive Score Validation', () {
      test('All single scores should be valid dartboard numbers', () {
        final validScores = [
          1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
          11, 12, 13, 14, 15, 16, 17, 18, 19, 20
        ];

        for (final number in dartboardNumbers) {
          expect(validScores.contains(number), true,
              reason: '$number should be a valid dartboard number');
        }
      });

      test('All segments should be represented', () {
        expect(dartboardNumbers.length, 20);
        expect(dartboardNumbers.toSet().length, 20,
            reason: 'All 20 numbers should be unique');
      });

      test('Correct dartboard sequence starting with 20 at top', () {
        expect(dartboardNumbers[0], 20,
            reason: 'Top segment should be 20');
        expect(dartboardNumbers[10], 3,
            reason: 'Bottom segment should be 3');
      });
    });
  });
}
