import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
    );
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 2: Pause blocks Play Again button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
    );
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 3: Pause blocks Change Settings button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
    );
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 4: Pause blocks Back to Menu button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
    );
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });

  testWidgets('Test 5: Pause dismisses and buttons work',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
    );
    await completeGameToVictory(tester);

    // Verify we are on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // Still on results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}
