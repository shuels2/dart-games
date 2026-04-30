import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Whitespace-only name validation - Enter "   ", tap Add -> error, dialog stays open', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open add player dialog
    final emptyStateButton = ElementFinders.getMonsterMashAddPlayerButtonEmptyState();
    final normalStateButton = ElementFinders.getMonsterMashAddPlayerButton();

    Finder addButton;
    if (emptyStateButton.evaluate().isNotEmpty) {
      addButton = emptyStateButton;
    } else {
      addButton = normalStateButton;
    }

    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Enter whitespace-only name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, '   ');
    await PumpSequences.textEntry(tester);

    // Try to add
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.simpleUpdate(tester);

    // Verify dialog is still open (error state)
    final dialog = ElementFinders.getAddPlayerDialog();
    expect(dialog, findsOneWidget);

    // Verify error message
    expect(find.textContaining('Please enter a player name'), findsOneWidget);
  });
}
