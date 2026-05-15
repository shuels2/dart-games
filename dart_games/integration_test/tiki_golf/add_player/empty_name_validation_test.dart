// integration_test/tiki_golf/add_player/empty_name_validation_test.dart
//
// Test 4 — Try to save with empty name, assert error/validation prevents save.
//
// Section 12B File 1 — add_player Test 4
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Empty name shows validation error and dialog stays open',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_add_player_empty_name_validation',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Open Add Player dialog
        final addButton = ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
        expect(addButton, findsAtLeastNWidgets(1),
            reason: '[DIAG empty_name] Empty-state add button not found');
        await tester.ensureVisible(addButton.first);
        await tester.pump();
        await tester.tap(addButton.first);
        await PumpSequences.dialogOpen(tester);

        // Verify dialog opened
        expect(find.text('Player Name'), findsOneWidget,
            reason: '[DIAG empty_name] Dialog not open — Player Name field not found');

        // Try to tap Add Player with empty name
        final addPlayerButton = ElementFinders.getAddPlayerAddButton();
        await tester.tap(addPlayerButton.first);
        await PumpSequences.simpleUpdate(tester);

        // Verify error message
        expect(find.text('Please enter a player name'), findsOneWidget,
            reason: '[DIAG empty_name] Validation error message not shown');

        // Verify dialog remains open
        expect(find.text('Player Name'), findsOneWidget,
            reason: '[DIAG empty_name] Dialog closed unexpectedly after empty submit');

        // Enter valid name and verify error clears
        final nameField = ElementFinders.getAddPlayerNameField();
        await tester.enterText(nameField, 'Valid Player');
        await PumpSequences.textEntry(tester);

        expect(find.text('Please enter a player name'), findsNothing,
            reason: '[DIAG empty_name] Error message should clear after valid input');

        // Verify successful add
        await tester.tap(addPlayerButton.first);
        await PumpSequences.dialogClose(tester);

        expect(find.text('Valid Player'), findsOneWidget,
            reason: '[DIAG empty_name] Player not added after valid name entry');
      },
    );
  });
}
