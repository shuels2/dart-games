// integration_test/tiki_golf/add_player/cancel_closes_without_adding_test.dart
//
// Test 6 — Open Add Player, cancel, assert player count unchanged.
//
// Section 12B File 1 — add_player Test 6
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cancel closes Add Player dialog without adding player',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open Add Player dialog
    final addButton = ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1),
        reason: '[DIAG cancel_closes] Empty-state add button not found');
    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Enter a player name (to verify it is NOT added after cancel)
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Cancelled Player');
    await PumpSequences.textEntry(tester);

    // Tap Cancel button
    final cancelButton = ElementFinders.getAddPlayerCancelButton();
    expect(cancelButton, findsOneWidget,
        reason: '[DIAG cancel_closes] Cancel button not found in dialog');
    await tester.tap(cancelButton);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed (Player Name field gone)
    expect(find.text('Player Name'), findsNothing,
        reason: '[DIAG cancel_closes] Dialog did not close after Cancel tap');

    // Verify player was NOT added
    expect(find.text('Cancelled Player'), findsNothing,
        reason: '[DIAG cancel_closes] Cancelled player should NOT appear in list');
  });
}
