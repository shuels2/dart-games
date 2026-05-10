import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: target score slider updates displayed value',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Default is 200
    final slider = tester.widget<Slider>(
        ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(slider.value.toInt(), 200);

    // Change to 350
    await SettingsHelpers.setGladiatorArenaTargetScore(tester, 350);
    await PumpSequences.simpleUpdate(tester);

    final updatedSlider = tester.widget<Slider>(
        ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(updatedSlider.value.toInt(), 350,
        reason: 'Slider should update to 350');

    // Change to 100
    await SettingsHelpers.setGladiatorArenaTargetScore(tester, 100);
    await PumpSequences.simpleUpdate(tester);

    final lowSlider = tester.widget<Slider>(
        ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(lowSlider.value.toInt(), 100,
        reason: 'Slider should update to 100');
  });
}
