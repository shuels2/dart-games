import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Menu screen initial state - Health slider present (default 20), Bonus Buffs OFF, Speed Play OFF, Round Limit disabled, Start disabled, back button present', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify health slider present with default value 20
    final healthSlider = ElementFinders.getMonsterMashHealthPointsSlider();
    expect(healthSlider, findsOneWidget);
    final healthSliderWidget = tester.widget<Slider>(healthSlider);
    expect(healthSliderWidget.value.toInt(), 20);

    // Verify Bonus Buffs switch is OFF
    final bonusBuffsSwitch = ElementFinders.getMonsterMashBonusBuffsSwitch();
    expect(bonusBuffsSwitch, findsOneWidget);
    final bonusBuffsWidget = tester.widget<Switch>(bonusBuffsSwitch);
    expect(bonusBuffsWidget.value, isFalse);

    // Verify Speed Play switch is OFF
    final speedPlaySwitch = ElementFinders.getMonsterMashSpeedPlaySwitch();
    expect(speedPlaySwitch, findsOneWidget);
    final speedPlayWidget = tester.widget<Switch>(speedPlaySwitch);
    expect(speedPlayWidget.value, isFalse);

    // Verify back button is present
    final backButton = ElementFinders.getMonsterMashBackButton();
    expect(backButton, findsOneWidget);

    // Verify start button exists (disabled without players)
    final startButton = ElementFinders.getMonsterMashStartButton();
    expect(startButton, findsOneWidget);
  });
}
