import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: winning on a double triggers victory (Double Finish ON)',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Target=100, DF ON. Get to 80 then finish with D10 = 20 → 100 DOUBLE VICTORY
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: true,
      playerNames: ['Player A', 'Player B'],
    );

    // Get P1 to 80: Turn 1 = 60 (S20*3), Turn 2 = 20 (S20)
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

    // P1 at 80. Finish on dart 3 with D10 (must be LAST dart for DF ON victory):
    //   Miss + Miss + D10 → prospective 80+0+0+20=100, last dart D10=double → VICTORY
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwDartViaMock(tester, 10, multiplier: 'double'); // D10 = 20 — DART 3, double
    await clickDartsRemoved(tester);

    // Wait for results navigation
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Should be on results screen
    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Should navigate to results screen after double finish win');
  });
}
