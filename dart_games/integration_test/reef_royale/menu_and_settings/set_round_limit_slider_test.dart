import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Set Round Limit slider value',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable speed play first
    await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);

    // Set round limit to 8
    await SettingsHelpers.setReefRoyaleRoundLimit(tester, 8);
  });
}
