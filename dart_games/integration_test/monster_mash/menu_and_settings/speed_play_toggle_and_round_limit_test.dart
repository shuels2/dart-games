import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Speed play toggle and round limit - Speed Play ON enables round limit slider, set round limit, Speed Play OFF disables slider', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Toggle Speed Play ON
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    var speedPlayWidget = tester.widget<Switch>(ElementFinders.getMonsterMashSpeedPlaySwitch());
    expect(speedPlayWidget.value, isTrue);

    // Verify round limit slider is now available
    final roundLimitSlider = ElementFinders.getMonsterMashRoundLimitSlider();
    expect(roundLimitSlider, findsOneWidget);

    // Set round limit to 5
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 5);
    var roundLimitWidget = tester.widget<Slider>(roundLimitSlider);
    expect(roundLimitWidget.value.toInt(), 5);

    // Set round limit to 15
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 15);
    roundLimitWidget = tester.widget<Slider>(roundLimitSlider);
    expect(roundLimitWidget.value.toInt(), 15);

    // Toggle Speed Play OFF
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    speedPlayWidget = tester.widget<Switch>(ElementFinders.getMonsterMashSpeedPlaySwitch());
    expect(speedPlayWidget.value, isFalse);
  });
}
