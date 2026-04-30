import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Toggle Speed Mode ON then OFF',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
    var speedSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestSpeedModeCheckbox(),
    );
    expect(speedSwitch.value, isTrue);

    await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
    speedSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestSpeedModeCheckbox(),
    );
    expect(speedSwitch.value, isFalse);
  });
}
