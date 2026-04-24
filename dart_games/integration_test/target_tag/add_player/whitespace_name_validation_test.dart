import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Add Player Whitespace-Only Name Validation - Validates whitespace-only input (spaces/tabs) is rejected as invalid, error message displays for whitespace input, dialog remains open after whitespace validation error', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Find and tap "NEW PLAYER" button (empty state since no players yet)
    final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1));
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Enter only whitespace in name field
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, '   ');
    await PumpSequences.textEntry(tester);

    // Try to add player
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.simpleUpdate(tester);

    // Verify error message appears
    expect(find.text('Please enter a player name'), findsOneWidget);

    // Verify dialog remains open
    expect(find.text('Player Name'), findsOneWidget);
  });
}
