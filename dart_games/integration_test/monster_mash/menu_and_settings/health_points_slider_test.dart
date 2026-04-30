import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Health points slider - Set to 10, 30, 50, verify label updates', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set health to 10
    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    final slider10 = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
    expect(slider10.value.toInt(), 10);

    // Set health to 30
    await SettingsHelpers.setMonsterMashHealthMax(tester, 30);
    final slider30 = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
    expect(slider30.value.toInt(), 30);

    // Set health to 50
    await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
    final slider50 = tester.widget<Slider>(ElementFinders.getMonsterMashHealthPointsSlider());
    expect(slider50.value.toInt(), 50);
  });
}
