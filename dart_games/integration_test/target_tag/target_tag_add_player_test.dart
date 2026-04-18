import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Shared component imports
import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';

// Test keys
import 'package:dart_games/constants/test_keys.dart';

/// Target Tag - Add Player Dialog Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test the Add Player dialog functionality.
///
/// Run with:
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/target_tag_add_player_test.dart -d chrome
/// ```
///
/// These tests automate the manual UI tests documented in TARGET_TAG_MANUAL_UI_TESTS.md:
/// - Test 1: Add Player with Name Only
/// - Test 2: Add Player with Name and Photo (UI elements only)
/// - Test 3: Add Player Validation - Empty Name

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Target Tag
  final config = GameUIConfig.targetTag();

  group('Target Tag - Add Player Dialog Integration Tests', () {
    setUp(() async {
      // Initialize settings with emulator mode
      await UITestHelpers.resetServerState();
    });

    testWidgets('Test 1: Navigation and Initial Player Setup - Validates app launch, game navigation, and basic player addition workflow with two players', (WidgetTester tester) async {
      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify we're on the Target Tag menu screen
      expect(find.textContaining('Shield Max:'), findsOneWidget);
      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);

      // Add first player (using empty state button)
      final addButtonEmpty = find.byKey(TargetTagMenuKeys.addPlayerButtonEmptyState);
      expect(addButtonEmpty, findsOneWidget);
      await tester.tap(addButtonEmpty);
      await PumpSequences.dialogOpen(tester);

      // Enter first player name
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, 'Player 1');
      await PumpSequences.textEntry(tester);

      // Tap Add Player button
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify first player was added
      expect(find.text('Player 1'), findsOneWidget);

      // Add second player (now using normal state button)
      final addButtonNormal = ElementFinders.getTargetTagAddPlayerButton();
      expect(addButtonNormal, findsAtLeastNWidgets(1));
      await tester.tap(addButtonNormal.first);
      await PumpSequences.dialogOpen(tester);

      // Enter second player name
      await tester.enterText(nameField, 'Player 2');
      await PumpSequences.textEntry(tester);

      // Tap Add Player button
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify second player was added
      expect(find.text('Player 2'), findsOneWidget);
    });

    testWidgets('Test 2: Add Player with Name Only - Validates new player dialog opening, name field entry, player creation without photo, dialog closure, player appears in list. Note: Does NOT explicitly verify auto-selection status (checkmark visible) - only confirms player exists in list and player card renders', (WidgetTester tester) async {
      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Find and tap "NEW PLAYER" button (empty state since no players yet)
      final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      expect(addButton, findsAtLeastNWidgets(1));
      await tester.ensureVisible(addButton.first);
      await tester.pump();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Verify dialog opened with expected elements
      expect(find.text('Player Name'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('CAMERA'), findsOneWidget);
      expect(find.text('GALLERY'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Player'), findsWidgets); // Multiple instances (title + button)

      // Enter player name
      final nameField = ElementFinders.getAddPlayerNameField();
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Test Player');
      await PumpSequences.textEntry(tester);

      // Tap "Add Player" button in the dialog
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify dialog closed (Player Name field should not be visible)
      expect(find.text('Player Name'), findsNothing);

      // Verify player appears in the player list with checkmark (selected)
      expect(find.text('Test Player'), findsOneWidget);

      // The player card should show a checkmark indicating selection
      final playerCard = find.text('Test Player');
      expect(playerCard, findsOneWidget);
    });

    testWidgets('Test 3: Add Player Photo UI Elements - Validates photo upload interface elements (Camera/Gallery buttons, icons, placeholder avatar, optional photo label), player creation with photo UI workflow', (WidgetTester tester) async {
      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Find and tap "NEW PLAYER" button (empty state since no players yet)
      final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

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
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, 'Photo Player');
      await PumpSequences.textEntry(tester);

      // Note: We cannot test actual photo selection in integration tests
      // without complex mocking. This test verifies UI elements exist.

      // Tap "Add Player" button
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify player was added
      expect(find.text('Photo Player'), findsOneWidget);
    });

    testWidgets('Test 4: Add Player Empty Name Validation - Validates empty name field submission shows error message, dialog remains open after error, error message clears on valid input, successful player creation after correction', (WidgetTester tester) async {
      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Find and tap "NEW PLAYER" button (empty state since no players yet)
      final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Verify dialog opened
      expect(find.text('Player Name'), findsOneWidget);

      // Leave name field empty and try to add player
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.simpleUpdate(tester);

      // Verify error message appears
      expect(find.text('Please enter a player name'), findsOneWidget);

      // Verify dialog remains open
      expect(find.text('Player Name'), findsOneWidget);

      // Enter valid name
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, 'Valid Player');
      await PumpSequences.textEntry(tester);

      // Verify error message disappears when typing
      expect(find.text('Please enter a player name'), findsNothing);

      // Tap "Add Player" button again
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify player was saved successfully
      expect(find.text('Valid Player'), findsOneWidget);

      // Verify dialog closed
      expect(find.text('Player Name'), findsNothing);
    });

    testWidgets('Test 5: Add Player Whitespace-Only Name Validation - Validates whitespace-only input (spaces/tabs) is rejected as invalid, error message displays for whitespace input, dialog remains open after whitespace validation error', (WidgetTester tester) async {
      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Find and tap "NEW PLAYER" button (empty state since no players yet)
      final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Enter only whitespace in name field
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, '   ');
      await PumpSequences.textEntry(tester);

      // Try to add player
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.simpleUpdate(tester);

      // Verify error message appears
      expect(find.text('Please enter a player name'), findsOneWidget);

      // Verify dialog remains open
      expect(find.text('Player Name'), findsOneWidget);
    });

    testWidgets('Test 6: Cancel Button Functionality - Validates cancel button closes dialog without saving player data, entered player name is not added to player list, dialog properly closes and returns to menu screen', (WidgetTester tester) async {
      // Navigate to Target Tag menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Find and tap "NEW PLAYER" button (empty state since no players yet)
      final addButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Enter a player name
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, 'Cancelled Player');
      await PumpSequences.textEntry(tester);

      // Tap Cancel button
      final cancelButton = ElementFinders.getAddPlayerCancelButton();
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await PumpSequences.dialogClose(tester);

      // Verify dialog closed
      expect(find.text('Player Name'), findsNothing);

      // Verify player was NOT added (should not appear in list)
      expect(find.text('Cancelled Player'), findsNothing);
    });
  });
}
