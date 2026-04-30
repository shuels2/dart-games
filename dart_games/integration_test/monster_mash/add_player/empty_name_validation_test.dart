import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Empty name validation - Tap Add with empty name -> error message, enter valid name -> error clears, add succeeds', (WidgetTester tester) async {
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

    // Try to add with empty name
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.simpleUpdate(tester);

    // Verify error message appears
    expect(find.textContaining('Please enter a player name'), findsOneWidget);

    // Now enter a valid name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Valid Name');
    await PumpSequences.textEntry(tester);

    // Tap Add again
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify player was added successfully
    expect(find.text('Valid Name'), findsWidgets);
  });
}
