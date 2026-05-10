import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: initial state shows correct defaults', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Target score slider should be at 200
    final slider = tester.widget<Slider>(
        ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(slider.value.toInt(), 200,
        reason: 'Default target score should be 200');

    // Target score value label should show 200
    expect(ElementFinders.getGladiatorArenaTargetScoreValue(), findsOneWidget);

    // Double Finish should be ON by default
    final dfSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaDoubleFinishSwitch());
    expect(dfSwitch.value, isTrue,
        reason: 'Double Finish should be ON by default');

    // Shield Round should be OFF by default
    final shieldSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaShieldRoundSwitch());
    expect(shieldSwitch.value, isFalse,
        reason: 'Shield Round should be OFF by default');

    // Speed Play should be OFF by default
    final speedSwitch = tester.widget<Switch>(
        ElementFinders.getGladiatorArenaSpeedPlaySwitch());
    expect(speedSwitch.value, isFalse,
        reason: 'Speed Play should be OFF by default');
  });
}
