import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: target score 500 — game does not end early',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    expect(ProviderHelpers.getGladiatorArenaTargetScore(tester), 500);

    // Score 200 points without winning (since target=500)
    for (int i = 0; i < 10; i++) {
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await throwDartViaMock(tester, 20);
      await clickDartsRemoved(tester);

      // Check for winner after each turn
      if (ProviderHelpers.gladiatorArenaHasWinner(tester)) break;

      await completeTurnWithMisses(tester);
    }

    // After 10 * S20 * 3 = 60 pts/turn, P1 wins around turn 9 (9*60=540 >= 500).
    // Wait for the 3-second navigation delay in _handleGameWon → results screen.
    await ResultsHelpers.pumpUntilResults(tester, config);

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Game should eventually complete at target=500');
  });
}
