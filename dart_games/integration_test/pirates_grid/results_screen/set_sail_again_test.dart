import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Results: SET SAIL AGAIN restarts game with same settings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    await completeGameToVictory(tester);

    // Verify on results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should be on results screen');

    // Tap SET SAIL AGAIN
    await clickPlayAgain(tester);

    // Should restart — game screen visible with a fresh game
    expect(ElementFinders.getPiratesGridSkipTurnButton(), findsOneWidget,
        reason: 'Game screen should restart after SET SAIL AGAIN');
  });
}
