import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Menu screen shows all settings controls',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify all 3 settings controls are visible
    expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
        findsOneWidget);
    expect(
        ElementFinders.getClockworkQuestSpeedModeCheckbox(), findsOneWidget);
    expect(ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
        findsOneWidget);

    // Start button should be visible
    expect(config.getStartButton(), findsOneWidget);

    // Player list should be visible
    expect(find.byKey(ClockworkQuestMenuKeys.playerListView), findsOneWidget);
  });
}
