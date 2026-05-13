import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: Speed Play toggle changes state', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Initially OFF
    var sw = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaSpeedPlaySwitch());
    expect(sw.value, isFalse, reason: 'Speed Play OFF by default');

    // Toggle ON
    await SettingsHelpers.toggleGladiatorArenaSpeedPlay(tester);
    sw = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaSpeedPlaySwitch());
    expect(sw.value, isTrue, reason: 'Speed Play should be ON after toggle');

    // Toggle back OFF
    await SettingsHelpers.toggleGladiatorArenaSpeedPlay(tester);
    sw = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaSpeedPlaySwitch());
    expect(sw.value, isFalse, reason: 'Speed Play should be OFF again');
  });
}
