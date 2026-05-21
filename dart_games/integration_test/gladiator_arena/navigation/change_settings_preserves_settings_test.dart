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
      'Navigation: leaving to home and re-entering resets settings to defaults',
      (WidgetTester tester) async {
    // Policy: when a user leaves a game (back to home) and re-enters from
    // the home screen, the menu rehydrates to defaults — only the
    // "Change Settings" button on the victory screen passes the prior
    // game's values through to the menu via the menu's `initialX` params.
    // This test exercises the home-roundtrip path and verifies the reset.
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Change settings away from defaults: target=300, Shield ON, Speed Play ON
    await SettingsHelpers.setGladiatorArenaTargetScore(tester, 300);
    await SettingsHelpers.toggleGladiatorArenaShieldRound(tester);
    await SettingsHelpers.toggleGladiatorArenaSpeedPlay(tester);

    // Navigate to home
    final backButton = ElementFinders.getGladiatorArenaBackButton();
    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    // Re-enter from home (this is the path that should reset)
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Verify settings reset to defaults (target=200, Shield OFF, Speed Play OFF)
    final sliderWidget = tester.widget<Slider>(
        ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(sliderWidget.value.toInt(), 200,
        reason: 'Target score should reset to default (200) after home roundtrip');

    final shieldSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaShieldRoundSwitch());
    expect(shieldSwitch.value, isFalse,
        reason: 'Shield Round should reset to default (OFF) after home roundtrip');

    final speedSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaSpeedPlaySwitch());
    expect(speedSwitch.value, isFalse,
        reason: 'Speed Play should reset to default (OFF) after home roundtrip');
  });
}
