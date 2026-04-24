import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Back to Menu returns to home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    await UITestHelpers.clickBackToMenu(tester, config);

    // Should be back on home screen
    expect(ElementFinders.getReefRoyaleCard(), findsOneWidget);
  });
}
