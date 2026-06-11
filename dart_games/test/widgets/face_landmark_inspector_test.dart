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
