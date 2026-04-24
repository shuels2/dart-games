import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Bonus buffs toggle - Toggle ON/OFF, verify switch state changes', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify initially OFF
    var bonusBuffsWidget = tester.widget<Switch>(ElementFinders.getMonsterMashBonusBuffsSwitch());
    expect(bonusBuffsWidget.value, isFalse);

    // Toggle ON
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
    bonusBuffsWidget = tester.widget<Switch>(ElementFinders.getMonsterMashBonusBuffsSwitch());
    expect(bonusBuffsWidget.value, isTrue);

    // Toggle OFF
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
    bonusBuffsWidget = tester.widget<Switch>(ElementFinders.getMonsterMashBonusBuffsSwitch());
    expect(bonusBuffsWidget.value, isFalse);
  });
}
