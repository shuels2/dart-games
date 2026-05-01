import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu back button returns to home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    final backButton = ElementFinders.getReefRoyaleBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget);
    expect(ElementFinders.getTargetTagCard(), findsOneWidget);
    expect(ElementFinders.getMonsterMashCard(), findsOneWidget);
  });
}
