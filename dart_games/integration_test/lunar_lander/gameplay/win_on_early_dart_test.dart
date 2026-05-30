import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

/// Per-dart win evaluation: a touchdown reached on dart 1 or dart 2 must
/// end the game IMMEDIATELY — the player must NOT have to keep throwing to
/// dart 3 for the win to register. Regression guard for the per-dart-eval
/// pattern shared across every game.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: touchdown on dart 2 ends the game (Hard Landing OFF, alt=100)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // Min altitude (100) keeps the test short. With Hard Landing OFF an
    // overshoot is treated as a touchdown, so:
    //   T20 (60) → alt 40, no win yet
    //   T20 (60) → alt -20, Hard Landing OFF → TOUCHDOWN on dart 2
    await setupAndStartGame(tester, config,
        altitude: 100, playerNames: ['Player A', 'Player B']);

    await throwDartViaMock(tester, 20, multiplier: 'triple');
    expect(hasWinner(tester), isFalse,
        reason: 'No win on dart 1 — altitude is still 40');

    await throwDartViaMock(tester, 20, multiplier: 'triple');
    expect(hasWinner(tester), isTrue,
        reason:
            'Overshoot on dart 2 with Hard Landing OFF should win immediately');

    await clickDartsRemoved(tester);
    await ResultsHelpers.pumpUntilResults(tester, config);

    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results after dart-2 touchdown');
  });
}
