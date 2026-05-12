import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: a winning total reached on dart 2 must end the
/// game IMMEDIATELY — the player must NOT have to keep throwing to dart 3
/// for the win to register. Regression guard for the per-dart-eval pattern
/// shared with Lunar Lander, Carnival Derby, etc.
///
/// Split from win_on_early_dart_test.dart so each test file holds exactly one
/// `testWidgets` — the parallel runner serializes per file and the prior
/// two-tests-per-file form produced flaky "Multiple exceptions" failures.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: win on dart 2 — DF ON, S20 + D20 with target=60 ends the game',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Double Finish ON: last dart must be a double. S20 (20) then D20 (40)
    // = 60 exact, last dart a double → VICTORY on dart 2.
    await setupAndStartGame(
      tester,
      config,
      targetScore: 60,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    await throwDartViaMock(tester, 20); // S20 → 20/60, no win yet
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isFalse);

    await throwDartViaMock(tester, 20, multiplier: 'double'); // D20 → 60 on a double
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason: 'D20 on dart 2 should finish on a double and win');

    // Intercept FlutterError.onError during the post-win pump so we can
    // capture errors before they aggregate into the "Multiple exceptions (N)"
    // wrapper (which the parallel runner's log shows without per-error
    // detail). Replacing the handler suppresses the original errors; our
    // own `fail()` at the end is the SOLE error reported, so its message
    // makes it through unmangled.
    final captured = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      captured.add(details);
    };

    try {
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();
    } finally {
      FlutterError.onError = originalOnError;
    }

    // Also drain any TestFailures (e.g. from expect() calls inside callbacks)
    final taken = <Object>[];
    for (int i = 0; i < 5; i++) {
      final e = tester.takeException();
      if (e == null) break;
      taken.add(e);
    }

    if (captured.isNotEmpty || taken.isNotEmpty) {
      final flutterErrs = captured
          .map((d) => 'EXC: ${d.exception} | LIB: ${d.library}')
          .join(' || ');
      fail(
        '[DIAG win_on_dart_2] post-win pump caught '
        '${captured.length} FlutterError(s) + ${taken.length} other(s). '
        'FlutterErrors: $flutterErrs. Others: $taken',
      );
    }

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-2 victory');
  });
}
