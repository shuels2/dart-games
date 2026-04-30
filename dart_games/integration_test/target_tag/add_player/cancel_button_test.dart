import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Cancel Button Functionality - Validates cancel button closes dialog without saving player data, entered player name is not added to player list, dialog properly closes and returns to menu screen', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Find and tap "NEW PLAYER" button (empty state since no players yet)
    final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1));
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Enter a player name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Cancelled Player');
    await PumpSequences.textEntry(tester);

    // Tap Cancel button
    final cancelButton = ElementFinders.getAddPlayerCancelButton();
    expect(cancelButton, findsOneWidget);
    await tester.tap(cancelButton);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    expect(find.text('Player Name'), findsNothing);

    // Verify player was NOT added (should not appear in list)
    expect(find.text('Cancelled Player'), findsNothing);
  });
}
