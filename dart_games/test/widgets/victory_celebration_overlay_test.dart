// WS03 §3.7. Five results screens each wrote out three ConfettiWidgets with
// the same nine-line parameter block. These tests pin the shared defaults and
// the two things the extraction had to keep expressible.
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/victory_celebration_overlay.dart';

import 'dart:math';

void main() {
  late ConfettiController controller;

  setUp(() => controller =
      ConfettiController(duration: const Duration(seconds: 1)));
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, VictoryCelebrationOverlay overlay) =>
      tester.pumpWidget(MaterialApp(home: Stack(children: [overlay])));

  group('blastDirectionFor', () {
    test('derives the angle from the alignment', () {
      // The screens hard-coded these next to their alignments — two lists that
      // had to be kept in step by hand.
      expect(VictoryCelebrationOverlay.blastDirectionFor(Alignment.topLeft),
          pi / 4);
      expect(VictoryCelebrationOverlay.blastDirectionFor(Alignment.topCenter),
          pi / 2);
      expect(VictoryCelebrationOverlay.blastDirectionFor(Alignment.topRight),
          3 * pi / 4);
    });
  });

  group('VictoryCelebrationOverlay', () {
    testWidgets('renders one emitter per alignment', (tester) async {
      await pump(
        tester,
        VictoryCelebrationOverlay(
          controller: controller,
          colors: const [Colors.red],
        ),
      );
      expect(find.byType(ConfettiWidget), findsNWidgets(3));
    });

    testWidgets('every emitter shares one controller', (tester) async {
      await pump(
        tester,
        VictoryCelebrationOverlay(
          controller: controller,
          colors: const [Colors.red],
        ),
      );
      final emitters = tester.widgetList<ConfettiWidget>(
          find.byType(ConfettiWidget));
      for (final e in emitters) {
        expect(e.confettiController, same(controller),
            reason: 'a second controller means the bursts desynchronise');
      }
    });

    testWidgets('applies the shared defaults', (tester) async {
      await pump(
        tester,
        VictoryCelebrationOverlay(
          controller: controller,
          colors: const [Colors.red, Colors.blue],
        ),
      );
      final e = tester
          .widgetList<ConfettiWidget>(find.byType(ConfettiWidget))
          .first;
      expect(e.emissionFrequency, 0.05);
      expect(e.numberOfParticles, 30);
      expect(e.gravity, 0.1);
      expect(e.colors, [Colors.red, Colors.blue]);
    });

    testWidgets('numberOfParticlesFor varies the count per emitter',
        (tester) async {
      // Carnival Derby fires a heavier central burst: 30 from the centre and
      // 20 from each corner. Averaging that away would change how the screen
      // looks.
      await pump(
        tester,
        VictoryCelebrationOverlay(
          controller: controller,
          colors: const [Colors.red],
          numberOfParticlesFor: (a) => a == Alignment.topCenter ? 30 : 20,
        ),
      );
      final counts = tester
          .widgetList<ConfettiWidget>(find.byType(ConfettiWidget))
          .map((e) => e.numberOfParticles)
          .toList();
      expect(counts.where((c) => c == 30), hasLength(1));
      expect(counts.where((c) => c == 20), hasLength(2));
    });

    testWidgets('a custom alignment list drives emitter count',
        (tester) async {
      await pump(
        tester,
        VictoryCelebrationOverlay(
          controller: controller,
          colors: const [Colors.red],
          alignments: const [Alignment.topLeft, Alignment.topRight],
        ),
      );
      expect(find.byType(ConfettiWidget), findsNWidgets(2));
    });
  });
}
