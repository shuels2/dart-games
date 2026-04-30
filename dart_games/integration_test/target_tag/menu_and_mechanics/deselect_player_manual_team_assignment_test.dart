import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 16: Deselect Player During Manual Team Assignment - Validates team mode with manual assignment enabled, 2 players added and auto-selected, player assigned to Team 1, clicking team icon opens dialog, Remove from Team button removes assignment, player shows Assign team button again after removal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Toggle manual team assignment (turn OFF random assignment)
    await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
    await PumpSequences.simpleUpdate(tester);

    // Add 2 players (keep small to avoid scrolling)
    for (int i = 1; i <= 2; i++) {
      await UITestHelpers.addPlayer(tester, 'Deselect$i', config);
    }

    // Assign first player to Team 1
    final player1 = ProviderHelpers.findPlayerByName(tester, 'Deselect1');
    expect(player1, isNotNull);

    // Click "Assign team" button to open dialog
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);

    // Select Team 1
    final dialog1 = find.byType(AlertDialog);
    final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors1.at(0)); // Team 1
    await tester.pump(const Duration(milliseconds: 500));
    await PumpSequences.dialogClose(tester);

    // Verify player 1 assigned (no more "Assign team" button for them, only player 2)
    expect(find.text('Assign team'), findsOneWidget); // Only player 2 has button

    // Verify player 1 shows team icon (no "Assign team" button)
    final player1TileArea = find.ancestor(
      of: find.text('Deselect1'),
      matching: find.byType(Container),
    );
    expect(player1TileArea, findsWidgets);

    // Click the team icon to open the team selection dialog again
    final teamIcon = find.descendant(
      of: find.ancestor(
        of: find.text('Deselect1'),
        matching: find.byType(GestureDetector),
      ),
      matching: find.byType(Image),
    ).first;
    await tester.tap(teamIcon);
    await PumpSequences.dialogOpen(tester);

    // Verify "Remove from Team" button exists
    expect(find.text('Remove from Team'), findsOneWidget);

    // Click "Remove from Team" button
    await tester.tap(find.text('Remove from Team'));
    await PumpSequences.dialogClose(tester);

    // Verify player 1 no longer has team assignment (shows "Assign team" button again)
    expect(find.text('Assign team'), findsNWidgets(2)); // Both players now have button
  });
}
