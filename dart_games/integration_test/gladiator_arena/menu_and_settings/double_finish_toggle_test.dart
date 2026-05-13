import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: Double Finish toggle changes state', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Initially ON
    var sw = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaDoubleFinishSwitch());
    expect(sw.value, isTrue, reason: 'Double Finish ON by default');

    // Toggle OFF
    await SettingsHelpers.toggleGladiatorArenaDoubleFinish(tester);
    sw = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaDoubleFinishSwitch());
    expect(sw.value, isFalse, reason: 'Double Finish should be OFF after toggle');

    // Toggle back ON
    await SettingsHelpers.toggleGladiatorArenaDoubleFinish(tester);
    sw = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaDoubleFinishSwitch());
    expect(sw.value, isTrue, reason: 'Double Finish should be ON again');
  });
}
