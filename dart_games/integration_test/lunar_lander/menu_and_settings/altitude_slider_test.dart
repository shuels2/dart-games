import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: altitude slider changes starting altitude value',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    final sliderFinder = ElementFinders.getLunarLanderAltitudeSlider();
    expect(sliderFinder, findsOneWidget);

    // Default should be 200
    final slider = tester.widget<Slider>(sliderFinder);
    expect(slider.value, 200.0);

    // Change to 300
    await setAltitude(tester, 300);

    final sliderAfter = tester.widget<Slider>(sliderFinder);
    expect(sliderAfter.value, 300.0);
  });
}
