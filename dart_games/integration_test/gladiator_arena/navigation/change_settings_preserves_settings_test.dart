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

  testWidgets(
      'Navigation: settings are preserved after navigating away and back',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Change settings: target=300, Shield ON, Speed Play ON
    await SettingsHelpers.setGladiatorArenaTargetScore(tester, 300);
    await SettingsHelpers.toggleGladiatorArenaShieldRound(tester);
    await SettingsHelpers.toggleGladiatorArenaSpeedPlay(tester);

    // Navigate to home and back
    final backButton = ElementFinders.getGladiatorArenaBackButton();
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Back to menu
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Verify settings preserved
    final sliderWidget = tester.widget<Slider>(
        ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(sliderWidget.value.toInt(), 300,
        reason: 'Target score should still be 300');

    final shieldSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaShieldRoundSwitch());
    expect(shieldSwitch.value, isTrue,
        reason: 'Shield Round should still be ON');

    final speedSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaSpeedPlaySwitch());
    expect(speedSwitch.value, isTrue,
        reason: 'Speed Play should still be ON');
  });
}
