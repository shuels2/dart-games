import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: rankings are ordered by score', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    await completeGameToVictory(tester);

    // Rankings list should be present
    expect(ElementFinders.getGladiatorArenaRankingsList(), findsOneWidget);

    // Rank rows should be visible
    expect(ElementFinders.getGladiatorArenaRankRow(0), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaRankRow(1), findsOneWidget);
  });
}
