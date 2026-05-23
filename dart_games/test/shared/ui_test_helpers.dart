import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  // FAILURE SCREENSHOT HELPER
  // ==========================================================================

  /// Wrap a test body so any exception triggers a failure screenshot before
  /// rethrowing. The screenshot lands at
  /// `temp_screenshots/failures/<testName>_<timestampMs>.png` (the timestamp
  /// suffix prevents collisions when parallel workers fail at similar moments).
  ///
  /// **Build phase only.** This wrap is applied to every UI test during
  /// Phase 7 of the game.build skill (iterative test authoring), where
  /// failure pixels accelerate triage. Tests run with
  /// `--driver=test_driver/screenshot_test.dart`; that driver's
  /// `onScreenshot` callback writes the bytes to disk.
  ///
  /// At Phase 9 Gate 4 (all UI + non-UI + screenshots simultaneously green)
  /// the wraps are removed by an unwrap sub-agent so tests match the form
  /// every other game's tests use. Production CI runs via
  /// `test_driver/integration_test.dart` (no `onScreenshot`); the wrap would
  /// be inert there anyway, but removing it eliminates per-test boilerplate.
  ///
  /// Usage during build:
  /// ```dart
  /// testWidgets('foo', (tester) async {
  ///   await UITestHelpers.runWithFailureScreenshot(
  ///     tester,
  ///     '[GAME_NAME_SNAKE]_<subdir>_<test_basename>',
  ///     () async {
  ///       // existing test body
  ///     },
  ///   );
  /// });
  /// ```
  static Future<void> runWithFailureScreenshot(
    WidgetTester tester,
    String testName,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (_) {
      // Best-effort capture. Never let a screenshot failure mask the real
      // test failure — wrap in its own try/catch and swallow internal errors.
      try {
        final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
        // Settle a few frames so the canvas reflects the post-failure state
        // before takeScreenshot reads it.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeName = testName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final fullName = 'failures/${safeName}_$timestamp';
        // Bound takeScreenshot with a hard timeout. Under
        // test_driver/screenshot_test.dart the call resolves in well under a
        // second; under test_driver/integration_test.dart (which has no
        // onScreenshot callback) the call hangs forever — which previously
        // masked legitimate test failures as 10-minute "Chrome session died"
        // infrastructure errors at the worker-poll-timeout boundary. The
        // 5-second cap surfaces the underlying assertion failure within seconds
        // instead. Past failure: home_screen filter_no_match_test failed an
        // assertion (registry change broke its filter premise); the rethrown
        // exception was hidden for 600s because takeScreenshot never returned.
        // onTimeout must return a value matching takeScreenshot's
        // Future<List<int>> result type — Dart's type checker rejects a
        // void-returning callback here (which was the previous compile
        // error: "A non-null value must be returned since the return type
        // 'FutureOr<List<int>>' doesn't allow null"). Return an empty byte
        // list as the sentinel for "no screenshot captured."
        await binding.takeScreenshot(fullName).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // ignore: avoid_print
            print('[FAILURE_SCREENSHOT] takeScreenshot timed out after 5s — '
                'likely running under test_driver/integration_test.dart '
                '(no onScreenshot callback). The real test failure is the '
                'rethrown exception that follows.');
            return <int>[];
          },
        );
        // ignore: avoid_print
        print('[FAILURE_SCREENSHOT] saved as temp_screenshots/$fullName.png');
      } catch (sse) {
        // ignore: avoid_print
        print('[FAILURE_SCREENSHOT] capture failed: $sse');
      }
      rethrow;
    }
  }

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

    // Tap game card via the scroll-aware helper so cards in the bottom rows
    // (offscreen at default 1366x768 viewport once the GAMES list grows past
    // 6) are scrolled into view before the tap.
    await tapGameCard(tester, config);
    print('UITestHelpers.navigateToGameMenu: COMPLETE');
  }

  /// Tap the home-screen game card for [config], scrolling it into view first.
  ///
  /// The home screen wraps its game-card grid in a `SingleChildScrollView`, so
  /// cards that sit in the bottom rows can be offscreen at the default
  /// headless viewport (1366x768). Calling `tester.tap` directly on an
  /// offscreen widget is a silent no-op under chromedriver — the test then
  /// fails downstream with "menu screen never mounted" or similar without
  /// surfacing the real cause.
  ///
  /// This helper:
  ///   1. Asserts the card is in the widget tree (`findsOneWidget`)
  ///   2. Calls `tester.ensureVisible(card)` so the scrollview brings it
  ///      into the viewport
  ///   3. Pumps a frame so the scroll animation completes
  ///   4. Taps
  ///   5. Pumps the standard navigation sequence
  ///
  /// Use this anywhere a test taps the home card. The pattern
  /// `await tester.tap(config.getGameCard())` is brittle once 7+ games are
  /// in the list and should be replaced with `await UITestHelpers.tapGameCard(tester, config)`.
  static Future<void> tapGameCard(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final gameCard = config.getGameCard();
    expect(gameCard, findsOneWidget);
    await tester.ensureVisible(gameCard);
    await tester.pump();
    await tester.tap(gameCard);
    await PumpSequences.navigation(tester);
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
    } else if (config.gameName == "Pirate's Grid") {
      // For Pirate's Grid, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getPiratesGridAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getPiratesGridAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Gladiator Arena') {
      // For Gladiator Arena, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getGladiatorArenaAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getGladiatorArenaAddPlayerButton();

      if (emptyStateButton.evaluate().isNotEmpty) {
        addButton = emptyStateButton;
      } else {
        addButton = normalStateButton;
      }
    } else if (config.gameName == 'Tiki Golf') {
      // For Tiki Golf, check which button exists (empty state or normal state)
      final emptyStateButton = ElementFinders.getTikiGolfAddPlayerButtonEmptyState();
      final normalStateButton = ElementFinders.getTikiGolfAddPlayerButton();

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
