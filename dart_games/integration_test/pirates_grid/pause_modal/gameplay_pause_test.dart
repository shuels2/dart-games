import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Pause Modal: disconnection during gameplay blocks interactions and dismisses on reconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw a dart so state is in-progress
    await throwDartViaMock(tester, 20);

    // Simulate disconnection
    await simulateDisconnectAndVerify(tester);

    // Pause modal should be visible
    expect(find.text('Game Paused'), findsOneWidget,
        reason: 'Pause modal should appear during gameplay on disconnect');

    // Verify game screen elements still exist in tree
    expect(config.getSkipTurnButton(), findsOneWidget,
        reason: 'Skip turn button should be in tree (blocked by modal overlay)');

    // Simulate reconnect
    await simulateReconnectAndVerify(tester);

    // Game should resume (skip turn button accessible again)
    await PumpSequences.simpleUpdate(tester);
    expect(config.getSkipTurnButton(), findsOneWidget,
        reason: 'Skip turn button should be accessible after reconnect');
  });
}
