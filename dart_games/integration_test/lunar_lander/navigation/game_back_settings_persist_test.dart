import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Navigation: game back button returns to menu with settings preserved',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Set non-default settings: altitude=300, Hard Landing=ON
    await setupAndStartGame(
      tester,
      config,
      altitude: 300,
      hardLanding: true,
    );

    // We're on the game screen — tap back (no darts thrown, so no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify we're on the menu with settings preserved
    expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget);

    // Altitude slider should still show 300
    final sliderFinder = ElementFinders.getLunarLanderAltitudeSlider();
    expect(sliderFinder, findsOneWidget);
    final slider = tester.widget<Slider>(sliderFinder);
    expect(slider.value, 300.0,
        reason: 'Altitude should still be 300 after back from game');

    // Hard Landing switch should still be ON
    final switchFinder = ElementFinders.getLunarLanderHardLandingSwitch();
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isTrue,
        reason: 'Hard Landing should still be ON after back from game');
  });
}
