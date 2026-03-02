import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Shared component imports
import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

/// Monster Mash - Add Player Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test the Add Player dialog functionality including:
/// - Navigation from home to Monster Mash menu
/// - Adding players via empty state and normal buttons
/// - Name validation (empty, whitespace)
/// - Cancel button behavior
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash_add_player_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Monster Mash
  final config = GameUIConfig.monsterMash();

  group('Monster Mash - Add Player Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Navigation and initial player setup - Navigate from home card to Monster Mash menu, add 2 players via empty-state then normal button', (WidgetTester tester) async {
      // Navigate to Monster Mash menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify we are on the Monster Mash menu screen
      expect(find.textContaining('Monster Mash'), findsWidgets);

      // Add first player using empty state button
      await UITestHelpers.addPlayer(tester, 'Monster Alpha', config);

      // Verify first player was added
      expect(find.text('Monster Alpha'), findsWidgets);

      // Add second player using normal state button
      await UITestHelpers.addPlayer(tester, 'Monster Beta', config);

      // Verify second player was added
      expect(find.text('Monster Beta'), findsWidgets);

      // Verify both players are in the player provider
      final allPlayers = ProviderHelpers.getAllPlayers(tester);
      final alphaPlayer = ProviderHelpers.findPlayerByName(tester, 'Monster Alpha');
      final betaPlayer = ProviderHelpers.findPlayerByName(tester, 'Monster Beta');
      expect(alphaPlayer, isNotNull);
      expect(betaPlayer, isNotNull);
    });

    testWidgets('Test 2: Add player with name only - Open dialog, enter name, tap Add, verify player appears in list', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Add a player with just a name (no photo)
      await UITestHelpers.addPlayer(tester, 'Dracula Fan', config);

      // Verify player appears in the list
      expect(find.text('Dracula Fan'), findsWidgets);

      // Verify player was created via provider
      final player = ProviderHelpers.findPlayerByName(tester, 'Dracula Fan');
      expect(player, isNotNull);
    });

    testWidgets('Test 3: Add player photo UI elements - Camera/gallery buttons present in dialog, player created without photo', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Open the add player dialog
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

      // Verify dialog is open
      final dialog = ElementFinders.getAddPlayerDialog();
      expect(dialog, findsOneWidget);

      // Verify camera and gallery buttons exist
      final cameraButton = ElementFinders.getAddPlayerCameraButton();
      final galleryButton = ElementFinders.getAddPlayerGalleryButton();
      expect(cameraButton, findsOneWidget);
      expect(galleryButton, findsOneWidget);

      // Verify name field exists
      final nameField = ElementFinders.getAddPlayerNameField();
      expect(nameField, findsOneWidget);

      // Enter a name and add player (without selecting photo)
      await tester.enterText(nameField, 'No Photo Player');
      await PumpSequences.textEntry(tester);

      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify player was created
      expect(find.text('No Photo Player'), findsWidgets);
    });

    testWidgets('Test 4: Empty name validation - Tap Add with empty name -> error message, enter valid name -> error clears, add succeeds', (WidgetTester tester) async {
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

      // Try to add with empty name
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.simpleUpdate(tester);

      // Verify error message appears
      expect(find.textContaining('Please enter a player name'), findsOneWidget);

      // Now enter a valid name
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, 'Valid Name');
      await PumpSequences.textEntry(tester);

      // Tap Add again
      await tester.tap(addPlayerButton.first);
      await PumpSequences.dialogClose(tester);

      // Verify player was added successfully
      expect(find.text('Valid Name'), findsWidgets);
    });

    testWidgets('Test 5: Whitespace-only name validation - Enter "   ", tap Add -> error, dialog stays open', (WidgetTester tester) async {
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

      // Enter whitespace-only name
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, '   ');
      await PumpSequences.textEntry(tester);

      // Try to add
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.simpleUpdate(tester);

      // Verify dialog is still open (error state)
      final dialog = ElementFinders.getAddPlayerDialog();
      expect(dialog, findsOneWidget);

      // Verify error message
      expect(find.textContaining('Please enter a player name'), findsOneWidget);
    });

    testWidgets('Test 6: Cancel button - Enter name, tap Cancel -> dialog closes, player NOT added', (WidgetTester tester) async {
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
  });
}
