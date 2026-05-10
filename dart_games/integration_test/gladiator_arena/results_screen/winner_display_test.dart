import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: winner display shows winner name and score',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    await completeGameToVictory(tester);

    // Results screen should be visible
    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget);
    expect(ElementFinders.getGladiatorArenaWinnerName(), findsOneWidget);

    // Winner should be identified
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isTrue);
  });
}
