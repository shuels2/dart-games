import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

/// Target Tag - Test 13 Debug
///
/// Isolated test for debugging Test 13: Game Start Validation - All Modes
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run test
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/test_13_debug.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper function to navigate to Target Tag menu
  Future<void> navigateToTargetTagMenu(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final targetTagCard = find.text('Target Tag');
    expect(targetTagCard, findsOneWidget);
    await tester.tap(targetTagCard);

    // Use pump() for screens with continuous animations
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Verify on Target Tag menu screen
    expect(find.textContaining('Shield Max:'), findsOneWidget);
  }

  // Helper function to add a player
  Future<void> addPlayer(WidgetTester tester, String name) async {
    final addButton = find.text('NEW PLAYER');
    await tester.ensureVisible(addButton.first);
    await tester.pump();
    await tester.tap(addButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final nameField = find.byType(TextField);
    await tester.enterText(nameField, name);
    await tester.pump();
    await tester.pump();

    final addPlayerButton = find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.text('Add Player'),
    );
    await tester.tap(addPlayerButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Helper function to start the game
  Future<void> startGame(WidgetTester tester) async {
    final playButton = find.text("LET'S PLAY TAG!");
    await tester.ensureVisible(playButton);
    await tester.pump();
    await tester.tap(playButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  // Helper function to enable Hero Bonus
  Future<void> enableHeroBonus(WidgetTester tester) async {
    // Find the 'Hero Bonus' text label
    final heroBonusLabel = find.text('Hero Bonus');

    if (heroBonusLabel.evaluate().isNotEmpty) {
      // Find the Container that contains the 'Hero Bonus' label
      final heroBonusContainer = find.ancestor(
        of: heroBonusLabel,
        matching: find.byType(Container),
      );

      // Find the Switch within that Container
      final heroBonusSwitch = find.descendant(
        of: heroBonusContainer,
        matching: find.byType(Switch),
      );

      if (heroBonusSwitch.evaluate().isNotEmpty) {
        // Check if the switch is already ON
        final switchWidget = tester.widget<Switch>(heroBonusSwitch.first);
        if (!switchWidget.value) {
          // Only tap if it's currently OFF
          await tester.tap(heroBonusSwitch.first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
        }
      }
    }
  }

  // Helper function to enable Team mode
  Future<void> enableTeamMode(WidgetTester tester) async {
    // Find the 'Team mode' text label
    final teamModeLabel = find.text('Team mode');

    if (teamModeLabel.evaluate().isNotEmpty) {
      // Find the Container that contains the 'Team mode' label
      final teamModeContainer = find.ancestor(
        of: teamModeLabel,
        matching: find.byType(Container),
      );

      // Find the Switch within that Container
      final teamModeSwitch = find.descendant(
        of: teamModeContainer,
        matching: find.byType(Switch),
      );

      if (teamModeSwitch.evaluate().isNotEmpty) {
        await tester.tap(teamModeSwitch.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }
    }
  }

  // Helper function to enable Manual team assignment
  Future<void> enableManualTeamAssignment(WidgetTester tester) async {
    // Find the 'Assign teams' text label
    final assignTeamsLabel = find.text('Assign teams');

    if (assignTeamsLabel.evaluate().isNotEmpty) {
      // Find the Container that contains the 'Assign teams' label
      final assignTeamsContainer = find.ancestor(
        of: assignTeamsLabel,
        matching: find.byType(Container),
      );

      // Find the Switch within that Container
      final assignTeamsSwitch = find.descendant(
        of: assignTeamsContainer,
        matching: find.byType(Switch),
      );

      if (assignTeamsSwitch.evaluate().isNotEmpty) {
        await tester.tap(assignTeamsSwitch.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }
    }
  }

  // Helper function to deselect all selected players by checking their Container styling
  Future<void> deselectAllPlayers(WidgetTester tester) async {
    // Find the ListView
    final listViewFinder = find.descendant(
      of: find.byType(Container),
      matching: find.byType(ListView),
    );

    if (listViewFinder.evaluate().isEmpty) {
      return;
    }

    final listView = listViewFinder.first;

    // Scroll to top first
    for (int i = 0; i < 10; i++) {
      await tester.drag(listView, const Offset(0, 300)); // Drag down to scroll to top
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    var deselectedCount = 0;
    var maxAttempts = 20; // Safety limit

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Find all currently visible InkWell widgets
      final inkWells = find.descendant(
        of: listView,
        matching: find.byType(InkWell),
      );

      bool foundSelected = false;

      // Check each visible InkWell
      for (int i = 0; i < inkWells.evaluate().length; i++) {
        final inkWell = inkWells.at(i);

        // Find the Container ancestor
        final containerAncestor = find.ancestor(
          of: inkWell,
          matching: find.byType(Container),
        );

        if (containerAncestor.evaluate().isNotEmpty) {
          final container = tester.widget<Container>(containerAncestor.first);
          final decoration = container.decoration as BoxDecoration?;

          if (decoration != null && decoration.border != null) {
            final border = decoration.border as Border;
            final borderColor = border.top.color.value;

            // Check if border color is green (0xFF00FFA3) - selected state
            if (borderColor == 0xFF00FFA3) {
              foundSelected = true;

              // Tap to deselect
              await tester.tap(inkWell);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));
              await tester.pump();

              deselectedCount++;

              // Scroll up slightly to check next player
              await tester.drag(listView, const Offset(0, -50));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 200));
              await tester.pump();
              break; // Process one at a time
            }
          }
        }
      }

      if (!foundSelected) {
        // Try scrolling down to find more players
        await tester.drag(listView, const Offset(0, -150));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        // Check if we found any selected players after scrolling
        if (deselectedCount > 0 && !foundSelected) {
          // We've scrolled through without finding more, we're done
          break;
        }
      }
    }
  }

  // Helper function to scroll to find a widget
  Future<bool> scrollToFindWidget(WidgetTester tester, Finder widgetFinder) async {
    // First check if it's already visible
    if (widgetFinder.evaluate().isNotEmpty) {
      return true;
    }

    // Find the ListView container (300px container holding the player list)
    final listViewFinder = find.descendant(
      of: find.byType(Container),
      matching: find.byType(ListView),
    );

    if (listViewFinder.evaluate().isEmpty) {
      return false; // No ListView found
    }

    final listView = listViewFinder.first;

    // Try scrolling down (drag up with negative Y) to look for items below current position
    for (int i = 0; i < 3; i++) {
      await tester.drag(listView, const Offset(0, -150)); // Scroll down 150px
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      if (widgetFinder.evaluate().isNotEmpty) {
        return true; // Found it!
      }
    }

    // If not found below, try scrolling up (drag down with positive Y) to look for items above
    for (int i = 0; i < 6; i++) {
      await tester.drag(listView, const Offset(0, 150)); // Scroll up 150px
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      if (widgetFinder.evaluate().isNotEmpty) {
        return true; // Found it!
      }
    }

    // Try scrolling down again in case we went too far up
    for (int i = 0; i < 3; i++) {
      await tester.drag(listView, const Offset(0, -150)); // Scroll down 150px
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      if (widgetFinder.evaluate().isNotEmpty) {
        return true; // Found it!
      }
    }

    return false; // Widget not found after all scroll attempts
  }

  group('Target Tag - Test 13 Debug', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'dartboard_name': 'Test Dartboard',
        'dartboard_serial': 'TEST-001',
        'use_emulator': true,
      });
    });

    testWidgets('Test 13: Game Start Validation - All Modes', (WidgetTester tester) async {
      // ===== Step 1: Standard Solo Mode - 2 Players =====
      await navigateToTargetTagMenu(tester);

      // Add 2 players
      await addPlayer(tester, 'Game Player 1');
      await addPlayer(tester, 'Game Player 2');

      // Start game
      await startGame(tester);

      // Verify game started successfully
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.text('Game Player 1'), findsWidgets); // Player names appear in multiple places
      expect(find.text('Game Player 2'), findsWidgets);

      // ===== Step 2: Three Player Solo Mode =====
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Add 3 players
      await addPlayer(tester, 'Player Alpha');
      await addPlayer(tester, 'Player Beta');
      await addPlayer(tester, 'Player Gamma');

      // Start game
      await startGame(tester);

      // Verify 3-player game started
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.text('Player Alpha'), findsOneWidget);
      expect(find.text('Player Beta'), findsOneWidget);
      expect(find.text('Player Gamma'), findsOneWidget);

      // ===== Step 3: Solo Mode with Hero Bonus =====
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Enable Hero Bonus
      await enableHeroBonus(tester);

      // Add 3 players
      await addPlayer(tester, 'Settings Player 1');
      await addPlayer(tester, 'Settings Player 2');
      await addPlayer(tester, 'Settings Player 3');

      // Pump to ensure UI updates
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify players added
      expect(find.text('Settings Player 1'), findsOneWidget);

      // Start game to verify settings persist
      await startGame(tester);

      // Verify game started with hero bonus
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.textContaining('ON'), findsWidgets); // Hero Bonus ON in settings panel
      expect(find.textContaining('Buff:'), findsWidgets); // Buff appears on game screen

      // ===== Step 4: Team Mode with Random Assignment =====
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Enable Team mode
      await enableTeamMode(tester);

      // Add 4 players for 2v2
      await addPlayer(tester, 'Team1 Winner1');
      await addPlayer(tester, 'Team1 Winner2');
      await addPlayer(tester, 'Team2 Loser1');
      await addPlayer(tester, 'Team2 Loser2');

      // Start the game
      await startGame(tester);

      // Verify game started in team mode
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.textContaining('Team'), findsWidgets);

      // ===== Step 5: Return to test another Team Mode variation =====
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Add 4 different players for team mode
      await addPlayer(tester, 'Team A Player 1');
      await addPlayer(tester, 'Team A Player 2');
      await addPlayer(tester, 'Team B Player 1');
      await addPlayer(tester, 'Team B Player 2');

      // Start game
      await startGame(tester);

      // Verify team game started
      expect(find.text('Target Tag Game On!'), findsOneWidget);
      expect(find.textContaining('Team'), findsWidgets);

      // ===== Step 6: Team Mode Manual Assignment Setup =====
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Team mode should still be enabled
      // Switch to Manual team assignment
      await enableManualTeamAssignment(tester);

      // Enable Hero Bonus
      await enableHeroBonus(tester);

      // Pump frames to let UI update after mode switches
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Deselect all currently selected players from previous steps
      // This uses Container styling to identify selected tiles (works in all modes)
      await deselectAllPlayers(tester);

      // Pump to ensure UI updates after deselecting
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Add 4 players (they will be auto-selected by default)
      await addPlayer(tester, 'Team Settings 1');
      await addPlayer(tester, 'Team Settings 2');
      await addPlayer(tester, 'Team Settings 3');
      await addPlayer(tester, 'Team Settings 4');

      // Pump to ensure UI updates
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Assign players to teams by finding each player by name
      // Team 1: Team Settings 1, Team Settings 2
      // Team 2: Team Settings 3, Team Settings 4

      final playerTeamAssignments = [
        {'player': 'Team Settings 1', 'teamIndex': 0}, // Team 1
        {'player': 'Team Settings 2', 'teamIndex': 0}, // Team 1
        {'player': 'Team Settings 3', 'teamIndex': 1}, // Team 2
        {'player': 'Team Settings 4', 'teamIndex': 1}, // Team 2
      ];

      for (final assignment in playerTeamAssignments) {
        final playerName = assignment['player'] as String;
        final teamIndex = assignment['teamIndex'] as int;

        // Find the player name and scroll it into view
        await scrollToFindWidget(tester, find.text(playerName));

        // Find the Row that contains this player name
        final playerNameFinder = find.text(playerName);
        final playerRow = find.ancestor(
          of: playerNameFinder,
          matching: find.byType(Row),
        );

        // Find the "Assign team" button within that Row
        final assignButton = find.descendant(
          of: playerRow.first,
          matching: find.text('Assign team'),
        );

        if (assignButton.evaluate().isEmpty) {
          continue;
        }

        // Tap the assign team button
        await tester.ensureVisible(assignButton.first);
        await tester.pump();
        await tester.tap(assignButton.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Dialog should appear - select the team
        expect(find.textContaining('Select Team for'), findsOneWidget);

        final gestureDetectors = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(GestureDetector),
        );

        // Tap the appropriate team (teamIndex: 0=first, 1=second)
        await tester.tap(gestureDetectors.at(teamIndex));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Dialog should close
        expect(find.textContaining('Select Team for'), findsNothing);
      }

      // Start game
      await startGame(tester);

      // Verify team game started
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify team mode and hero buff assignment
      expect(find.textContaining('Team'), findsWidgets);
      expect(find.textContaining('Buff:'), findsWidgets);
    });
  });
}
