import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// Target Tag - Test 12 Debug
///
/// Isolated test for debugging Test 12: Game Settings Panel - Complete Validation
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run test
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/test_12_debug.dart \
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

    // Verify we're on the game screen
    expect(find.text('Target Tag Game On!'), findsOneWidget);
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
        await tester.tap(heroBonusSwitch.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
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

  group('Target Tag - Test 12 Debug', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'dartboard_name': 'Test Dartboard',
        'dartboard_serial': 'TEST-001',
        'use_emulator': true,
      });
    });

    testWidgets('Test 12: Game Settings Panel - Complete Validation', (WidgetTester tester) async {
      // ===== Step 1: Solo Mode Settings with Hero Bonus =====
      await navigateToTargetTagMenu(tester);

      // Enable Hero Bonus
      await enableHeroBonus(tester);

      // Add 2 players in Solo mode (default)
      await addPlayer(tester, 'Solo Player 1');
      await addPlayer(tester, 'Solo Player 2');

      // Start the game
      await startGame(tester);

      // Verify game started
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify game info panel shows Solo mode settings
      expect(find.textContaining('Game Settings'), findsWidgets);
      expect(find.textContaining('Solo'), findsWidgets);
      expect(find.textContaining('Shield Max'), findsWidgets);
      expect(find.textContaining('ON'), findsWidgets); // Hero Bonus ON

      // Wait/simulate some gameplay to verify persistence
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Verify game settings panel still visible with same settings
      expect(find.textContaining('Game Settings'), findsWidgets);
      expect(find.textContaining('Solo'), findsWidgets);
      expect(find.textContaining('Shield Max'), findsWidgets);

      // ===== Step 2: Return to menu and test Team Mode with Random Assignment =====
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Enable Team mode
      await enableTeamMode(tester);

      // Ensure Random assignment is selected (default for team mode)
      // Add 4 players
      await addPlayer(tester, 'Team Player 1');
      await addPlayer(tester, 'Team Player 2');
      await addPlayer(tester, 'Team Player 3');
      await addPlayer(tester, 'Team Player 4');

      // Start the game
      await startGame(tester);

      // Verify game started in Team mode
      expect(find.text('Target Tag Game On!'), findsOneWidget);

      // Verify game info panel shows Team mode settings
      // Note: Team assignment mode (Random/Manual) is not displayed on game screen
      expect(find.textContaining('Game Settings'), findsWidgets);
      expect(find.textContaining('Team'), findsWidgets);
      expect(find.textContaining('Shield Max'), findsWidgets);

      // ===== Step 3: Return to menu and test Manual Team Assignment UI =====
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
      }

      // Team mode should still be enabled
      // Switch to Manual team assignment
      await enableManualTeamAssignment(tester);

      // Add 4 players for manual assignment
      await addPlayer(tester, 'Manual Player 1');
      await addPlayer(tester, 'Manual Player 2');
      await addPlayer(tester, 'Manual Player 3');
      await addPlayer(tester, 'Manual Player 4');

      // Pump to ensure UI updates
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify players are added by scrolling to find them
      final foundPlayer1 = await scrollToFindWidget(tester, find.text('Manual Player 1'));
      expect(foundPlayer1, true, reason: 'Manual Player 1 should be found in the player list');

      final foundPlayer2 = await scrollToFindWidget(tester, find.text('Manual Player 2'));
      expect(foundPlayer2, true, reason: 'Manual Player 2 should be found in the player list');

      // Verify Manual mode is active
      expect(find.text('Manually'), findsOneWidget);

      // Note: Assigning players to teams manually and starting a game
      // requires complex UI interaction with team assignment controls.
    });
  });
}
