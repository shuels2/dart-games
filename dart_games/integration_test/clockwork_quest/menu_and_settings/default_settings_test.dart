import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Default settings are correct',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Include Bullseye should default to OFF
    final bullseyeSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
    );
    expect(bullseyeSwitch.value, isFalse);

    // Speed Mode should default to OFF
    final speedSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestSpeedModeCheckbox(),
    );
    expect(speedSwitch.value, isFalse);

    // Number of Laps should default to 1
    final lapsDropdown = tester.widget<DropdownButton<int>>(
      ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
    );
    expect(lapsDropdown.value, 1);
  });
}
