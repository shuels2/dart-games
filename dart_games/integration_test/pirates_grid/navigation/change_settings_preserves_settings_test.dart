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
      'Navigation: after game with Bo3+Steal, NEW VOYAGE preserves settings on menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Start game with non-default settings: Bo3 + Steal ON
    await setupAndStartGame(tester, config,
        bestOf: '3',
        stealMode: true,
        playerNames: ['Player A', 'Player B']);

    // Complete game to results
    await completeGameToVictory(tester);

    UITestHelpers.dumpRoute(tester, 'after-completeGameToVictory');

    // Click NEW VOYAGE → menu
    await tester.tap(config.getChangeSettingsButton());
    await PumpSequences.navigation(tester);

    UITestHelpers.dumpRoute(tester, 'after-NEW-VOYAGE-tap');

    // Verify on menu
    expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget,
        reason: 'Should be on menu after NEW VOYAGE');

    // Settings should still be: Bo3
    expect(find.text('3'), findsWidgets,
        reason: 'Best Of should still be 3 after NEW VOYAGE');

    // Steal Mode should still be ON
    final stealSwitch = ElementFinders.getPiratesGridStealModeSwitch();
    expect(stealSwitch, findsOneWidget);
    final stealWidget = tester.widget<Switch>(stealSwitch);
    expect(stealWidget.value, isTrue,
        reason: 'Steal Mode should still be ON after NEW VOYAGE');
  });
}
