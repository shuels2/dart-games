// integration_test/tiki_golf/navigation/change_settings_preserves_settings_test.dart
//
// Test Nav-4 — Set Mulligan ON + Max Strokes 5, add 2 players, complete game,
//              on results tap CHANGE SETTINGS, assert menu loads with the same
//              settings preserved (Max Strokes 5, Mulligan ON, both players still selected).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Change Settings preserves Max Strokes and Mulligan and players after victory',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Set up game with specific settings: Max Strokes=5, Mulligan=ON
    await setupAndStartGame(
      tester,
      maxStrokes: 5,
      mulliganEnabled: true,
      playerNames: ['SettingsP1', 'SettingsP2'],
    );

    // Complete the game to reach results screen
    await playGameToCompletion(tester);

    // Verify results screen is showing
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: '[DIAG cs_preserves] Play Again button not found — results screen not loaded');

    // Tap Change Settings
    await UITestHelpers.clickChangeSettings(tester, config);

    // Verify menu is loaded
    final startButton = ElementFinders.getTikiGolfStartButton();
    expect(startButton, findsOneWidget,
        reason: '[DIAG cs_preserves] TEE OFF button not found — menu did not load after Change Settings');

    // Verify Max Strokes = 5 is preserved
    expect(find.text('5'), findsWidgets,
        reason: '[DIAG cs_preserves] Max Strokes "5" not showing — settings not preserved after Change Settings');

    // Verify Mulligan switch is still ON
    final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
    expect(mulliganSwitch, findsOneWidget,
        reason: '[DIAG cs_preserves] Mulligan switch not found after Change Settings');
    final switchWidget = tester.widget<Switch>(mulliganSwitch);
    expect(switchWidget.value, isTrue,
        reason: '[DIAG cs_preserves] Mulligan should be ON — settings not preserved');

    // Verify both players are still in the list
    expect(find.text('SettingsP1'), findsWidgets,
        reason: '[DIAG cs_preserves] SettingsP1 not found after Change Settings');
    expect(find.text('SettingsP2'), findsWidgets,
        reason: '[DIAG cs_preserves] SettingsP2 not found after Change Settings');
  });
}
