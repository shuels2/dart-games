import 'package:flutter/material.dart' show Switch;
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

    // Set non-default settings: Bo3 + Steal ON
    await setupAndStartGame(
      tester,
      config,
      bestOf: '3',
      stealMode: true,
    );

    // Tap back from game screen (no darts thrown — no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify we're on the menu
    expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget,
        reason: 'Should be back on menu after tapping game back button');

    // Best Of should still show 3
    expect(find.text('3'), findsWidgets,
        reason: 'Best Of should still be 3 after back from game');

    // Steal Mode should still be ON
    final stealSwitch = ElementFinders.getPiratesGridStealModeSwitch();
    expect(stealSwitch, findsOneWidget);
    final stealWidget = tester.widget<Switch>(stealSwitch);
    expect(stealWidget.value, isTrue,
        reason: 'Steal Mode should still be ON after back from game');
  });
}
