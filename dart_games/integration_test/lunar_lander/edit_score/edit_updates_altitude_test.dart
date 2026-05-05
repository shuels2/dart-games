import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: editing multiple darts correctly recalculates altitude',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, playerNames: ['Player A', 'Player B']);

    final playerId = ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;
    final startingAlt = ProviderHelpers.getLunarLanderStartingAltitude(tester);

    // Throw 3 darts so the RemoveDartsModal appears: 5, 3, miss.
    // (The Edit Score button lives inside the modal, which only renders after
    // the turn ends per spec §10B.)
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 3);
    await throwMissViaMock(tester);

    // Expected altitude: startingAlt - 5 - 3 - 0 = startingAlt - 8
    expect(ProviderHelpers.getLunarLanderAltitude(tester, playerId), startingAlt - 8);

    // Edit: change dart 1 to double 10 and dart 2 to double 10
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'D10');
    await EditScoreHelpers.setDart2(tester, 'D10');
    await updateScore(tester);

    // Expected altitude: startingAlt - 20 - 20 - 0 = startingAlt - 40
    expect(ProviderHelpers.getLunarLanderAltitude(tester, playerId), startingAlt - 40);
  });
}
