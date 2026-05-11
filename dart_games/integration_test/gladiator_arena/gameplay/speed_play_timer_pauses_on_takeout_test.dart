import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

/// Gap-coverage test (cross-game audit). The game screen calls
/// `_speedPlayTimer?.cancel()` once `shouldPromptTakeout` becomes true. If
/// that cancellation regressed, the timer would keep ticking down after a
/// turn ended and the visible seconds-remaining pill would change while the
/// player is busy removing darts. This regression test pumps time after
/// dart 3 and asserts the displayed seconds-remaining stays put.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: Speed Play timer is paused (cancelled) once turn ends and '
      'takeout prompt is showing',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      speedPlayEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Throw 3 darts → turn ends, shouldPromptTakeout=true, timer cancelled.
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    // Capture the timer display text NOW (immediately after dart 3).
    final timerBefore = tester.widget<Text>(
        ElementFinders.getGladiatorArenaTimerDisplay());
    final secondsBefore = timerBefore.data;

    // Advance time well past the timer's natural tick interval.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    // Re-read the timer display. It must NOT have ticked down — the cancel
    // ran when shouldPromptTakeout fired.
    final timerAfter = tester.widget<Text>(
        ElementFinders.getGladiatorArenaTimerDisplay());
    expect(timerAfter.data, secondsBefore,
        reason:
            'Speed Play timer must be cancelled while takeout prompt is up — '
            'displayed seconds should not change');
  });
}
