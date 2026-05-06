import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Pause Modal: disconnection on results screen blocks action buttons and dismisses on reconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Complete game to reach results screen
    await completeGameToVictory(tester);

    // Verify on results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Should be on results screen');

    // Simulate disconnection on results screen
    await simulateDisconnectAndVerify(tester);

    // Pause modal should be visible
    expect(find.text('Game Paused'), findsOneWidget,
        reason: 'Pause modal should appear on results screen on disconnect');

    // Verify results buttons still in tree
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Play again button should be in tree (blocked by pause modal)');

    // Simulate reconnect
    await simulateReconnectAndVerify(tester);

    // Results should be accessible again
    await PumpSequences.simpleUpdate(tester);
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results buttons should be accessible after reconnect');
  });
}
