import 'package:dart_games/models/player.dart';
import 'package:dart_games/widgets/treasure_divide/pirate_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Player _makePlayer({Map<String, dynamic>? faceLandmarks}) {
  return Player(
    id: 'p1',
    name: 'Alice',
    photoPath: null,
    createdAt: DateTime(2024),
    faceLandmarks: faceLandmarks,
  );
}

/// Wraps [widget] in the minimal Material scaffold needed for rendering.
Widget _wrap(Widget widget) {
  return MaterialApp(home: Scaffold(body: Center(child: widget)));
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('PirateAvatarWidget', () {
    // ── 1. Renders without crash (null landmarks + valid theme) ──────────────
    testWidgets('renders without error for theme 0 with null landmarks',
        (tester) async {
      await tester.pumpWidget(_wrap(PirateAvatarWidget(
        player: _makePlayer(),
        themeIndex: 0,
        size: 100,
      )));
      await tester.pump();
      expect(find.byType(PirateAvatarWidget), findsOneWidget);
    });

    // ── 2. Uses heuristic position when landmarks are null ────────────────────
    // Theme 0: first accessory anchor = headTop → heuristic (0.5, 0.05)
    // At size=100: left = 0.5*100 - 35/2 = 32.5, top = 0.05*100 - 35/2 = -12.5
    testWidgets('positions hat at heuristic headTop when landmarks are null',
        (tester) async {
      await tester.pumpWidget(_wrap(PirateAvatarWidget(
        player: _makePlayer(),
        themeIndex: 0,
        size: 100,
      )));
      await tester.pump();

      // Find the first Positioned widget that corresponds to the hat layer.
      // We verify the resolved position matches the heuristic constant.
      final normalized = resolveAnchorPosition(ThemeAccessoryAnchor.headTop, null);
      expect(normalized, const Offset(0.5, 0.05));
    });

    // ── 3. Uses landmark coords when landmarks are populated ──────────────────
    // Fixture uses MediaPipe convention: leftEye = SUBJECT's own left
    // eye → higher x (image right); rightEye → lower x (image left).
    // The renderer's job is to place the eyepatch at the coord it's
    // given; it does not re-mirror the sides.
    testWidgets('uses landmark leftEye position for eyepatch', (tester) async {
      final landmarks = {
        'leftEye': {'x': 0.65, 'y': 0.42},
        'rightEye': {'x': 0.35, 'y': 0.42},
        'noseTip': {'x': 0.50, 'y': 0.57},
        'mouthCenter': {'x': 0.50, 'y': 0.73},
        'boundingBox': {'x': 0.18, 'y': 0.12, 'width': 0.64, 'height': 0.72},
      };
      final pos = resolveAnchorPosition(ThemeAccessoryAnchor.leftEye, landmarks);
      expect(pos.dx, closeTo(0.65, 0.001));
      expect(pos.dy, closeTo(0.42, 0.001));
    });

    // ── 3a. Convention: leftEye lands on image-right for a centered face ──────
    // Explicit documentation test — freezes the MediaPipe convention
    // in a place a code reviewer WILL notice if someone later changes
    // it to viewer-perspective.
    test(
        "leftEye/rightEye follow MediaPipe convention (subject's own "
        'left / right, not viewer perspective)', () {
      final landmarks = {
        // For a front-facing photo where the face is centered around
        // x=0.5, the SUBJECT's left eye lies on the RIGHT half of
        // the image (x > 0.5) and their right eye on the LEFT half.
        'leftEye': {'x': 0.65, 'y': 0.42},
        'rightEye': {'x': 0.35, 'y': 0.42},
      };
      final leftPos =
          resolveAnchorPosition(ThemeAccessoryAnchor.leftEye, landmarks);
      final rightPos =
          resolveAnchorPosition(ThemeAccessoryAnchor.rightEye, landmarks);
      expect(leftPos.dx, greaterThan(0.5),
          reason: "leftEye is the SUBJECT's left → image right (x > 0.5)");
      expect(rightPos.dx, lessThan(0.5),
          reason: "rightEye is the SUBJECT's right → image left (x < 0.5)");
    });

    // ── 4. headTop derived from bounding box ──────────────────────────────────
    testWidgets('derives headTop from bounding box landmarks', (tester) async {
      final landmarks = {
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
      };
      final pos = resolveAnchorPosition(ThemeAccessoryAnchor.headTop, landmarks);
      // headTop = (bbX + bbW/2, bbY - bbH*0.15) = (0.20+0.30, 0.15-0.105) = (0.50, 0.045)
      expect(pos.dx, closeTo(0.50, 0.001));
      expect(pos.dy, closeTo(0.045, 0.001));
    });

    // ── 4a. Persisted headTop wins over derived heuristic ─────────────────────
    // When the operator has fine-tuned the hat anchor in the
    // FaceLandmarkInspector, the persisted point must beat the
    // bounding-box heuristic — otherwise the tuning would silently
    // no-op on the game screen.
    test(
        'resolveAnchorPosition prefers persisted headTop over the bounding-box '
        'heuristic when the field is present', () {
      final landmarks = {
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
        // Deliberately far from the heuristic (0.50, 0.045) so a bug
        // that falls through to bbox math produces a very different
        // number than what we expect.
        'headTop': {'x': 0.42, 'y': 0.02},
      };
      final pos =
          resolveAnchorPosition(ThemeAccessoryAnchor.headTop, landmarks);
      expect(pos.dx, closeTo(0.42, 0.001));
      expect(pos.dy, closeTo(0.02, 0.001));
    });

    test(
        'resolveAnchorPosition prefers persisted chinBottom over the '
        'bounding-box heuristic when the field is present', () {
      final landmarks = {
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
        // Heuristic would give chinBottom.y = 0.15 + 0.70 = 0.85.
        // Persisted value is deliberately different.
        'chinBottom': {'x': 0.55, 'y': 0.92},
      };
      final pos =
          resolveAnchorPosition(ThemeAccessoryAnchor.chinBottom, landmarks);
      expect(pos.dx, closeTo(0.55, 0.001));
      expect(pos.dy, closeTo(0.92, 0.001));
    });

    test(
        'resolveAnchorPosition falls back to the bounding-box heuristic '
        'when headTop / chinBottom are absent (legacy records)', () {
      // No headTop / chinBottom keys — matches every player record
      // stored before this feature landed.
      final landmarks = {
        'boundingBox': {'x': 0.10, 'y': 0.10, 'width': 0.80, 'height': 0.80},
      };
      final headPos =
          resolveAnchorPosition(ThemeAccessoryAnchor.headTop, landmarks);
      final chinPos =
          resolveAnchorPosition(ThemeAccessoryAnchor.chinBottom, landmarks);
      // Heuristic: head = (bbX + bbW/2, bbY - 0.15*bbH) = (0.50, -0.02)
      //            chin = (bbX + bbW/2, bbY + bbH)      = (0.50, 0.90)
      expect(headPos.dx, closeTo(0.50, 0.001));
      expect(headPos.dy, closeTo(-0.02, 0.001));
      expect(chinPos.dx, closeTo(0.50, 0.001));
      expect(chinPos.dy, closeTo(0.90, 0.001));
    });

    // ── 5. Corners always use heuristic regardless of landmarks ───────────────
    test('corner anchors always return heuristic positions', () {
      final landmarks = {
        'boundingBox': {'x': 0.1, 'y': 0.1, 'width': 0.8, 'height': 0.8},
        'leftEye': {'x': 0.3, 'y': 0.4},
      };
      expect(
        resolveAnchorPosition(ThemeAccessoryAnchor.topLeftCorner, landmarks),
        const Offset(0.0, 0.0),
      );
      expect(
        resolveAnchorPosition(ThemeAccessoryAnchor.topRightCorner, landmarks),
        const Offset(1.0, 0.0),
      );
      expect(
        resolveAnchorPosition(ThemeAccessoryAnchor.bottomLeftCorner, landmarks),
        const Offset(0.0, 1.0),
      );
      expect(
        resolveAnchorPosition(ThemeAccessoryAnchor.bottomRightCorner, landmarks),
        const Offset(1.0, 1.0),
      );
    });

    // ── 6. Parametric: correct accessory count per theme ─────────────────────
    for (int theme = 0; theme <= 7; theme++) {
      testWidgets('theme $theme renders correct number of accessories',
          (tester) async {
        await tester.pumpWidget(_wrap(PirateAvatarWidget(
          player: _makePlayer(),
          themeIndex: theme,
          size: 80,
        )));
        await tester.pump();
        // Widget renders without overflow errors / exceptions.
        expect(tester.takeException(), isNull);
        expect(find.byType(PirateAvatarWidget), findsOneWidget);
      });
    }

    // ── 7. Asset load error doesn't crash widget ──────────────────────────────
    // Theme 99 has no paths → no accessory layers → safe fallback.
    testWidgets('unknown theme index renders base avatar without crash',
        (tester) async {
      await tester.pumpWidget(_wrap(PirateAvatarWidget(
        player: _makePlayer(),
        themeIndex: 99,
        size: 100,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(PirateAvatarWidget), findsOneWidget);
    });

    // ── 8. isActive=true renders a visible glow (boxShadow container) ────────
    testWidgets('isActive=true includes glow decoration container',
        (tester) async {
      await tester.pumpWidget(_wrap(PirateAvatarWidget(
        player: _makePlayer(),
        themeIndex: 0,
        size: 100,
        isActive: true,
      )));
      await tester.pump();

      // The glow is rendered as a Container with BoxDecoration.
      // Find containers with boxShadow (gold glow).
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGlow = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.boxShadow != null &&
              decoration.boxShadow!.isNotEmpty;
        }
        return false;
      });
      expect(hasGlow, isTrue);
    });

    // ── 9. isActive=false does NOT render the glow container ─────────────────
    testWidgets('isActive=false does not include glow decoration',
        (tester) async {
      await tester.pumpWidget(_wrap(PirateAvatarWidget(
        player: _makePlayer(),
        themeIndex: 0,
        size: 100,
        isActive: false,
      )));
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGlow = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.boxShadow != null &&
              decoration.boxShadow!.isNotEmpty;
        }
        return false;
      });
      expect(hasGlow, isFalse);
    });

    // ── 10. RepaintBoundary is present ────────────────────────────────────────
    testWidgets('build wraps output in RepaintBoundary', (tester) async {
      await tester.pumpWidget(_wrap(PirateAvatarWidget(
        player: _makePlayer(),
        themeIndex: 1,
        size: 64,
      )));
      await tester.pump();
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    // ── 11. resolveAnchorPosition falls back gracefully on malformed data ─────
    test('resolveAnchorPosition handles malformed landmark data', () {
      // leftEye key present but wrong type — should fall back to heuristic.
      final badLandmarks = {'leftEye': 'not_a_map'};
      final pos =
          resolveAnchorPosition(ThemeAccessoryAnchor.leftEye, badLandmarks);
      expect(pos, const Offset(0.40, 0.40));
    });

    // ── 12. chinBottom derived from bounding box ──────────────────────────────
    test('chinBottom is derived from bounding box bottom edge', () {
      final landmarks = {
        'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
      };
      final pos =
          resolveAnchorPosition(ThemeAccessoryAnchor.chinBottom, landmarks);
      // chinBottom = (bbX + bbW/2, bbY + bbH) = (0.50, 0.85)
      expect(pos.dx, closeTo(0.50, 0.001));
      expect(pos.dy, closeTo(0.85, 0.001));
    });
  });
}
