import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

/// Coverage for win-on-dart-2 with Speed Play ON. Companion to
/// `win_on_dart_2_test` (DF ON only) — this variant adds Speed Play and
/// verifies (a) the win still triggers on dart 2 (not waiting for dart 3
/// or for the timer to expire), and (b) the Speed Play timer is canceled
/// the moment the winning dart commits.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: win on dart 2 — DF ON + Speed Play ON, T20 + D20 with '
      'target=100 wins and timer is canceled',
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

    // Dart 1: T20 → 60/100, no win yet.
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isFalse);

    // Dart 2: D20 → prospective 100 exact on a double → DF ON WIN.
    await throwDartViaMock(tester, 20, multiplier: 'double');
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason:
            'D20 on dart 2 should finish on a double and win immediately, '
            'not wait until dart 3 or until the Speed Play timer expires');

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
        reason: 'Should navigate to results after dart-2 victory');
  });
}
