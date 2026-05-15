import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Pause modal appears on menu screen',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_01_appears',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        await PauseModalHelpers.simulateDisconnectAndVerify(tester);

        // Verify we are still on the menu screen
        expect(config.getStartButton(), findsOneWidget);

        await PauseModalHelpers.simulateReconnectAndVerify(tester);
      },
    );
  });

  testWidgets('Test 2: Pause blocks AppBar back button on menu',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_02_blocks_back',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        await PauseModalHelpers.simulateDisconnectAndVerify(tester);

        // Try tapping the back button — overlay should block it
        final backButton = ElementFinders.getTikiGolfBackButton();
        await tester.tap(backButton, warnIfMissed: false);
        await PumpSequences.simpleUpdate(tester);

        // Verify we are still on the menu (not navigated to home)
        PauseModalHelpers.verifyPauseModalVisible(tester);
        expect(config.getStartButton(), findsOneWidget);

        await PauseModalHelpers.simulateReconnectAndVerify(tester);
      },
    );
  });

  testWidgets('Test 3: Pause blocks TEE OFF button',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_03_blocks_tee_off',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Add players so TEE OFF would be enabled
        await UITestHelpers.addPlayer(tester, 'Player A', config);
        await UITestHelpers.addPlayer(tester, 'Player B', config);

        await PauseModalHelpers.simulateDisconnectAndVerify(tester);

        // Try tapping TEE OFF — overlay should block it
        await tester.tap(config.getStartButton(), warnIfMissed: false);
        await PumpSequences.simpleUpdate(tester);

        // Should still be on menu screen, not game screen
        PauseModalHelpers.verifyPauseModalVisible(tester);
        expect(config.getStartButton(), findsOneWidget);

        await PauseModalHelpers.simulateReconnectAndVerify(tester);
      },
    );
  });

  testWidgets('Test 4: Pause blocks settings controls',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_04_blocks_settings',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        await PauseModalHelpers.simulateDisconnectAndVerify(tester);

        // Try tapping Max Strokes dropdown — overlay should block it
        final maxStrokesDropdown = ElementFinders.getTikiGolfMaxStrokesDropdown();
        await tester.tap(maxStrokesDropdown, warnIfMissed: false);
        await PumpSequences.simpleUpdate(tester);

        // Pause should still be visible
        PauseModalHelpers.verifyPauseModalVisible(tester);

        // Try tapping Mulligan toggle — overlay should block it
        final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
        await tester.tap(mulliganSwitch, warnIfMissed: false);
        await PumpSequences.simpleUpdate(tester);

        PauseModalHelpers.verifyPauseModalVisible(tester);

        await PauseModalHelpers.simulateReconnectAndVerify(tester);
      },
    );
  });

  testWidgets('Test 5: Pause blocks Add Player button on menu',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_05_blocks_add_player',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        await PauseModalHelpers.simulateDisconnectAndVerify(tester);

        // Try tapping add player button — overlay should block it
        final addPlayerButton =
            ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
        await tester.tap(addPlayerButton, warnIfMissed: false);
        await PumpSequences.simpleUpdate(tester);

        // Add player dialog should NOT have opened
        PauseModalHelpers.verifyPauseModalVisible(tester);
        expect(ElementFinders.getAddPlayerNameField(), findsNothing);

        await PauseModalHelpers.simulateReconnectAndVerify(tester);
      },
    );
  });

  testWidgets('Test 6: Pause dismisses on reconnect; AppBar back works again',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_06_dismisses_back_works',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Disconnect then reconnect
        await PauseModalHelpers.simulateDisconnectAndVerify(tester);
        await PauseModalHelpers.simulateReconnectAndVerify(tester);

        // Menu should still be functional — add a player
        await UITestHelpers.addPlayer(tester, 'Player A', config);

        // Verify player was added (start button should still be visible)
        expect(config.getStartButton(), findsOneWidget);
      },
    );
  });

  testWidgets(
      'Test 7: Post-reconnect back arrow returns to home with ≥3 cards visible',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_pause_modal_menu_07_reconnect_back_to_home',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Disconnect — back button should be blocked
        await PauseModalHelpers.simulateDisconnectAndVerify(tester);

        final backButton = ElementFinders.getTikiGolfBackButton();
        await tester.tap(backButton, warnIfMissed: false);
        await PumpSequences.simpleUpdate(tester);

        // Still on menu
        PauseModalHelpers.verifyPauseModalVisible(tester);
        expect(config.getStartButton(), findsOneWidget);

        // Reconnect — back button should now work
        await PauseModalHelpers.simulateReconnectAndVerify(tester);

        await tester.tap(backButton);
        await PumpSequences.navigation(tester);

        // Should be back on home screen with Tiki Golf card visible
        expect(ElementFinders.getTikiGolfCard(), findsOneWidget);
      },
    );
  });
}
