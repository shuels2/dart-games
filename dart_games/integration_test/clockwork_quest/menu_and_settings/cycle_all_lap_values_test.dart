import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Cycle through all lap values',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    for (final laps in [2, 3, 4, 5]) {
      await SettingsHelpers.selectClockworkQuestLaps(tester, laps);
      final lapsDropdown = tester.widget<DropdownButton<int>>(
        ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
      );
      expect(lapsDropdown.value, laps, reason: 'Laps should be $laps');
    }
  });
}
