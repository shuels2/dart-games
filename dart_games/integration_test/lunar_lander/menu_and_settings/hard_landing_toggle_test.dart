import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: hard landing toggle changes switch state',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    final switchFinder = ElementFinders.getLunarLanderHardLandingSwitch();
    expect(switchFinder, findsOneWidget);

    // Default should be OFF
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Toggle ON
    await setHardLanding(tester, enabled: true);

    final switchAfter = tester.widget<Switch>(switchFinder);
    expect(switchAfter.value, isTrue);
  });
}
