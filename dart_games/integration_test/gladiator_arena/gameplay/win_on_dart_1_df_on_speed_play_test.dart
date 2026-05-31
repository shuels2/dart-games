import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

/// Coverage for win-on-dart-1 under the BOTH-OPTIONS-ON corner: Double
/// Finish ON AND Speed Play ON. Also verifies the Speed Play timer is
/// canceled the moment the winning dart commits — the screen's cancel
/// branch fires on `shouldPrompt = dartsThrown >= 3 || provider.hasWinner`,
/// so the win path takes the same line as the 3-dart takeout path, but the
/// trigger is different and worth a dedicated regression.
///
/// Setup: target=100 (menu minimum), DF ON, Speed Play ON. Turn 1 P1
/// reaches 60 via T20+Miss+Miss. P2 misses everything. Turn 2 dart 1: D20
/// (40) → 100 on a double → DF ON WIN on the FIRST dart of P1's second
/// turn.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: win on dart 1 — DF ON + Speed Play ON, D20 with score=60 wins '
      'and timer is canceled',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: true,
      speedPlayEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Turn 1: P1 reaches 60. T20+Miss+Miss commits to 60 under DF ON
    // (prospective 60 < target 100, no bust).
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // T20 = 60
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Turn 1: P2 misses everything.
    await completeTurnWithMisses(tester);

    // Turn 2 dart 1: D20 → prospective 100 on a double → DF ON WIN.
    await throwDartViaMock(tester, 20, multiplier: 'double');

    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason:
            'D20 on dart 1 of turn 2 should finish on a double and win '
            'immediately — must not wait until dart 3');

    // Verify timer cancellation: pump 2 s (well under the 3 s nav delay)
    // and confirm the timer display has not ticked down. If the Speed Play
    // timer leaked past the win, the displayed seconds would change.
    final timerJustAfterWin = tester
        .widget<Text>(ElementFinders.getGladiatorArenaTimerDisplay())
        .data;
    await tester.pump(const Duration(seconds: 2));
    final timerAfterPump = tester
        .widget<Text>(ElementFinders.getGladiatorArenaTimerDisplay())
        .data;
    expect(timerAfterPump, timerJustAfterWin,
        reason:
            'Speed Play timer must be canceled on win — displayed seconds '
            'must not tick down between dart-commit and Results navigation');

    // Drive navigation to Results — total post-win pump now ≈ 6 s, well
    // past the 3 s nav delay in `_handleGameWon`.
    await clickDartsRemoved(tester);
    await ResultsHelpers.pumpUntilResults(tester, config);

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 victory');
  });
}
