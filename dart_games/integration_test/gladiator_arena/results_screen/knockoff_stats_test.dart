import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: knockoff stats section visible when knockoffs occurred',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Large target so we can get a knockoff before winning
    await setupAndStartGame(
      tester,
      config,
      targetScore: 500,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // P1 gets to 60: S20 x 3
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // P2 scores 60 to knockoff P1
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    // P1 should be at 0 now (knocked off)
    expect(
        ProviderHelpers.getGladiatorArenaPlayerScore(tester, p1Id), 0);

    // Play to completion (DF OFF)
    await completeGameToVictory(tester, numOpponents: 1);

    // Results screen should show knockoff stats
    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget);
    // Knockoff stats appear only if knockoffs occurred
    expect(ElementFinders.getGladiatorArenaKnockoffStats(), findsOneWidget,
        reason: 'Knockoff stats should be visible when knockoffs occurred');
  });
}
