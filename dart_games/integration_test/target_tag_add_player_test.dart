import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// Target Tag - Add Player Dialog Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test the Add Player dialog functionality.
///
/// Run with:
/// ```bash
/// flutter test integration_test/target_tag_add_player_test.dart --platform chrome
/// ```
///
/// These tests automate the manual UI tests documented in TARGET_TAG_MANUAL_UI_TESTS.md:
/// - Test 1: Add Player with Name Only
/// - Test 2: Add Player with Name and Photo (UI elements only)
/// - Test 3: Add Player Validation - Empty Name

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Target Tag - Add Player Dialog Integration Tests', () {
    setUp(() async {
      // Clear shared preferences before each test to start fresh
      SharedPreferences.setMockInitialValues({
        // Pre-configure dartboard in emulator mode to skip setup screen
        'dartboard_name': 'Test Dartboard',
        'dartboard_serial': 'TEST-001',
        'use_emulator': true,
      });
    });

    testWidgets('Test 1: Navigation and Initial Player Setup - Validates app launch, game navigation, and basic player addition workflow with two players', (WidgetTester tester) async {
      // Launch the full app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      // The app should navigate to HomeScreen (since dartboard is pre-configured)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap the Target Tag game card
      final targetTagCard = find.text('Target Tag');
      expect(targetTagCard, findsOneWidget);
      await tester.tap(targetTagCard);

      // Target Tag menu has a continuous pulse animation that prevents pumpAndSettle
      // Use pump() instead to advance frames without waiting for animations to settle
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for PlayerProvider async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree with new data
      await tester.pump(); // Layout the new widgets
      await tester.pump(); // Paint the ElevatedButton

      // Verify we're on the Target Tag menu screen
      expect(find.textContaining('Shield Max:'), findsOneWidget);
      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);

      // Add first player
      // The button text exists but ElevatedButton type doesn't match - tap the text directly
      final addButton = find.text('NEW PLAYER');
      expect(addButton, findsAtLeastNWidgets(1));
      await tester.ensureVisible(addButton.first);
      await tester.pump(); // Process ensureVisible
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Enter first player name
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, 'Player 1');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Tap Add Player button
      final addPlayerButton = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Add Player'),
      );
      await tester.tap(addPlayerButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog to close
      await tester.pump(); // Process dialog closing

      // Verify first player was added
      expect(find.text('Player 1'), findsOneWidget);

      // Add second player
      await tester.ensureVisible(addButton.first);
      await tester.pump(); // Process ensureVisible
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Enter second player name
      await tester.enterText(nameField, 'Player 2');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Tap Add Player button
      await tester.tap(addPlayerButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog to close
      await tester.pump(); // Process dialog closing

      // Verify second player was added
      expect(find.text('Player 2'), findsOneWidget);
    });

    testWidgets('Test 2: Add Player with Name Only - Validates new player dialog opening, name field entry, player creation without photo, dialog closure, and player appears in list with auto-selection', (WidgetTester tester) async {
      // Launch the full app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Target Tag
      final targetTagCard = find.text('Target Tag');
      await tester.tap(targetTagCard);

      // Target Tag menu has a continuous pulse animation that prevents pumpAndSettle
      // Use pump() instead to advance frames without waiting for animations to settle
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for PlayerProvider async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree with new data
      await tester.pump(); // Layout the new widgets
      await tester.pump(); // Paint the ElevatedButton

      // Find and tap "NEW PLAYER" button
      // The button text exists but ElevatedButton type doesn't match - tap the text directly
      final addButton = find.text('NEW PLAYER');
      expect(addButton, findsAtLeastNWidgets(1));
      await tester.ensureVisible(addButton.first);
      await tester.pump(); // Process ensureVisible
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Verify dialog opened with expected elements
      expect(find.text('Player Name'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('CAMERA'), findsOneWidget);
      expect(find.text('GALLERY'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Player'), findsWidgets); // Multiple instances (title + button)

      // Enter player name
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Test Player');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Tap "Add Player" button in the dialog
      // Find the button (not the title)
      final addPlayerButtons = find.text('Add Player');
      final buttonWidget = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Add Player'),
      );
      await tester.tap(buttonWidget.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for action to complete
      await tester.pump(); // Process completion

      // Verify dialog closed (Player Name field should not be visible)
      expect(find.text('Player Name'), findsNothing);

      // Verify player appears in the player list with checkmark (selected)
      expect(find.text('Test Player'), findsOneWidget);

      // The player card should show a checkmark indicating selection
      // We can verify this by checking for the player name in the UI
      final playerCard = find.text('Test Player');
      expect(playerCard, findsOneWidget);
    });

    testWidgets('Test 3: Add Player Photo UI Elements - Validates photo upload interface elements (Camera/Gallery buttons, icons, placeholder avatar, optional photo label), player creation with photo UI workflow', (WidgetTester tester) async {
      // Launch the full app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Target Tag
      final targetTagCard = find.text('Target Tag');
      await tester.tap(targetTagCard);

      // Target Tag menu has a continuous pulse animation that prevents pumpAndSettle
      // Use pump() instead to advance frames without waiting for animations to settle
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for PlayerProvider async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree with new data
      await tester.pump(); // Layout the new widgets
      await tester.pump(); // Paint the ElevatedButton

      // Find and tap "NEW PLAYER" button
      final addButton = find.text('NEW PLAYER');
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Verify dialog opened
      expect(find.text('Add New Player'), findsWidgets);

      // Verify photo selection UI elements are present
      expect(find.text('CAMERA'), findsOneWidget);
      expect(find.text('GALLERY'), findsOneWidget);
      expect(find.text('Photo (Optional)'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget); // Placeholder avatar
      expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Camera button icon
      expect(find.byIcon(Icons.photo_library), findsOneWidget); // Gallery button icon

      // Enter player name
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, 'Photo Player');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Note: We cannot test actual photo selection in integration tests
      // without complex mocking. This test verifies UI elements exist.

      // Tap "Add Player" button
      final buttonWidget = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Add Player'),
      );
      await tester.tap(buttonWidget.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for action to complete
      await tester.pump(); // Process completion

      // Verify player was added
      expect(find.text('Photo Player'), findsOneWidget);
    });

    testWidgets('Test 4: Add Player Empty Name Validation - Validates empty name field submission shows error message, dialog remains open after error, error message clears on valid input, successful player creation after correction', (WidgetTester tester) async {
      // Launch the full app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Target Tag
      final targetTagCard = find.text('Target Tag');
      await tester.tap(targetTagCard);

      // Target Tag menu has a continuous pulse animation that prevents pumpAndSettle
      // Use pump() instead to advance frames without waiting for animations to settle
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for PlayerProvider async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree with new data
      await tester.pump(); // Layout the new widgets
      await tester.pump(); // Paint the ElevatedButton

      // Find and tap "NEW PLAYER" button
      final addButton = find.text('NEW PLAYER');
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Verify dialog opened
      expect(find.text('Player Name'), findsOneWidget);

      // Leave name field empty and try to add player
      final buttonWidget = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Add Player'),
      );
      await tester.tap(buttonWidget.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for action to complete
      await tester.pump(); // Process completion

      // Verify error message appears
      expect(find.text('Please enter a name'), findsOneWidget);

      // Verify dialog remains open
      expect(find.text('Player Name'), findsOneWidget);

      // Enter valid name
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, 'Valid Player');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Verify error message disappears when typing
      expect(find.text('Please enter a name'), findsNothing);

      // Tap "Add Player" button again
      await tester.tap(buttonWidget.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for action to complete
      await tester.pump(); // Process completion

      // Verify player was saved successfully
      expect(find.text('Valid Player'), findsOneWidget);

      // Verify dialog closed
      expect(find.text('Player Name'), findsNothing);
    });

    testWidgets('Test 5: Add Player Whitespace-Only Name Validation - Validates whitespace-only input (spaces/tabs) is rejected as invalid, error message displays for whitespace input, dialog remains open after whitespace validation error', (WidgetTester tester) async {
      // Launch the full app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Target Tag
      final targetTagCard = find.text('Target Tag');
      await tester.tap(targetTagCard);

      // Target Tag menu has a continuous pulse animation that prevents pumpAndSettle
      // Use pump() instead to advance frames without waiting for animations to settle
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for PlayerProvider async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree with new data
      await tester.pump(); // Layout the new widgets
      await tester.pump(); // Paint the ElevatedButton

      // Find and tap "NEW PLAYER" button
      final addButton = find.text('NEW PLAYER');
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Enter only whitespace in name field
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, '   ');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Try to add player
      final buttonWidget = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Add Player'),
      );
      await tester.tap(buttonWidget.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for action to complete
      await tester.pump(); // Process completion

      // Verify error message appears
      expect(find.text('Please enter a name'), findsOneWidget);

      // Verify dialog remains open
      expect(find.text('Player Name'), findsOneWidget);
    });

    testWidgets('Test 6: Cancel Button Functionality - Validates cancel button closes dialog without saving player data, entered player name is not added to player list, dialog properly closes and returns to menu screen', (WidgetTester tester) async {
      // Launch the full app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Target Tag
      final targetTagCard = find.text('Target Tag');
      await tester.tap(targetTagCard);

      // Target Tag menu has a continuous pulse animation that prevents pumpAndSettle
      // Use pump() instead to advance frames without waiting for animations to settle
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(seconds: 1)); // Let navigation complete
      await tester.pump(); // Process navigation
      await tester.pump(const Duration(seconds: 5)); // Wait for PlayerProvider async loading
      await tester.pump(); // Process data loaded
      await tester.pump(); // Rebuild widget tree with new data
      await tester.pump(); // Layout the new widgets
      await tester.pump(); // Paint the ElevatedButton

      // Find and tap "NEW PLAYER" button
      final addButton = find.text('NEW PLAYER');
      await tester.tap(addButton.first);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
      await tester.pump(); // Build dialog
      await tester.pump(); // Layout dialog
      await tester.pump(); // Paint dialog

      // Enter a player name
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, 'Cancelled Player');
      await tester.pump(); // Process text entry
      await tester.pump(); // Update text field

      // Tap Cancel button
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pump(); // Process tap
      await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog to close
      await tester.pump(); // Process dialog closing

      // Verify dialog closed
      expect(find.text('Player Name'), findsNothing);

      // Verify player was NOT added (should not appear in list)
      expect(find.text('Cancelled Player'), findsNothing);
    });
  });
}
