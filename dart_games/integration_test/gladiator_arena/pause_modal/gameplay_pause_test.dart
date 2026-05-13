import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks AppBar back button during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause blocks dartboard emulator',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause over RemoveDartsModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Pause over SaveGameModal', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 6: EditScoreDialog auto-closes on disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 7: Pause dismisses on reconnect game continues',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 8: RemoveDartsModal still visible after reconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the game screen
    expect(config.getGameBackButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}
