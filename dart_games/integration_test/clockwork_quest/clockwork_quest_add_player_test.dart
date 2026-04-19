import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

/// Get whichever add player button is visible (empty state or normal)
Finder getAddPlayerButton(WidgetTester tester) {
  final emptyState = ElementFinders.getClockworkQuestAddPlayerButtonEmptyState();
  if (emptyState.evaluate().isNotEmpty) return emptyState;
  return ElementFinders.getClockworkQuestAddPlayerButton();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Add Player Tests', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // ================================================================
    // NAVIGATION
    // ================================================================

    testWidgets('Test 1: Navigate to Clockwork Quest menu',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify we're on the menu screen
      expect(config.getStartButton(), findsOneWidget);
      expect(find.byKey(ClockworkQuestMenuKeys.playerListView), findsOneWidget);
    });

    // ================================================================
    // ADD PLAYER
    // ================================================================

    testWidgets('Test 2: Add player with name shows in player list',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Cogsworth', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      expect(players.any((p) => p.name == 'Cogsworth'), isTrue);
    });

    testWidgets('Test 3: Add multiple players',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Inventor1', config);
      await UITestHelpers.addPlayer(tester, 'Inventor2', config);
      await UITestHelpers.addPlayer(tester, 'Inventor3', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      expect(players.any((p) => p.name == 'Inventor1'), isTrue);
      expect(players.any((p) => p.name == 'Inventor2'), isTrue);
      expect(players.any((p) => p.name == 'Inventor3'), isTrue);
    });

    // ================================================================
    // ADD PLAYER DIALOG
    // ================================================================

    testWidgets('Test 4: Add player dialog has required UI elements',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      // Dialog and name field should be visible
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);
      expect(ElementFinders.getAddPlayerNameField(), findsOneWidget);
      expect(ElementFinders.getAddPlayerAddButton(), findsOneWidget);
      expect(ElementFinders.getAddPlayerCancelButton(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 5: Add player with empty name is rejected',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      // Try to add with empty name
      final addButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addButton);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open (validation failed)
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 6: Add player with whitespace-only name is rejected',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      await tester.enterText(ElementFinders.getAddPlayerNameField(), '   ');
      await PumpSequences.textEntry(tester);

      final addButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addButton);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 7: Cancel add player dialog closes without adding',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final playersBefore = ProviderHelpers.getAllPlayers(tester).length;

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));
      await tester.enterText(
          ElementFinders.getAddPlayerNameField(), 'CancelMe');
      await PumpSequences.textEntry(tester);
      await SettingsHelpers.cancelAddPlayerDialog(tester);

      // Dialog should be closed
      expect(ElementFinders.getAddPlayerDialog(), findsNothing);

      // Player count should be unchanged
      final playersAfter = ProviderHelpers.getAllPlayers(tester).length;
      expect(playersAfter, playersBefore);
    });

    // ================================================================
    // PLAYER SELECTION
    // ================================================================

    testWidgets('Test 8: Added player can be selected',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Selectable', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final player = players.firstWhere((p) => p.name == 'Selectable');

      // Player tile should exist
      final tile = config.getPlayerTile(player.id);
      expect(tile, findsOneWidget);

      // Select the player
      await UITestHelpers.selectPlayers(tester, [player.id], config);

      final playerProvider = ProviderHelpers.getPlayerProvider(tester);
      expect(
        playerProvider.selectedPlayers.any((p) => p.id == player.id),
        isTrue,
        reason: 'Player should be selected after tapping',
      );
    });

    testWidgets('Test 9: Select and deselect player',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Toggle', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final player = players.firstWhere((p) => p.name == 'Toggle');

      // Select
      await UITestHelpers.selectPlayers(tester, [player.id], config);
      var playerProvider = ProviderHelpers.getPlayerProvider(tester);
      expect(playerProvider.selectedPlayers.any((p) => p.id == player.id), isTrue);

      // Deselect (tap again)
      await UITestHelpers.deselectPlayers(tester, [player.id], config);
      playerProvider = ProviderHelpers.getPlayerProvider(tester);
      expect(playerProvider.selectedPlayers.any((p) => p.id == player.id), isFalse);
    });

    // ================================================================
    // REMOVE PLAYER
    // ================================================================

    testWidgets('Test 10: Remove player from selected list',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'RemoveMe', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final player = players.firstWhere((p) => p.name == 'RemoveMe');

      // Select the player first
      await UITestHelpers.selectPlayers(tester, [player.id], config);

      // Find and tap the remove button
      final removeButton = find.byKey(ClockworkQuestMenuKeys.removePlayerButton(player.id));
      if (removeButton.evaluate().isNotEmpty) {
        await tester.tap(removeButton);
        await PumpSequences.simpleUpdate(tester);

        // Player should no longer be selected
        final playerProvider = ProviderHelpers.getPlayerProvider(tester);
        expect(playerProvider.selectedPlayers.any((p) => p.id == player.id), isFalse);
      }
    });
  });
}
