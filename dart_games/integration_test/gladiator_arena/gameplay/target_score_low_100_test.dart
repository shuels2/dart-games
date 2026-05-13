import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: target score 100 — game ends at 100',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false, // simpler win condition
      playerNames: ['Player A', 'Player B'],
    );

    expect(ProviderHelpers.getGladiatorArenaTargetScore(tester), 100);

    // Win: S20 x 5 turns = 100
    await completeGameToVictory(tester);

    expect(ElementFinders.getGladiatorArenaPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should show after winning at target=100');
  });
}
