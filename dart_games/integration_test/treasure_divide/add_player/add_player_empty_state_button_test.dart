// integration_test/treasure_divide/add_player/add_player_empty_state_button_test.dart
//
// Test AP-3 — After resetServerState (zero players), assert the empty-state
//             "NEW PLAYER" button (TreasureDivideMenuKeys.addPlayerButtonEmptyState)
//             is visible. Tap it. Verify the AddPlayerDialog opens.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Empty-state add-player button is visible and opens dialog',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // On fresh reset there are zero players — the empty-state button should
    // be visible (keyed TreasureDivideMenuKeys.addPlayerButtonEmptyState).
    final emptyStateBtn =
        ElementFinders.getTreasureDivideAddPlayerButtonEmptyState();
    expect(emptyStateBtn, findsAtLeastNWidgets(1),
        reason:
            '[DIAG td_ap_empty_state] Empty-state add-player button not found on fresh reset');

    // Tap the empty-state button
    await tester.ensureVisible(emptyStateBtn.first);
    await tester.pump();
    await tester.tap(emptyStateBtn.first);
    await PumpSequences.dialogOpen(tester);

    // Verify AddPlayerDialog opened
    expect(find.text('Add New Player'), findsOneWidget,
        reason:
            '[DIAG td_ap_empty_state] "Add New Player" dialog did not open after tapping empty-state button');

    // Verify name field present
    final nameField = ElementFinders.getAddPlayerNameField();
    expect(nameField, findsOneWidget,
        reason:
            '[DIAG td_ap_empty_state] Name text field not found in dialog');

    // Close via Cancel
    final cancelButton = ElementFinders.getAddPlayerCancelButton();
    expect(cancelButton, findsOneWidget,
        reason:
            '[DIAG td_ap_empty_state] Cancel button not found in dialog');
    await tester.tap(cancelButton);
    await PumpSequences.dialogClose(tester);

    expect(find.text('Add New Player'), findsNothing,
        reason:
            '[DIAG td_ap_empty_state] Dialog did not close after Cancel tap');

  });
}
