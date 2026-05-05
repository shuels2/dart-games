import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Navigation: change settings preserves settings and players after victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Start with non-default settings: altitude=300, Hard Landing=ON
    await setupAndStartGame(
      tester,
      config,
      altitude: 300,
      hardLanding: true,
    );

    await completeGameToVictory(tester, hardLandingEnabled: true);
    await PumpSequences.fullRebuild(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Click Change Settings (CHANGE MISSION) on results screen
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify we're on the menu with settings preserved
    expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget);

    // Altitude should still be 300
    final sliderFinder = ElementFinders.getLunarLanderAltitudeSlider();
    expect(sliderFinder, findsOneWidget);
    final slider = tester.widget<Slider>(sliderFinder);
    expect(slider.value, 300.0,
        reason: 'Altitude should still be 300 after CHANGE MISSION');

    // Hard Landing should still be ON
    final switchFinder = ElementFinders.getLunarLanderHardLandingSwitch();
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isTrue,
        reason: 'Hard Landing should still be ON after CHANGE MISSION');

    // Players should still be present in selected list
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.length, 2);

    // Player names should be visible in UI
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  });
}
