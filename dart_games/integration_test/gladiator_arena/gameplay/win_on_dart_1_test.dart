import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: a winning total reached on dart 1 must end the
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
      'Gameplay: win on dart 1 — DF OFF, T20 with target=60 ends the game',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 60,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    // T20 = 60 → prospective 60 ≥ 60 → VICTORY on dart 1.
    await throwDartViaMock(tester, 20, multiplier: 'triple');

    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue,
        reason: 'Winning dart should end the game on dart 1');

    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-1 victory');
  });
}
