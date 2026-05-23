import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Menu screen shows all 8 game options',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify game mode dropdown exists
    expect(ElementFinders.getReefRoyaleGameModeDropdown(), findsOneWidget);

    // Verify toggle switches exist. Include Bull replaced Show Hints
    // in the menu (the Show Hints toggle was removed; hints are now
    // always on for new games).
    expect(ElementFinders.getReefRoyaleEasyClaimSwitch(), findsOneWidget);
    expect(ElementFinders.getReefRoyaleNeighborNumbersSwitch(), findsOneWidget);
    expect(ElementFinders.getReefRoyaleRandomReefsSwitch(), findsOneWidget);
    expect(ElementFinders.getReefRoyaleBonusBuffsSwitch(), findsOneWidget);
    expect(ElementFinders.getReefRoyaleIncludeBullSwitch(), findsOneWidget);
    expect(ElementFinders.getReefRoyaleSpeedPlaySwitch(), findsOneWidget);
  });
}
