import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: standard victory without double when Double Finish is OFF',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Target=100, DF OFF. Win by reaching or exceeding 100, no double needed
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    // Get to 80: Turn 1 = 60, Turn 2 = 20
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester);

    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester);

    // P1 at 80. Throw on dart 3: Miss + Miss + S20 = 100 → VICTORY (DF OFF)
    // Win evaluation fires at turn end (dart 3), not on individual dart.
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwDartViaMock(tester, 20); // S20 — DART 3, prospective 100 ≥ 100 = VICTORY
    await clickDartsRemoved(tester);

    await ResultsHelpers.pumpUntilResults(tester, config);

    // Should be on results screen
    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason:
            'Should navigate to results after standard win with DF OFF');
  });
}
