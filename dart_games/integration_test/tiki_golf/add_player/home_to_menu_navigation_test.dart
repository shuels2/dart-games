// integration_test/tiki_golf/add_player/home_to_menu_navigation_test.dart
//
// Test 1 — Navigate from home to Tiki Golf menu, assert menu loaded.
//
// Section 12B File 1 — add_player Test 1
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home to Tiki Golf menu navigation loads menu screen',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_add_player_home_to_menu_navigation',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Verify Tiki Golf menu is loaded by checking for known menu elements
        final startButton = ElementFinders.getTikiGolfStartButton();
        expect(startButton, findsOneWidget,
            reason: '[DIAG home_to_menu] TEE OFF button not found on Tiki Golf menu');

        final maxStrokesDropdown = ElementFinders.getTikiGolfMaxStrokesDropdown();
        expect(maxStrokesDropdown, findsOneWidget,
            reason: '[DIAG home_to_menu] Max Strokes dropdown not found — menu did not load');

        final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
        expect(mulliganSwitch, findsOneWidget,
            reason: '[DIAG home_to_menu] Mulligan switch not found on Tiki Golf menu');
      },
    );
  });
}
