import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/pump_sequences.dart';

/// Carnival Derby - Save & Resume Game UI Tests
///
/// Tests the save game modal (back button) and resume game modal (menu screen).
///
/// Run with:
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/carnival_derby/carnival_derby_save_resume_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.carnivalDerby();
  const gameType = 'carnival_derby';

  /// Navigate to game screen with 2 players ready to play
  Future<void> navigateToGameScreen(WidgetTester tester) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);
    // Players are auto-selected when added, no need to call selectPlayers
    await UITestHelpers.startGame(tester, config);
  }

  /// Throw one dart on the game screen via mock API
  Future<void> throwOneDart(WidgetTester tester) async {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    final mockApi = dartboardProvider.apiService;
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: 20,
        multiplier: 'single',
        playerName: 'Player',
        baseScore: 20,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Throw a dart at a specific number via mock API
  Future<void> throwDartViaMock(WidgetTester tester, int number,
      {String multiplier = 'single'}) async {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    final mockApi = dartboardProvider.apiService;
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: number *
            (multiplier == 'double'
                ? 2
                : multiplier == 'triple'
                    ? 3
                    : 1),
        multiplier: multiplier,
        playerName: 'Player',
        baseScore: number,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Throw a miss via mock API
  Future<void> throwMissViaMock(WidgetTester tester) async {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    final mockApi = dartboardProvider.apiService;
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: 0,
        multiplier: 'single',
        playerName: 'Player',
        baseScore: 0,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Click DARTS REMOVED button on emulator
  Future<void> clickDartsRemoved(WidgetTester tester) async {
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Pre-populate a saved game in SharedPreferences (for resume modal tests)
  Future<String> preSaveGame() async {
    final metadata = SavedGameMetadata.create(
      gameType: gameType,
      playerNames: ['Alice', 'Bob'],
      progressInfo: 'Leading: 20 pts',
      gameModeName: 'Target: 200',
      leadingPlayerName: 'Alice',
      leadingPlayerScore: '20 pts',
      gameState: {'_marker': 'test'},
    );
    await SaveGameService().saveGame(metadata);
    return metadata.id;
  }

  /// Pre-populate two saved games
  Future<List<String>> preSaveTwoGames() async {
    final id1 = await preSaveGame();
    final metadata2 = SavedGameMetadata.create(
      gameType: gameType,
      playerNames: ['Charlie', 'Diana'],
      progressInfo: 'Leading: 40 pts',
      gameModeName: 'Target: 300',
      leadingPlayerName: 'Charlie',
      leadingPlayerScore: '40 pts',
      gameState: {'_marker': 'test2'},
    );
    await SaveGameService().saveGame(metadata2);
    return [id1, metadata2.id];
  }

  // ==================== SAVE GAME MODAL TESTS ====================

  group('Save Game Modal', () {
    testWidgets('back button with 0 darts navigates without save modal',
        (tester) async {
      await navigateToGameScreen(tester);

      // Tap back with 0 darts thrown
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await PumpSequences.navigation(tester);

      // Should navigate back to menu without showing save modal
      expect(ElementFinders.getSaveGameModalOverlay(), findsNothing);
      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('back button after darts thrown shows save modal',
        (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);

      // Tap back with darts thrown
      await UITestHelpers.tapGameScreenBackButton(tester, config);

      // Save modal should appear
      UITestHelpers.verifySaveGameModal();
    });

    testWidgets('Don\'t Save navigates back without saving', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);

      // Tap Don't Save
      await UITestHelpers.tapDontSaveButton(tester);

      // Should be back on menu
      expect(config.getStartButton(), findsOneWidget);

      // No saved game should exist
      final hasSaved = await SaveGameService().hasSavedGames(gameType);
      expect(hasSaved, false);
    });

    testWidgets('Save button saves game and navigates back', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);

      // Tap Save
      await UITestHelpers.tapSaveGameButton(tester);

      // Should be back on menu
      expect(config.getStartButton(), findsOneWidget);

      // Saved game should exist
      final hasSaved = await SaveGameService().hasSavedGames(gameType);
      expect(hasSaved, true);
    });
  });

  // ==================== RESUME GAME MODAL TESTS ====================

  group('Resume Game Modal', () {
    testWidgets('tapping game with saved games shows resume modal',
        (tester) async {
      await SettingsHelpers.initializeSettings();
      await preSaveGame();

      await UITestHelpers.navigateToHomeScreen(tester);

      // Tap game card — navigates to menu screen
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Resume modal should appear
      UITestHelpers.verifyResumeGameModal();
    });

    testWidgets('Resume Game loads game screen', (tester) async {
      // Full roundtrip: navigate → throw → save → home → resume
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Back to home from menu
      await tester.tap(find.byKey(CarnivalDerbyMenuKeys.backButton));
      await PumpSequences.navigation(tester);

      // Tap game card on home — navigates to menu screen
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Get saved game ID and select it
      final saved = await SaveGameService().loadSavedGames(gameType);
      expect(saved, hasLength(1));
      await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
      await UITestHelpers.tapResumeGameButton(tester);

      // Verify game screen loaded
      expect(config.getSkipTurnButton(), findsOneWidget);

      // Verify players exist in resumed game
      final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
      final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
      expect(alice, isNotNull);
      expect(bob, isNotNull);

      // Verify restored game state: Alice threw single-20, score should be 20
      expect(
          ProviderHelpers.getCarnivalDerbyPlayerScore(tester, alice!.id), 20);
      expect(ProviderHelpers.getCarnivalDerbyPlayerScore(tester, bob!.id), 0);

      // Verify it's still Alice's turn (only 1 of 3 darts thrown)
      expect(
          ProviderHelpers.getCarnivalDerbyCurrentPlayerId(tester), alice.id);

      // Verify game is active
      expect(ProviderHelpers.isCarnivalDerbyGameActive(tester), true);
    });

    testWidgets('Start New Game dismisses modal and shows menu', (tester) async {
      await SettingsHelpers.initializeSettings();
      await preSaveGame();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      await UITestHelpers.tapStartNewGameButton(tester);

      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('delete individual saved game removes it', (tester) async {
      await SettingsHelpers.initializeSettings();
      final ids = await preSaveTwoGames();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Both tiles should exist
      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
          findsOneWidget);
      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
          findsOneWidget);

      // Delete first saved game
      await UITestHelpers.deleteSavedGameTile(tester, ids[0]);

      // First tile should be gone, second should remain
      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
          findsNothing);
      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
          findsOneWidget);
    });

    testWidgets('delete all saved games shows empty state', (tester) async {
      await SettingsHelpers.initializeSettings();
      await preSaveTwoGames();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Delete all
      await UITestHelpers.deleteAllSavedGames(tester);

      // Empty state should show
      expect(ElementFinders.getResumeGameModalEmptyState(), findsOneWidget);
    });

    testWidgets('resumed game re-save overwrites instead of duplicating',
        (tester) async {
      // Full roundtrip: navigate → throw → save → home → resume → throw → save again
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Verify 1 saved game
      var saved = await SaveGameService().loadSavedGames(gameType);
      expect(saved, hasLength(1));
      final originalId = saved[0].id;

      // Back to home from menu
      await tester.tap(find.byKey(CarnivalDerbyMenuKeys.backButton));
      await PumpSequences.navigation(tester);

      // Tap game card on home — navigates to menu screen
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Select saved game and resume
      saved = await SaveGameService().loadSavedGames(gameType);
      await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
      await UITestHelpers.tapResumeGameButton(tester);

      // Throw another dart in resumed game
      await throwOneDart(tester);

      // Save again via back button
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Should still be 1 saved game (overwritten, not duplicated)
      saved = await SaveGameService().loadSavedGames(gameType);
      expect(saved, hasLength(1));
      expect(saved[0].id, originalId);
    });

    testWidgets('resumed game auto-deletes saved game on completion',
        (tester) async {
      // Full roundtrip: navigate → throw → save → home → resume → complete
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Back to home from menu
      await tester.tap(find.byKey(CarnivalDerbyMenuKeys.backButton));
      await PumpSequences.navigation(tester);

      // Tap game card on home — navigates to menu screen
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      // Get saved game ID and select it
      final saved = await SaveGameService().loadSavedGames(gameType);
      expect(saved, hasLength(1));
      final savedGameId = saved[0].id;
      await UITestHelpers.selectSavedGameTile(tester, savedGameId);
      await UITestHelpers.tapResumeGameButton(tester);

      // Play to completion: Alice has 20 pts, 1/3 darts, target=150
      // Remaining 2 darts this turn
      await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 → total 80
      await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60 → total 140
      await clickDartsRemoved(tester);

      // Bob's turn: miss all 3
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Alice's turn: S20 → total 160 ≥ 150 = wins!
      await throwDartViaMock(tester, 20);
      await clickDartsRemoved(tester);

      // Wait for results screen
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump();

      // Verify results screen
      expect(config.getPlayAgainButton(), findsOneWidget);

      // Verify saved game was auto-deleted
      final remaining = await SaveGameService().loadSavedGames(gameType);
      expect(remaining, isEmpty);
    });
  });
}
