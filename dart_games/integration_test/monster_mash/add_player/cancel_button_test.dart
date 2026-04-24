import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Cancel button - Enter name, tap Cancel -> dialog closes, player NOT added', (WidgetTester tester) async {
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

    // Enter a name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, 'Cancelled Player');
    await PumpSequences.textEntry(tester);

    // Tap Cancel
    final cancelButton = ElementFinders.getAddPlayerCancelButton();
    await tester.tap(cancelButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    final dialog = ElementFinders.getAddPlayerDialog();
    expect(dialog, findsNothing);

    // Verify player was NOT added
    final player = ProviderHelpers.findPlayerByName(tester, 'Cancelled Player');
    expect(player, isNull);
  });
}
