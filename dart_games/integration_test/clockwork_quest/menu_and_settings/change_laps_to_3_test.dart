import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Change Number of Laps to 3',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.selectClockworkQuestLaps(tester, 3);

    final lapsDropdown = tester.widget<DropdownButton<int>>(
      ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
    );
    expect(lapsDropdown.value, 3);
  });
}
