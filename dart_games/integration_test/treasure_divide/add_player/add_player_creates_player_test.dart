// integration_test/treasure_divide/add_player/add_player_creates_player_test.dart
//
// Test AP-2 — Tap "NEW PLAYER" button, enter "Test Pirate Alpha", tap Save.
//             Assert dialog closes AND the new player tile appears in the
//             player panel.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add player with name "Test Pirate Alpha" appears in player list',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open add-player dialog (empty-state button visible on fresh reset)
    final addButton =
        ElementFinders.getTreasureDivideAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1),
        reason:
            '[DIAG td_ap_creates] Empty-state add-player button not found');
    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog opened
    expect(find.text('Add New Player'), findsOneWidget,
        reason:
            '[DIAG td_ap_creates] "Add New Player" dialog did not open');

    // Enter player name
    final nameField = ElementFinders.getAddPlayerNameField();
    expect(nameField, findsOneWidget,
        reason: '[DIAG td_ap_creates] Name text field not found');
    await tester.enterText(nameField, 'Test Pirate Alpha');
    await PumpSequences.textEntry(tester);

    // Tap the Add (Save) button
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    expect(addPlayerButton, findsOneWidget,
        reason: '[DIAG td_ap_creates] Add button not found in dialog');
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    expect(find.text('Add New Player'), findsNothing,
        reason: '[DIAG td_ap_creates] Dialog did not close after Add tap');

    // Verify the new player tile appears in the panel
    expect(find.text('Test Pirate Alpha'), findsOneWidget,
        reason:
            '[DIAG td_ap_creates] "Test Pirate Alpha" not found in player panel after add');

  });
}
