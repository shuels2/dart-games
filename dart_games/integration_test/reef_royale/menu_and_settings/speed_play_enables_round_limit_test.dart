import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Speed Play enables Round Limit slider',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Toggle speed play ON
    await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

    // Round limit slider should now be visible
    expect(ElementFinders.getReefRoyaleRoundLimitSlider(), findsOneWidget);
  });
}
