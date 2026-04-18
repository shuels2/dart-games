import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/main.dart' as app;
import 'package:dart_games/widgets/player_selection_card.dart';
import 'game_ui_config.dart';
import 'element_finders.dart';
import 'provider_helpers.dart';
import 'pump_sequences.dart';
import 'settings_helpers.dart';

/// High-level UI navigation and interaction helpers
///
/// Provides game-agnostic test helpers that work with any game configuration.
/// All operations use widget keys for reliable element finding.
class UITestHelpers {
  // ==========================================================================
  // NAVIGATION HELPERS
  // ==========================================================================

  /// Navigate from home screen to game menu
  static Future<void> navigateToGameMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    print('UITestHelpers.navigateToGameMenu: START');

    // Set up emulator mode
    print('UITestHelpers.navigateToGameMenu: Calling initializeSettings...');
    await SettingsHelpers.initializeSettings();
    print('UITestHelpers.navigateToGameMenu: initializeSettings complete');

    // Launch app (await ensures runApp() fires before pumps start,
    // so the widget tree is fully replaced with fresh providers)
    print('UITestHelpers.navigateToGameMenu: Launching app...');
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

    // Debug: Check what screen we're on
    print('UITestHelpers.navigateToGameMenu: Checking which screen is displayed...');

    // Check for home screen
    final homeScreenText = find.text('Let\'s play some Dart Games');
    print('UITestHelpers.navigateToGameMenu: Home screen found: ${homeScreenText.evaluate().length}');

    // Check for setup screen
    final setupText = find.text('Scolia Dartboard Setup');
    print('UITestHelpers.navigateToGameMenu: Setup screen found: ${setupText.evaluate().length}');

    // Check for splash screen
    final splashText = find.text('DARTS');
    print('UITestHelpers.navigateToGameMenu: Splash screen found: ${splashText.evaluate().length}');

    // Reset client-side player state so any in-flight loadPlayers() from
    // a prior test (or the menu screen's addPostFrameCallback) is
    // discarded via the generation counter rather than repopulating the
    // list with stale data.
    ProviderHelpers.getPlayerProvider(tester).resetForTesting();
    print('UITestHelpers.navigateToGameMenu: PlayerProvider reset');

    // Wait for home screen cards to load (async operation)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    print('UITestHelpers.navigateToGameMenu: Waited for cards to load');

    // Tap game card
    print('UITestHelpers.navigateToGameMenu: Looking for game card...');
    final gameCard = config.getGameCard();
    print('UITestHelpers.navigateToGameMenu: Game card finder created, checking...');

    print('UITestHelpers.navigateToGameMenu: Found ${gameCard.evaluate().length} game cards');

    expect(gameCard, findsOneWidget);
    print('UITestHelpers.navigateToGameMenu: Game card found, tapping...');

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
    await PumpSequences.simpleUpdate(tester);
  }

  /// Delete all saved games on resume modal
  static Future<void> deleteAllSavedGames(WidgetTester tester) async {
    await tester.tap(ElementFinders.getResumeGameModalDeleteAllButton());
    await PumpSequences.simpleUpdate(tester);
  }
}
