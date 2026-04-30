import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Add Player with Name Only - Validates new player dialog opening, name field entry, player creation without photo, dialog closure, player appears in list. Note: Does NOT explicitly verify auto-selection status (checkmark visible) - only confirms player exists in list and player card renders', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Find and tap "NEW PLAYER" button (empty state since no players yet)
    final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1));
    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog opened with expected elements
    expect(find.text('Player Name'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);
    expect(find.text('GALLERY'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add Player'), findsWidgets); // Multiple instances (title + button)

    // Enter player name
    final nameField = ElementFinders.getAddPlayerNameField();
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Test Player');
    await PumpSequences.textEntry(tester);

    // Tap "Add Player" button in the dialog
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed (Player Name field should not be visible)
    expect(find.text('Player Name'), findsNothing);

    // Verify player appears in the player list with checkmark (selected)
    expect(find.text('Test Player'), findsOneWidget);

    // The player card should show a checkmark indicating selection
    final playerCard = find.text('Test Player');
    expect(playerCard, findsOneWidget);
  });
}
