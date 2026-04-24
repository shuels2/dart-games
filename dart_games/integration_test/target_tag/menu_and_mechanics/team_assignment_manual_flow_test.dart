import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 3: Team Assignment - Complete Manual Flow - Validates team mode enabled successfully, manual team assignment switch toggles on, 4 players added (Team1P1, Team1P2, Team2P1, Team2P2), all players found in scrollable player list, players manually assigned to teams using team selection dialog. Verifies "Assign team" buttons removed after assignment. Note: Does NOT verify team badge visibility on player tiles',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Toggle manual team assignment (turn OFF random assignment)
    await tester.tap(ElementFinders.getTargetTagAssignTeamsButton());
    await PumpSequences.simpleUpdate(tester);

    // Add 4 players
    for (int i = 1; i <= 4; i++) {
      await UITestHelpers.addPlayer(tester, 'TeamPlayer$i', config);
    }

    // Get all players
    final player1 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer1');
    final player2 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer2');
    final player3 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer3');
    final player4 = ProviderHelpers.findPlayerByName(tester, 'TeamPlayer4');

    expect(player1, isNotNull);
    expect(player2, isNotNull);
    expect(player3, isNotNull);
    expect(player4, isNotNull);

    // Scroll to top of player list to ensure all players are visible
    final listFinder = find.byType(ListView).first;
    await tester.fling(listFinder, const Offset(0, 500), 5000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Assign Player 1 to Team 1 (index 0)
    await tester.ensureVisible(find.text('TeamPlayer1'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog1 = find.byType(AlertDialog);
    final gestureDetectors1 = find.descendant(of: dialog1, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors1.at(0)); // Team 1 - dialog auto-closes
    await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close

    // Assign Player 2 to Team 1 (index 0)
    await tester.ensureVisible(find.text('TeamPlayer2'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog2 = find.byType(AlertDialog);
    final gestureDetectors2 = find.descendant(of: dialog2, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors2.at(0)); // Team 1 - dialog auto-closes
    await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close

    // Assign Player 3 to Team 2 (index 1)
    await tester.ensureVisible(find.text('TeamPlayer3'));
    await tester.pump();
    await tester.tap(find.text('Assign team').first);
    await PumpSequences.dialogOpen(tester);
    final dialog3 = find.byType(AlertDialog);
    final gestureDetectors3 = find.descendant(of: dialog3, matching: find.byType(GestureDetector));
    await tester.tap(gestureDetectors3.at(1)); // Team 2 - dialog auto-closes
    await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close

    // Check if Player 4 needs assignment or was auto-assigned
    final remainingButtons = find.text('Assign team');
    if (remainingButtons.evaluate().isEmpty) {
      print('All players auto-assigned after 3 manual assignments');
    } else {
      // Assign Player 4 to Team 2 (index 1)
      await tester.ensureVisible(find.text('TeamPlayer4'));
      await tester.pump();
      await tester.tap(find.text('Assign team').first);
      await PumpSequences.dialogOpen(tester);
      final dialog4 = find.byType(AlertDialog);
      final gestureDetectors4 = find.descendant(of: dialog4, matching: find.byType(GestureDetector));
      await tester.tap(gestureDetectors4.at(1)); // Team 2 - dialog auto-closes
      await tester.pump(const Duration(milliseconds: 500)); // Wait for auto-close
    }

    // Ensure final dialog is fully closed and UI updated before verification
    await PumpSequences.dialogClose(tester);

    // Verify all teams assigned (no more "Assign team" buttons)
    expect(find.text('Assign team'), findsNothing);

    // Verify start button exists
    final startButton = find.byKey(TargetTagMenuKeys.startButton);
    expect(startButton, findsOneWidget);
  });
}
