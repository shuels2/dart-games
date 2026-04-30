import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Change Settings returns to menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    await UITestHelpers.clickChangeSettings(tester, config);

    // Should be back on menu with game options visible
    expect(ElementFinders.getReefRoyaleGameModeDropdown(), findsOneWidget);
  });
}
