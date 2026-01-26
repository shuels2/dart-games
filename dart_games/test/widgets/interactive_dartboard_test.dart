import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/interactive_dartboard.dart';

void main() {
  group('InteractiveDartboard Widget Tests', () {
    testWidgets('Dartboard renders at specified size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveDartboard(
              size: 600,
              onDartThrow: (score, multiplier, baseScore, position) {},
            ),
          ),
        ),
      );

      // Verify the dartboard is rendered
      expect(find.byType(InteractiveDartboard), findsOneWidget);
    });

    testWidgets('Bullseye (center) registers 50 points', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the center (bullseye)
      await tester.tapAt(tester.getCenter(find.byType(InteractiveDartboard)));
      await tester.pump();

      expect(capturedScore, equals(50));
      expect(capturedMultiplier, equals('bullseye'));
    });

    testWidgets('Outer bull registers 25 points', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        ),
      );

      // Tap slightly off center for outer bull (radius 0.094, so about 5.5% from center)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx + 15, center.dy));
      await tester.pump();

      expect(capturedScore, equals(25));
      expect(capturedMultiplier, equals('outer_bull'));
    });

    testWidgets('Double 20 at top registers 40 points', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;
      int? capturedBaseScore;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                  capturedBaseScore = baseScore;
                },
              ),
            ),
          ),
        ),
      );

      // Tap near top for double 20 (radius 0.953, so about 95% from center)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx, center.dy - 280));
      await tester.pump();

      expect(capturedScore, equals(40));
      expect(capturedMultiplier, equals('double'));
      expect(capturedBaseScore, equals(20));
    });

    testWidgets('Triple 20 registers 60 points', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;
      int? capturedBaseScore;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                  capturedBaseScore = baseScore;
                },
              ),
            ),
          ),
        ),
      );

      // Tap for triple 20 (radius 0.629, so about 63% from center)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx, center.dy - 190));
      await tester.pump();

      expect(capturedScore, equals(60));
      expect(capturedMultiplier, equals('triple'));
      expect(capturedBaseScore, equals(20));
    });

    testWidgets('Single 20 in outer single area registers 20 points', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;
      int? capturedBaseScore;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                  capturedBaseScore = baseScore;
                },
              ),
            ),
          ),
        ),
      );

      // Tap for outer single 20 (radius 0.79, so about 79% from center)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx, center.dy - 235));
      await tester.pump();

      expect(capturedScore, equals(20));
      expect(capturedMultiplier, equals('single'));
      expect(capturedBaseScore, equals(20));
    });

    testWidgets('Single 20 in inner single area registers 20 points', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;
      int? capturedBaseScore;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                  capturedBaseScore = baseScore;
                },
              ),
            ),
          ),
        ),
      );

      // Tap for inner single 20 (radius 0.38, so about 38% from center)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx, center.dy - 115));
      await tester.pump();

      expect(capturedScore, equals(20));
      expect(capturedMultiplier, equals('single'));
      expect(capturedBaseScore, equals(20));
    });

    testWidgets('Dartboard scales correctly - 300px size', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 300,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the center (bullseye) on smaller dartboard
      await tester.tapAt(tester.getCenter(find.byType(InteractiveDartboard)));
      await tester.pump();

      expect(capturedScore, equals(50));
      expect(capturedMultiplier, equals('bullseye'));

      // Tap for double ring on smaller dartboard (radius 0.953 * 150 = 142.95px)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx, center.dy - 140));
      await tester.pump();

      expect(capturedMultiplier, equals('double'));
    });

    testWidgets('Dartboard handles constraint-based sizing', (WidgetTester tester) async {
      int? capturedScore;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: InteractiveDartboard(
                size: 600, // Larger than available space
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                },
              ),
            ),
          ),
        ),
      );

      // Should scale down to fit constraints (400x400)
      await tester.tapAt(tester.getCenter(find.byType(InteractiveDartboard)));
      await tester.pump();

      expect(capturedScore, equals(50)); // Center should still be bullseye
    });

    testWidgets('Dart positions scale when dartboard is resized', (WidgetTester tester) async {
      final dartboardKey = GlobalKey<InteractiveDartboardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 600,
                child: InteractiveDartboard(
                  key: dartboardKey,
                  size: 600,
                  onDartThrow: (score, multiplier, baseScore, position) {},
                ),
              ),
            ),
          ),
        ),
      );

      // Add a dart by tapping
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx + 50, center.dy));
      await tester.pump();

      // Verify dart was added
      expect(dartboardKey.currentState?.dartCount, equals(1));

      // Resize the dartboard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: InteractiveDartboard(
                  key: dartboardKey,
                  size: 600,
                  onDartThrow: (score, multiplier, baseScore, position) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Dart should still be present after resize
      expect(dartboardKey.currentState?.dartCount, equals(1));
    });

    testWidgets('Remove darts functionality works', (WidgetTester tester) async {
      final dartboardKey = GlobalKey<InteractiveDartboardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveDartboard(
              key: dartboardKey,
              size: 600,
              onDartThrow: (score, multiplier, baseScore, position) {},
            ),
          ),
        ),
      );

      // Add some darts
      await tester.tapAt(tester.getCenter(find.byType(InteractiveDartboard)));
      await tester.pump();
      await tester.tapAt(Offset(tester.getCenter(find.byType(InteractiveDartboard)).dx + 50, tester.getCenter(find.byType(InteractiveDartboard)).dy));
      await tester.pump();

      expect(dartboardKey.currentState?.dartCount, equals(2));

      // Remove all darts
      dartboardKey.currentState?.removeDarts();
      await tester.pump();

      expect(dartboardKey.currentState?.dartCount, equals(0));
    });

    testWidgets('Remove single dart functionality works', (WidgetTester tester) async {
      final dartboardKey = GlobalKey<InteractiveDartboardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveDartboard(
              key: dartboardKey,
              size: 600,
              onDartThrow: (score, multiplier, baseScore, position) {},
            ),
          ),
        ),
      );

      // Add 3 darts
      await tester.tapAt(tester.getCenter(find.byType(InteractiveDartboard)));
      await tester.pump();
      await tester.tapAt(Offset(tester.getCenter(find.byType(InteractiveDartboard)).dx + 50, tester.getCenter(find.byType(InteractiveDartboard)).dy));
      await tester.pump();
      await tester.tapAt(Offset(tester.getCenter(find.byType(InteractiveDartboard)).dx - 50, tester.getCenter(find.byType(InteractiveDartboard)).dy));
      await tester.pump();

      expect(dartboardKey.currentState?.dartCount, equals(3));

      // Remove single dart
      dartboardKey.currentState?.removeSingleDart();
      await tester.pump();

      expect(dartboardKey.currentState?.dartCount, equals(2));

      // Remove another
      dartboardKey.currentState?.removeSingleDart();
      await tester.pump();

      expect(dartboardKey.currentState?.dartCount, equals(1));
    });

    testWidgets('Click inside dartboard bounds triggers callback', (WidgetTester tester) async {
      int? capturedScore;
      String? capturedMultiplier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveDartboard(
                size: 600,
                onDartThrow: (score, multiplier, baseScore, position) {
                  capturedScore = score;
                  capturedMultiplier = multiplier;
                },
              ),
            ),
          ),
        ),
      );

      // Tap inside the dartboard bounds (at the edge, should still register)
      final center = tester.getCenter(find.byType(InteractiveDartboard));
      await tester.tapAt(Offset(center.dx, center.dy - 290));
      await tester.pump();

      // Should capture some score (not null)
      expect(capturedScore, isNotNull);
      expect(capturedMultiplier, isNotNull);
    });
  });

  group('InteractiveDartboard Segment Tests', () {
    // Test specific segments around the board
    // These values reflect the actual dartboard segment layout as implemented
    final segmentTests = [
      {'name': '20 (top)', 'dx': 0.0, 'dy': -0.79, 'score': 20},
      {'name': 'Right of 20', 'dx': 0.40, 'dy': -0.69, 'score': 18},
      {'name': 'Right side', 'dx': 0.79, 'dy': 0.0, 'score': 6},
      {'name': 'Right lower', 'dx': 0.69, 'dy': 0.40, 'score': 15},
      {'name': 'Bottom right', 'dx': 0.56, 'dy': 0.56, 'score': 2},
      {'name': 'Bottom', 'dx': 0.0, 'dy': 0.79, 'score': 3},
      {'name': 'Bottom left', 'dx': -0.56, 'dy': 0.56, 'score': 16},
      {'name': 'Left side', 'dx': -0.79, 'dy': 0.0, 'score': 11},
      {'name': 'Left upper', 'dx': -0.69, 'dy': -0.40, 'score': 9},
      {'name': 'Top left', 'dx': -0.56, 'dy': -0.56, 'score': 9},
    ];

    for (final test in segmentTests) {
      testWidgets('Segment ${test['name']} registers correctly', (WidgetTester tester) async {
        int? capturedBaseScore;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: InteractiveDartboard(
                  size: 600,
                  onDartThrow: (score, multiplier, baseScore, position) {
                    capturedBaseScore = baseScore;
                  },
                ),
              ),
            ),
          ),
        );

        // Tap at the specified position (outer single area)
        final center = tester.getCenter(find.byType(InteractiveDartboard));
        final radius = 300.0; // Half of 600
        await tester.tapAt(Offset(
          center.dx + (test['dx'] as double) * radius,
          center.dy + (test['dy'] as double) * radius,
        ));
        await tester.pump();

        expect(capturedBaseScore, equals(test['score']),
            reason: 'Segment ${test['name']} should register ${test['score']}');
      });
    }
  });
}
