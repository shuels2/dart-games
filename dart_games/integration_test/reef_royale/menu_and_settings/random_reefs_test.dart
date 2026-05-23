// Random Reefs menu toggle smoke test.
//
// Renamed/trimmed from the original `random_reefs_and_show_hints_test`
// once the Show Hints toggle was removed from the menu. The Include
// Bull toggle (added in the same change) is covered by its own
// dedicated UI test `include_bull_test.dart` and does not need to be
// duplicated here.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Random Reefs toggle starts a game cleanly',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Toggle Random Reefs ON
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    expect(ElementFinders.getReefRoyaleRandomReefsSwitch(), findsOneWidget);

    // Start game to verify the setting was accepted by the menu.
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    expect(ProviderHelpers.isReefRoyaleGameActive(tester), isTrue);
  });
}
