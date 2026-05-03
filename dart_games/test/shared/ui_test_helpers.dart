import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/main.dart' as app;
import 'package:dart_games/services/api/api_config.dart';
import 'package:dart_games/widgets/player_selection_card.dart';
import 'game_ui_config.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';
import 'settings_helpers.dart';

/// High-level UI navigation and interaction helpers
///
/// Provides game-agnostic test helpers that work with any game configuration.
/// All operations use widget keys for reliable element finding.
class UITestHelpers {
  // ==========================================================================
  // STATE RESET HELPERS
  // ==========================================================================

  /// Reset server + client state between tests.
  ///
  /// Call this from `setUp()` in every UI test file so each `testWidgets`
  /// starts with a clean database (no leftover players, saved games,
  /// game history, or victory music from a prior test).
  ///
  /// Without this, tests that depend on empty-state UI (e.g. the "NEW
  /// PLAYER" button, or the resume modal) fail because earlier tests in
  /// the same file leaked state.
  ///
  /// This is a thin wrapper over [SettingsHelpers.initializeSettings] that
  /// makes the intent explicit in test files' `setUp`.
  static Future<void> resetServerState({bool useEmulator = true}) async {
    if (ApiConfig.dbSession == null) {
      final sessionId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      ApiConfig.setDbSession('session-$sessionId');
    }
    await SettingsHelpers.resetServerState(useEmulator: useEmulator);
  }

  // ==========================================================================
  // NAVIGATION HELPERS
  // ==========================================================================

  /// Navigate from home screen to game menu
  static Future<void> navigateToGameMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    print('UITestHelpers.navigateToGameMenu: START');

    // Launch app
    await app.main();
    print('UITestHelpers.navigateToGameMenu: App launched, pumping...');

    // NOTE: Do NOT use pumpAndSettle() here — the splash screen has a
    // CircularProgressIndicator (continuous animation) that prevents settling.
    // Use manual pumps instead to wait for splash → home navigation.
    await tester.pump(); // Process initial frame
    await tester.pump(const Duration(seconds: 2)); // Wait for splash delay + config load
    await tester.pump(); // Process navigation
    await tester.pump(const Duration(seconds: 2)); // Wait for home screen to build
    await tester.pump(); // Rebuild
    await tester.pump(); // Layout
    await tester.pump(); // Paint
    print('UITestHelpers.navigateToGameMenu: Manual pump sequence complete');

    // Wait for home screen cards to load (async operation)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    print('UITestHelpers.navigateToGameMenu: Waited for cards to load');

    // Tap game card
    final gameCard = config.getGameCard();
    print('UITestHelpers.navigateToGameMenu: Found ${gameCard.evaluate().length} game cards');

    expect(gameCard, findsOneWidget);
    await tester.tap(gameCard);

    // Wait for navigation
    await PumpSequences.navigation(tester);
    print('UITestHelpers.navigateToGameMenu: COMPLETE');
  }

  /// Start the game from menu screen
  static Future<void> startGame(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final startButton = config.getStartButton();
    await tester.ensureVisible(startButton);
    await tester.pump();
    await tester.tap(startButton);
    await PumpSequences.navigation(tester);
  }

  // ==========================================================================
  // PLAYER MANAGEMENT HELPERS
  // ==========================================================================

  /// Add a player via the add player dialog
  static Future<void> addPlayer(
    WidgetTester tester,
    String name,
    GameUIConfig config,
  ) async {
    // Try to find the add player button (handles both empty state and normal state)
    Finder addButton;
    if (config.gameName == 'Target Tag') {
      // For Target Tag, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getTargetTagAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getTargetTagAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Carnival Derby') {
      // For Carnival Derby, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getCarnivalDerbyAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getCarnivalDerbyAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Monster Mash') {
      // For Monster Mash, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getMonsterMashAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getMonsterMashAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Reef Royale') {
      // For Reef Royale, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getReefRoyaleAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getReefRoyaleAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Clockwork Quest') {
      // For Clockwork Quest, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getClockworkQuestAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getClockworkQuestAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Lunar Lander') {
      // For Lunar Lander, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getLunarLanderAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getLunarLanderAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else {
      // For other games, use the config method
      addButton = config.getAddPlayerButton();
    }

    await tester.ensureVisible(addButton.first);
    await tester.pump();

    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, name);
    await PumpSequences.textEntry(tester);

    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);
  }

  /// Select multiple players from the player list
  /// Skips players that are already selected to avoid toggling them off
  static Future<void> selectPlayers(
    WidgetTester tester,
    List<String> playerIds,
    GameUIConfig config,
  ) async {
    for (final playerId in playerIds) {
      final playerTile = config.getPlayerTile(playerId);
      if (playerTile.evaluate().isEmpty) continue;

      // Check if already selected — skip to avoid toggling off
      final card = tester.widget<PlayerSelectionCard>(playerTile.first);
      if (card.isSelected) continue;

      await tester.ensureVisible(playerTile.first);
      await tester.pump();
      await tester.tap(playerTile.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Deselect multiple players from the player list
  /// Skips players that are already deselected
  static Future<void> deselectPlayers(
    WidgetTester tester,
    List<String> playerIds,
    GameUIConfig config,
  ) async {
    for (final playerId in playerIds) {
      final playerTile = config.getPlayerTile(playerId);
      if (playerTile.evaluate().isEmpty) continue;

      // Check if not selected — skip to avoid toggling on
      final card = tester.widget<PlayerSelectionCard>(playerTile.first);
      if (!card.isSelected) continue;

      await tester.ensureVisible(playerTile.first);
      await tester.pump();
      await tester.tap(playerTile.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  // ==========================================================================
  // GAME CONTROL HELPERS
  // ==========================================================================

  /// Click "Skip Turn" button
  static Future<void> clickSkipTurn(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final skipButton = config.getSkipTurnButton();
    await tester.ensureVisible(skipButton);
    await tester.pump();
    await tester.tap(skipButton);
    await PumpSequences.simpleUpdate(tester);
  }

  // ==========================================================================
  // RESULTS SCREEN HELPERS
  // ==========================================================================

  /// Verify results screen is showing
  static Future<void> verifyResultsScreen(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    await tester.pump();
    await tester.pump();
    expect(config.getPlayAgainButton(), findsOneWidget);
    expect(config.getChangeSettingsButton(), findsOneWidget);
    expect(config.getBackToMenuButton(), findsOneWidget);
  }

  /// Click "Play Again" button on results screen
  static Future<void> clickPlayAgain(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final playAgainButton = config.getPlayAgainButton();
    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);
  }

  /// Click "Change Settings" button on results screen
  static Future<void> clickChangeSettings(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final changeSettingsButton = config.getChangeSettingsButton();
    await tester.ensureVisible(changeSettingsButton);
    await tester.pump();
    await tester.tap(changeSettingsButton);
    await PumpSequences.navigation(tester);
  }

  /// Click "Back to Menu" button on results screen
  static Future<void> clickBackToMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final backToMenuButton = config.getBackToMenuButton();
    await tester.ensureVisible(backToMenuButton);
    await tester.pump();
    await tester.tap(backToMenuButton);
    await PumpSequences.navigation(tester);
  }

  // ==========================================================================
  // SAVE/RESUME GAME HELPERS
  // ==========================================================================

  /// Launch app and navigate to home screen (settings must be initialized first)
  static Future<void> navigateToHomeScreen(WidgetTester tester) async {
    print('UITestHelpers.navigateToHomeScreen: START');

    await app.main();
    // Same pump sequence as navigateToGameMenu but stop at home screen
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    print('UITestHelpers.navigateToHomeScreen: Pump sequence complete');

    // Let home screen rebuild
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    print('UITestHelpers.navigateToHomeScreen: COMPLETE');
  }

  /// Tap back button on game screen (uses widget key via config)
  static Future<void> tapGameScreenBackButton(WidgetTester tester, GameUIConfig config) async {
    final backButton = config.getGameBackButton();
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Verify save game modal is showing
  static void verifySaveGameModal() {
    expect(ElementFinders.getSaveGameModalOverlay(), findsOneWidget);
    expect(ElementFinders.getSaveGameModalSaveButton(), findsOneWidget);
    expect(ElementFinders.getSaveGameModalDontSaveButton(), findsOneWidget);
  }

  /// Tap Save button on save game modal
  static Future<void> tapSaveGameButton(WidgetTester tester) async {
    await tester.tap(ElementFinders.getSaveGameModalSaveButton());
    await PumpSequences.navigation(tester);
  }

  /// Tap Don't Save button on save game modal
  static Future<void> tapDontSaveButton(WidgetTester tester) async {
    await tester.tap(ElementFinders.getSaveGameModalDontSaveButton());
    await PumpSequences.navigation(tester);
  }

  /// Verify resume game modal is showing
  static void verifyResumeGameModal() {
    expect(ElementFinders.getResumeGameModalOverlay(), findsOneWidget);
    expect(ElementFinders.getResumeGameModalResumeButton(), findsOneWidget);
    expect(ElementFinders.getResumeGameModalStartNewButton(), findsOneWidget);
  }

  /// Select a saved game tile on resume modal
  static Future<void> selectSavedGameTile(WidgetTester tester, String id) async {
    final tile = ElementFinders.getResumeGameModalSavedGameTile(id);
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Tap Resume Game button on resume modal
  static Future<void> tapResumeGameButton(WidgetTester tester) async {
    await tester.tap(ElementFinders.getResumeGameModalResumeButton());
    await PumpSequences.navigation(tester);
  }

  /// Tap Start New Game button on resume modal
  static Future<void> tapStartNewGameButton(WidgetTester tester) async {
    await tester.tap(ElementFinders.getResumeGameModalStartNewButton());
    await PumpSequences.navigation(tester);
  }

  /// Delete a saved game tile on resume modal
  static Future<void> deleteSavedGameTile(WidgetTester tester, String id) async {
    await tester.tap(ElementFinders.getResumeGameModalDeleteButton(id));
    // Delete roundtrips through HTTP (DELETE /games/{id}) and triggers a
    // provider reload (GET /games) before the modal rebuilds.  simpleUpdate
    // (2 zero-duration pumps) is too short — asyncDataLoad waits 5s.
    await PumpSequences.asyncDataLoad(tester);
  }

  /// Delete all saved games on resume modal
  static Future<void> deleteAllSavedGames(WidgetTester tester) async {
    await tester.tap(ElementFinders.getResumeGameModalDeleteAllButton());
    await PumpSequences.asyncDataLoad(tester);
  }
}
