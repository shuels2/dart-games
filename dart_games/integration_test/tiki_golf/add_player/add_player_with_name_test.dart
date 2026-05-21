// integration_test/tiki_golf/add_player/add_player_with_name_test.dart
//
// Test 2 — Add a player with name "Alice", verify it appears in the player list.
//
// Section 12B File 1 — add_player Test 2
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add player with name Alice appears in player list',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open the Add Player dialog from the empty state button
    final addButton = ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
    expect(addButton, findsAtLeastNWidgets(1),
        reason: '[DIAG add_player_with_name] Empty-state add button not found');
    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    // Verify the dialog opened
    expect(find.text('Player Name'), findsOneWidget,
        reason: '[DIAG add_player_with_name] Player Name label not found in dialog');

    // Enter player name
    final nameField = ElementFinders.getAddPlayerNameField();
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Alice');
    await PumpSequences.textEntry(tester);

    // Tap Add Player button
    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    expect(find.text('Player Name'), findsNothing,
        reason: '[DIAG add_player_with_name] Dialog did not close');

    // Verify Alice appears in the player list
    expect(find.text('Alice'), findsOneWidget,
        reason: '[DIAG add_player_with_name] Player "Alice" not found in list after add');
  });
}
