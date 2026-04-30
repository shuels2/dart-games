import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Add player dialog has required UI elements',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.openAddPlayerDialog(
        tester, getAddPlayerButton(tester));

    // Dialog and name field should be visible
    expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);
    expect(ElementFinders.getAddPlayerNameField(), findsOneWidget);
    expect(ElementFinders.getAddPlayerAddButton(), findsOneWidget);
    expect(ElementFinders.getAddPlayerCancelButton(), findsOneWidget);

    await SettingsHelpers.cancelAddPlayerDialog(tester);
  });
}
