// integration_test/tiki_golf/navigation/game_back_settings_persist_test.dart
//
// Test Nav-2 — Set Max Strokes=5 and Mulligan ON, add 2 players, TEE OFF,
//              then back-from-game (Save modal → Don't Save), assert menu
//              loads with Max Strokes still 5 and Mulligan still ON.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Game back with Don\'t Save returns to menu with settings preserved',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_navigation_game_back_settings_persist',
      () async {
        await UITestHelpers.resetServerState();

        // Set Max Strokes = 5, Mulligan = ON, add 2 players, start game
        await setupAndStartGame(
          tester,
          maxStrokes: 5,
          mulliganEnabled: true,
          playerNames: ['NavPlayer1', 'NavPlayer2'],
        );

        // Verify we are on the game screen
        final holeCounter = ElementFinders.getTikiGolfHoleCounter();
        expect(holeCounter, findsOneWidget,
            reason: '[DIAG game_back_persist] Game screen not loaded — hole counter not found');

        // Tap game screen back button (should show Save modal since darts thrown = 0
        // but game has started — or no modal since 0 darts thrown)
        await UITestHelpers.tapGameScreenBackButton(tester, config);

        // If save modal appeared, tap Don't Save
        final dontSaveButton = ElementFinders.getSaveGameModalDontSaveButton();
        if (dontSaveButton.evaluate().isNotEmpty) {
          await tester.tap(dontSaveButton);
          await PumpSequences.navigation(tester);
        }

        // Verify we're on the menu screen
        final startButton = ElementFinders.getTikiGolfStartButton();
        expect(startButton, findsOneWidget,
            reason: '[DIAG game_back_persist] TEE OFF button not found — menu screen did not load');

        // Verify Max Strokes = 5 is still shown
        expect(find.text('5'), findsWidgets,
            reason: '[DIAG game_back_persist] Max Strokes "5" not showing after back — settings not preserved');

        // Verify Mulligan switch is still ON
        final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
        expect(mulliganSwitch, findsOneWidget,
            reason: '[DIAG game_back_persist] Mulligan switch not found on menu');
        final switchWidget = tester.widget<Switch>(mulliganSwitch);
        expect(switchWidget.value, isTrue,
            reason: '[DIAG game_back_persist] Mulligan should be ON — settings not preserved');
        // Primarily verify the players are still present:
        expect(find.text('NavPlayer1'), findsWidgets,
            reason: '[DIAG game_back_persist] NavPlayer1 not found in menu after back');
        expect(find.text('NavPlayer2'), findsWidgets,
            reason: '[DIAG game_back_persist] NavPlayer2 not found in menu after back');
      },
    );
  });
}
