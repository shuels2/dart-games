// integration_test/tiki_golf/add_player/whitespace_name_validation_test.dart
//
// Test 5 — Try to save with all-whitespace name, assert validation prevents save.
//
// Section 12B File 1 — add_player Test 5
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Whitespace-only name shows validation error and dialog stays open',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open Add Player dialog
    final addButton = ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1),
        reason: '[DIAG whitespace_name] Empty-state add button not found');
    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Enter whitespace-only name
    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, '   ');
    await PumpSequences.textEntry(tester);

    // Try to add player
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.simpleUpdate(tester);

    // Verify error message
    expect(find.text('Please enter a player name'), findsOneWidget,
        reason: '[DIAG whitespace_name] Validation error not shown for whitespace-only name');

    // Verify dialog remains open
    expect(find.text('Player Name'), findsOneWidget,
        reason: '[DIAG whitespace_name] Dialog closed unexpectedly for whitespace-only name');
  });
}
