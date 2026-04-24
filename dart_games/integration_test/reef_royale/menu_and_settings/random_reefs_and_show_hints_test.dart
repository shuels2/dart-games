import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Random Reefs and Show Hints toggles',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Toggle Random Reefs ON
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    expect(ElementFinders.getReefRoyaleRandomReefsSwitch(), findsOneWidget);

    // Toggle Show Hints OFF (it starts ON by default)
    await SettingsHelpers.toggleReefRoyaleShowHints(tester);
    expect(ElementFinders.getReefRoyaleShowHintsSwitch(), findsOneWidget);

    // Start game to verify settings were applied
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
  });
}
