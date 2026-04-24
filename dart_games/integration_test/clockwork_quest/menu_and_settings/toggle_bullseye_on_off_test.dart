import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Toggle Include Bullseye ON then OFF',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Toggle ON
    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
    var bullseyeSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
    );
    expect(bullseyeSwitch.value, isTrue);

    // Toggle OFF
    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
    bullseyeSwitch = tester.widget<Switch>(
      ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
    );
    expect(bullseyeSwitch.value, isFalse);
  });
}
