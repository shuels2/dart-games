/// Unit tests for the `faceLandmarksHintMessage` pure helper — verifies
/// the sidecar error-reason strings map to the two friendly buckets
/// (retake photo vs. contact admin) that the Add / Edit Player dialogs
/// surface via `showFaceLandmarksHintIfAny`.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/widgets/face_landmarks_hint.dart';

void main() {
  group('faceLandmarksHintMessage — no-face-detected bucket', () {
    test('retake-photo hint when errorReason is no-face-detected', () {
      final msg = faceLandmarksHintMessage(
          'no-face-detected: MediaPipe ran successfully but did not '
          'find a face in the current photo.');
      expect(msg, contains("didn't find a clear face"));
      expect(msg, contains('front-facing photo'));
      expect(msg, contains('Re-detect'));
    });

    test('any reason string starting with no-face-detected still hits '
        'the retake bucket', () {
      final msg = faceLandmarksHintMessage('no-face-detected');
      expect(msg, contains("didn't find a clear face"));
    });
  });

  group('faceLandmarksHintMessage — infra-failure bucket', () {
    test('python-not-found → contact-admin hint', () {
      final msg = faceLandmarksHintMessage(
          'python-not-found: No Python 3 interpreter found on the '
          "service account's PATH.");
      expect(msg, contains('Face detection ran into a problem'));
      expect(msg, contains('Diagnose face'));
      expect(msg, contains('python-not-found'),
          reason: 'the short reason should appear parenthetically');
    });

    test('timeout → contact-admin hint', () {
      final msg = faceLandmarksHintMessage(
          'timeout: Python sidecar did not respond within 10s.');
      expect(msg, contains('Face detection ran into a problem'));
      expect(msg, contains('timeout'));
    });

    test('sidecar-exit-N → contact-admin hint', () {
      final msg =
          faceLandmarksHintMessage('sidecar-exit-1: Python sidecar exited …');
      expect(msg, contains('Face detection ran into a problem'));
    });

    test('unknown / novel reason still falls into contact-admin bucket', () {
      final msg = faceLandmarksHintMessage('sudden-solar-flare');
      expect(msg, contains('Face detection ran into a problem'));
      expect(msg, contains('sudden-solar-flare'));
    });

    test('very long reason string is truncated in the parenthetical', () {
      final huge = 'sidecar-error: ${'x' * 500}';
      final msg = faceLandmarksHintMessage(huge);
      // Should not blow past a sensible length.
      expect(msg.length, lessThan(500));
      // Truncation marker present.
      expect(msg, contains('…'));
    });

    test('multi-line reason is condensed to the first line in the hint',
        () {
      const reason = 'sidecar-exit-1: first line\nsecond line here';
      final msg = faceLandmarksHintMessage(reason);
      expect(msg, contains('first line'));
      expect(msg, isNot(contains('second line here')));
    });
  });
}
