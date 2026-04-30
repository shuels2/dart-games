import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Add player with whitespace-only name is rejected',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.openAddPlayerDialog(
        tester, getAddPlayerButton(tester));

    await tester.enterText(ElementFinders.getAddPlayerNameField(), '   ');
    await PumpSequences.textEntry(tester);

    final addButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addButton);
    await PumpSequences.simpleUpdate(tester);

    // Dialog should still be open
    expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

    await SettingsHelpers.cancelAddPlayerDialog(tester);
  });
}
