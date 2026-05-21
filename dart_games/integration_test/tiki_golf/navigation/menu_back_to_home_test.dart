// integration_test/tiki_golf/navigation/menu_back_to_home_test.dart
//
// Test Nav-1 — From Tiki Golf menu, tap back arrow, assert home screen
//              with ≥3 game cards visible.
//
// Per skill §15: inline [DIAG ...] reasons on navigation-dependent assertions.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu back button returns to home screen with game cards',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Tap the Tiki Golf menu back button
    final backButton = ElementFinders.getTikiGolfBackButton();
    expect(backButton, findsOneWidget,
        reason: '[DIAG menu_back_home] Tiki Golf back button not found on menu screen');
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Verify we're on the home screen by checking for ≥3 game cards
    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
        reason: '[DIAG menu_back_home] Carnival Derby card not found after back navigation — not on home screen');
    expect(ElementFinders.getTargetTagCard(), findsOneWidget,
        reason: '[DIAG menu_back_home] Target Tag card not found after back navigation — not on home screen');
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
        reason: '[DIAG menu_back_home] Monster Mash card not found after back navigation — not on home screen');
  });
}
