import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Add Player Empty Name Validation - Validates empty name field submission shows error message, dialog remains open after error, error message clears on valid input, successful player creation after correction', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Find and tap "NEW PLAYER" button (empty state since no players yet)
    final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1));
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog opened
    expect(find.text('Player Name'), findsOneWidget);

    // Leave name field empty and try to add player
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.simpleUpdate(tester);

    // Verify error message appears
    expect(find.text('Please enter a player name'), findsOneWidget);

    // Verify dialog remains open
    expect(find.text('Player Name'), findsOneWidget);

    // Enter valid name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Valid Player');
    await PumpSequences.textEntry(tester);

    // Verify error message disappears when typing
    expect(find.text('Please enter a player name'), findsNothing);

    // Tap "Add Player" button again
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify player was saved successfully
    expect(find.text('Valid Player'), findsOneWidget);

    // Verify dialog closed
    expect(find.text('Player Name'), findsNothing);
  });
}
