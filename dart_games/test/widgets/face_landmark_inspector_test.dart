/// Widget tests for the face-landmarks inspector modal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/models/player.dart';
import 'package:dart_games/widgets/face_landmark_inspector/face_landmark_inspector.dart';

Player _testPlayer({Map<String, dynamic>? landmarks}) {
  return Player(
    id: 'face-test-1',
    name: 'Alex',
    createdAt: DateTime.parse('2026-05-01T00:00:00.000Z'),
    gamesPlayed: 0,
    gamesWon: 0,
    photoPath: '/api/v1/players/face-test-1/photo',
    faceLandmarks: landmarks,
  );
}

const _knownLandmarks = {
  'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
  'leftEye': {'x': 0.38, 'y': 0.40},
  'rightEye': {'x': 0.62, 'y': 0.40},
  'noseTip': {'x': 0.50, 'y': 0.55},
  'mouthCenter': {'x': 0.50, 'y': 0.70},
};

void main() {
  Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('toggling a landmark hides its draggable dot', (tester) async {
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        player: _testPlayer(landmarks: _knownLandmarks),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (_) async {},
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('face-landmark-dot-leftEye')), findsOneWidget);

    // Toggle leftEye off.
    await tester.tap(find.byKey(const Key('face-landmark-toggle-leftEye')));
    await tester.pump();

    expect(find.byKey(const Key('face-landmark-dot-leftEye')), findsNothing,
        reason: 'dot should disappear when toggle is off');
    // Other dots remain.
    expect(find.byKey(const Key('face-landmark-dot-rightEye')), findsOneWidget);
  });

  testWidgets('dragging a dot updates the working landmark and enables Save',
      (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        player: _testPlayer(landmarks: _knownLandmarks),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (m) async {
          saved = m;
        },
      ),
    ));
    await tester.pump();

    // Save button is disabled while no edits have happened.
    final saveBtn =
        tester.widget<ElevatedButton>(find.byKey(const Key('face-landmark-save')));
    expect(saveBtn.onPressed, isNull, reason: 'Save disabled before edits');

    // Drag the noseTip dot by some distance.
    await tester.drag(
      find.byKey(const Key('face-landmark-dot-noseTip')),
      const Offset(40, -20),
    );
    await tester.pump();

    // Save is now enabled. Tap it.
    final saveBtnAfter =
        tester.widget<ElevatedButton>(find.byKey(const Key('face-landmark-save')));
    expect(saveBtnAfter.onPressed, isNotNull,
        reason: 'Save should enable once landmarks are modified');

    await tester.tap(find.byKey(const Key('face-landmark-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull, reason: 'onSave callback should fire');
    final nose = saved!['noseTip'] as Map;
    // x should have increased, y should have decreased from the originals.
    expect((nose['x'] as num) > 0.50, isTrue);
    expect((nose['y'] as num) < 0.55, isTrue);
    // Untouched landmarks survive.
    expect(saved!['leftEye'], _knownLandmarks['leftEye']);
  });

  testWidgets('Reset to original reverts in-flight edits', (tester) async {
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        player: _testPlayer(landmarks: _knownLandmarks),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (_) async {},
      ),
    ));
    await tester.pump();

    // Drag → edits become dirty.
    await tester.drag(
      find.byKey(const Key('face-landmark-dot-mouthCenter')),
      const Offset(20, 30),
    );
    await tester.pump();

    final saveBtnAfterDrag =
        tester.widget<ElevatedButton>(find.byKey(const Key('face-landmark-save')));
    expect(saveBtnAfterDrag.onPressed, isNotNull);

    // Tap "Reset to original" (use the key — the button is inside a
    // scrollable sidebar that may scroll it offscreen in test viewports).
    final resetFinder = find.byKey(const Key('face-landmark-reset'));
    await tester.scrollUntilVisible(resetFinder, 100);
    await tester.tap(resetFinder);
    await tester.pump();

    // Save is disabled again because working == original.
    final saveBtnAfterReset =
        tester.widget<ElevatedButton>(find.byKey(const Key('face-landmark-save')));
    expect(saveBtnAfterReset.onPressed, isNull,
        reason: 'Reset should clear the dirty flag');
  });

  // ── head-top / chin-bottom independence ────────────────────────────────────

  testWidgets(
      'legacy landmarks map (no headTop/chinBottom) gets seeded from the '
      'bounding-box heuristic on load — dots appear draggable',
      (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        // _knownLandmarks has NO headTop / chinBottom — legacy shape.
        player: _testPlayer(landmarks: _knownLandmarks),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (m) async {
          saved = m;
        },
      ),
    ));
    await tester.pump();

    // Both derived dots are now real draggable dots.
    expect(find.byKey(const Key('face-landmark-dot-headTop')), findsOneWidget,
        reason: 'headTop should render as a draggable dot');
    expect(find.byKey(const Key('face-landmark-dot-chinBottom')), findsOneWidget,
        reason: 'chinBottom should render as a draggable dot');

    // Drag headTop, save, confirm the map now carries an override.
    await tester.drag(
      find.byKey(const Key('face-landmark-dot-headTop')),
      const Offset(30, -10),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('face-landmark-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull);
    expect(saved!['headTop'], isA<Map>(),
        reason: 'save must persist the headTop override');
    expect(saved!['chinBottom'], isA<Map>(),
        reason: 'chinBottom was seeded on load and should also persist');
  });

  testWidgets(
      'resizing the bounding box (dragging a corner handle) does NOT move '
      'headTop or chinBottom', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        player: _testPlayer(landmarks: _knownLandmarks),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (m) async {
          saved = m;
        },
      ),
    ));
    await tester.pump();

    // Drag the bottom-right corner outward → bbox width and height grow.
    await tester.drag(
      find.byKey(const Key('face-landmark-bbox-bottomRight')),
      const Offset(30, 30),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('face-landmark-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull);
    // Bounding box grew.
    final savedBb = saved!['boundingBox'] as Map;
    final originalWidth =
        ((_knownLandmarks['boundingBox'] as Map)['width'] as num).toDouble();
    final savedWidth = (savedBb['width'] as num).toDouble();
    expect(savedWidth, greaterThan(originalWidth),
        reason: 'dragging the bottom-right corner outward must grow the box');
    // headTop and chinBottom kept their seeded (bbox-derived-at-load-time)
    // positions — resizing must NOT drag them. Original headTop.y was
    // seeded as bbY - 0.15*bbH = 0.15 - 0.105 = 0.045.
    final savedHead = saved!['headTop'] as Map;
    final savedChin = saved!['chinBottom'] as Map;
    expect((savedHead['y'] as num).toDouble(), closeTo(0.045, 0.005),
        reason: 'resize must not translate headTop');
    // Chin was seeded at bbY + bbH = 0.15 + 0.70 = 0.85.
    expect((savedChin['y'] as num).toDouble(), closeTo(0.85, 0.005),
        reason: 'resize must not translate chinBottom');
  });

  testWidgets(
      'translating the bounding box (dragging its interior) group-moves '
      'headTop and chinBottom by the same delta', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        player: _testPlayer(landmarks: _knownLandmarks),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (m) async {
          saved = m;
        },
      ),
    ));
    await tester.pump();

    // Snapshot the seeded head/chin y-values before we drag.
    // Seeded on load: headTop.y = 0.045, chinBottom.y = 0.85.
    const expectedHeadYBeforeDrag = 0.045;
    const expectedChinYBeforeDrag = 0.85;

    // Drag the bbox interior. The handler in _translateBoundingBoxTo
    // moves the box AND applies the same delta to head / chin.
    await tester.drag(
      find.byKey(const Key('face-landmark-bbox-translate')),
      const Offset(0, 30), // move box down
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('face-landmark-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull);
    final savedBb = saved!['boundingBox'] as Map;
    final savedHead = saved!['headTop'] as Map;
    final savedChin = saved!['chinBottom'] as Map;

    // Bounding box top edge moved DOWN. Compute how much.
    final bbYNow = (savedBb['y'] as num).toDouble();
    final bbYBefore =
        ((_knownLandmarks['boundingBox'] as Map)['y'] as num).toDouble();
    final bbDeltaY = bbYNow - bbYBefore;
    expect(bbDeltaY, greaterThan(0),
        reason: 'the bounding box must have translated down');

    // headTop and chinBottom must have moved by the SAME delta.
    final headYNow = (savedHead['y'] as num).toDouble();
    final chinYNow = (savedChin['y'] as num).toDouble();
    expect(headYNow, closeTo(expectedHeadYBeforeDrag + bbDeltaY, 0.005),
        reason: 'headTop must translate by the same delta as the box');
    expect(chinYNow, closeTo(expectedChinYBeforeDrag + bbDeltaY, 0.005),
        reason: 'chinBottom must translate by the same delta as the box');
  });

  testWidgets('seeds defaults when player has no stored landmarks',
      (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(_wrap(
      FaceLandmarkInspector(
        player: _testPlayer(landmarks: null),
        photoUrl: 'http://localhost/placeholder.png',
        onSave: (m) async {
          saved = m;
        },
      ),
    ));
    await tester.pump();

    // Even though the player had no landmarks, the inspector seeds defaults so
    // the user has something draggable. Verify a marker is rendered.
    expect(find.byKey(const Key('face-landmark-dot-leftEye')), findsOneWidget);

    // Drag any dot far enough to clear the pan-slop threshold, then save
    // and confirm the seeded full landmark map flows through onSave.
    await tester.drag(
      find.byKey(const Key('face-landmark-dot-leftEye')),
      const Offset(40, 30),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('face-landmark-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull);
    expect(saved!.containsKey('boundingBox'), isTrue);
    expect(saved!.containsKey('mouthCenter'), isTrue);
  });
}
