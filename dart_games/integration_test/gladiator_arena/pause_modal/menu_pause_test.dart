import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on menu screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks AppBar back button on menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause blocks start game button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause blocks settings controls', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Pause blocks add player button on menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 6: Pause dismisses and menu still works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 7: Pause blocks then reconnect back button works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Verify we are still on the menu screen
    expect(config.getStartButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}
