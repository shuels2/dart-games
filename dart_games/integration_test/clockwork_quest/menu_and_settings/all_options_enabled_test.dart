import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Enable all options (Bullseye + Speed + 5 Laps)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
    await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
    await SettingsHelpers.selectClockworkQuestLaps(tester, 5);

    final bullseyeSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
    );
    final speedSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestSpeedModeCheckbox(),
    );
    final lapsDropdown = tester.widget<DropdownButton<int>>(
      ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
    );
    expect(bullseyeSwitch.value, isTrue);
    expect(speedSwitch.value, isTrue);
    expect(lapsDropdown.value, 5);
  });
}
