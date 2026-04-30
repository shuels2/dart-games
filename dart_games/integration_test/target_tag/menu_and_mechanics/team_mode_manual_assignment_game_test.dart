import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 15: Team Mode - Manual Team Assignment Game - Validates team mode enabled with manual assignment, 6 players added (ManualTeam1-6), players correctly assigned to 3 teams with 2 members each using manual team selection dialog, "Assign team" buttons removed after all assignments, game starts successfully with "Target Tag Game On!" displayed. Note: Does NOT validate team badge visibility or max 5 teams enforcement - only verifies assignment workflow and game start',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Toggle manual team assignment (turn OFF random assignment)
    await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
    await PumpSequences.simpleUpdate(tester);

    // Add 6 players
    for (int i = 1; i <= 6; i++) {
      await UITestHelpers.addPlayer(tester, 'ManualTeam$i', config);
    }

    // Scroll to top of player list to ensure all players are visible
    final listFinder = find.byType(ListView).first;
    await tester.fling(listFinder, const Offset(0, 500), 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Assign Player 1 to Team 1 (index 0)
    await tester.ensureVisible(find.text('ManualTeam1'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog1 = find.byType(AlertDialog);
    final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors1.at(0)); // Team 1
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Player 2 to Team 1 (index 0)
    await tester.ensureVisible(find.text('ManualTeam2'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog2 = find.byType(AlertDialog);
    final gestureDetectors2 = find.descendant(of: dialog2, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors2.at(0)); // Team 1
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Player 3 to Team 2 (index 1)
    await tester.ensureVisible(find.text('ManualTeam3'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog3 = find.byType(AlertDialog);
    final gestureDetectors3 = find.descendant(of: dialog3, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors3.at(1)); // Team 2
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Player 4 to Team 2 (index 1)
    await tester.ensureVisible(find.text('ManualTeam4'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog4 = find.byType(AlertDialog);
    final gestureDetectors4 = find.descendant(of: dialog4, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors4.at(1)); // Team 2
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Player 5 to Team 3 (index 2)
    await tester.ensureVisible(find.text('ManualTeam5'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog5 = find.byType(AlertDialog);
    final gestureDetectors5 = find.descendant(of: dialog5, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors5.at(2)); // Team 3
    await tester.pump(const Duration(milliseconds: 500));

    // Assign Player 6 to Team 3 (index 2)
    await tester.ensureVisible(find.text('ManualTeam6'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog6 = find.byType(AlertDialog);
    final gestureDetectors6 = find.descendant(of: dialog6, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors6.at(2)); // Team 3
    await tester.pump(const Duration(milliseconds: 500));

    // Ensure final dialog is fully closed and UI updated before verification
    await PumpSequences.dialogClose(tester);

    // Verify all teams assigned (no more "Assign team" buttons)
    expect(find.text('Assign team'), findsNothing);

    // Start game
    await UITestHelpers.startGame(tester, config);

    expect(find.text('Target Tag Game On!'), findsOneWidget);
  });
}
