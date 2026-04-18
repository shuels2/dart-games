import 'package:flutter/material.dart';
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

/// Target Tag - Save & Resume Game UI Tests
///
/// Tests the save game modal (back button) and resume game modal (menu screen).
///
/// Run with:
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/target_tag/target_tag_save_resume_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.targetTag();
  const gameType = 'target_tag';

  /// Navigate to game screen with 2 players ready to play
  Future<void> navigateToGameScreen(WidgetTester tester) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);
    // Players are auto-selected when added, no need to call selectPlayers
    await UITestHelpers.startGame(tester, config);
  }

  /// Navigate to game screen with low shield max for quick completion
  Future<void> navigateToGameScreenLowShields(WidgetTester tester) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setTargetTagShieldMax(tester, 3);
    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);
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

  /// Pre-populate a saved game via server API
  Future<String> preSaveGame() async {
    final metadata = SavedGameMetadata.create(
      gameType: gameType,
      playerNames: ['Alice', 'Bob'],
      progressInfo: '2 of 2 players remaining',
      gameModeName: 'Solo',
      leadingPlayerName: 'Alice',
      leadingPlayerScore: '5 shields',
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
      playerNames: ['Charlie', 'Diana', 'Eve'],
      progressInfo: '3 of 3 players remaining',
      gameModeName: 'Solo + Hero Bonus',
      leadingPlayerName: 'Charlie',
      leadingPlayerScore: '5 shields',
      gameState: {'_marker': 'test2'},
    );
    await SaveGameService().saveGame(metadata2);
    return [id1, metadata2.id];
  }

  // ==================== SAVE GAME MODAL TESTS ====================

  group('Save Game Modal', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('back button with 0 darts navigates without save modal',
        (tester) async {
      await navigateToGameScreen(tester);

      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await PumpSequences.navigation(tester);

      expect(ElementFinders.getSaveGameModalOverlay(), findsNothing);
      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('back button after darts thrown shows save modal',
        (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);

      await UITestHelpers.tapGameScreenBackButton(tester, config);

      UITestHelpers.verifySaveGameModal();
    });

    testWidgets('Don\'t Save navigates back without saving', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);

      await UITestHelpers.tapDontSaveButton(tester);

      expect(config.getStartButton(), findsOneWidget);
      final hasSaved = await SaveGameService().hasSavedGames(gameType);
      expect(hasSaved, false);
    });

    testWidgets('Save button saves game and navigates back', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);

      await UITestHelpers.tapSaveGameButton(tester);

      expect(config.getStartButton(), findsOneWidget);
      final hasSaved = await SaveGameService().hasSavedGames(gameType);
      expect(hasSaved, true);
    });
  });

  // ==================== RESUME GAME MODAL TESTS ====================

  group('Resume Game Modal', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('tapping game with saved games shows resume modal',
        (tester) async {
      await preSaveGame();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      UITestHelpers.verifyResumeGameModal();
    });

    testWidgets('Resume Game loads game screen', (tester) async {
      // Full roundtrip: navigate → throw → save → home → resume
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Back to home from menu
      await tester.tap(find.byKey(TargetTagMenuKeys.backButton));
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

      // Verify active player name is displayed on screen (visual widget check)
      final activeNameFinder = find.byKey(TargetTagGameKeys.activePlayerName);
      expect(activeNameFinder, findsOneWidget);
      final activeNameText = tester.widget<Text>(activeNameFinder);
      expect(activeNameText.data, isNotNull);

      // Verify players exist in resumed game
      final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
      final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
      expect(alice, isNotNull);
      expect(bob, isNotNull);

      // Verify neither player is eliminated
      expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, alice!.id),
          false);
      expect(
          ProviderHelpers.isTargetTagPlayerEliminated(tester, bob!.id), false);

      // Verify game is active
      expect(ProviderHelpers.isTargetTagGameActive(tester), true);
    });

    testWidgets('Start New Game dismisses modal and shows menu', (tester) async {
      await preSaveGame();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      await UITestHelpers.tapStartNewGameButton(tester);

      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('delete individual saved game removes it', (tester) async {
      final ids = await preSaveTwoGames();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
          findsOneWidget);
      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
          findsOneWidget);

      await UITestHelpers.deleteSavedGameTile(tester, ids[0]);

      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
          findsNothing);
      expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
          findsOneWidget);
    });

    testWidgets('delete all saved games shows empty state', (tester) async {
      await preSaveTwoGames();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      await UITestHelpers.deleteAllSavedGames(tester);

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
      await tester.tap(find.byKey(TargetTagMenuKeys.backButton));
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
      await navigateToGameScreenLowShields(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Back to home from menu
      await tester.tap(find.byKey(TargetTagMenuKeys.backButton));
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

      // Play to completion: 2-player solo, shield_max=3
      // Get dynamic target numbers from provider
      final alice = ProviderHelpers.findPlayerByName(tester, 'Alice')!;
      final bob = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
      final aliceTarget =
          ProviderHelpers.getTargetTagPlayerTarget(tester, alice.id)!;
      final bobTarget =
          ProviderHelpers.getTargetTagPlayerTarget(tester, bob.id)!;

      // Alice has 2 darts remaining (threw S20 before save)
      // Dart 2: Triple own target → 3 shields → TAGGED IN
      await throwDartViaMock(tester, aliceTarget, multiplier: 'triple');
      // Dart 3: miss
      await throwDartViaMock(tester, 1);
      await clickDartsRemoved(tester);
      await PumpSequences.fullRebuild(tester);

      // Bob's turn: Triple own target → TAGGED IN, then miss x2
      await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 1);
      await clickDartsRemoved(tester);
      await PumpSequences.fullRebuild(tester);

      // Alice attacks Bob: 3 singles → shields 3→2→1→0 (vulnerable)
      await throwDartViaMock(tester, bobTarget);
      await throwDartViaMock(tester, bobTarget);
      await throwDartViaMock(tester, bobTarget);
      await clickDartsRemoved(tester);
      await PumpSequences.fullRebuild(tester);

      // Bob misses all 3
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);
      await PumpSequences.fullRebuild(tester);

      // Alice eliminates Bob (0 shields → hit = elimination)
      await throwDartViaMock(tester, bobTarget);
      await PumpSequences.simpleUpdate(tester);
      await clickDartsRemoved(tester);

      // Wait for results screen
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify results screen
      expect(config.getPlayAgainButton(), findsOneWidget);

      // Verify saved game was auto-deleted
      final remaining = await SaveGameService().loadSavedGames(gameType);
      expect(remaining, isEmpty);
    });
  });

  // ==================== RESUME GAME BUTTON TESTS ====================

  group('Resume Game Button', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('button is disabled when no saved games exist', (tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Find the resume button
      final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
      expect(resumeButton, findsOneWidget);

      // Find the IconButton within ResumeGameButton
      final iconButtonFinder = find.descendant(
        of: resumeButton,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinder);

      // Verify button is disabled (IconButton with null onPressed)
      expect(iconButton.onPressed, isNull);

      // Verify tooltip shows "No saved games"
      expect(iconButton.tooltip, 'No saved games');
    });

    testWidgets('button becomes enabled after saving a game', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Now on menu screen, find the resume button
      final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
      expect(resumeButton, findsOneWidget);

      // Find the IconButton within ResumeGameButton
      final iconButtonFinder = find.descendant(
        of: resumeButton,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinder);

      // Verify button is enabled (IconButton with non-null onPressed)
      expect(iconButton.onPressed, isNotNull);

      // Verify tooltip shows "Resume saved game"
      expect(iconButton.tooltip, 'Resume saved game');
    });

    testWidgets('clicking button shows resume modal', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Click the resume button
      final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
      await tester.tap(resumeButton);
      await PumpSequences.asyncDataLoad(tester);

      // Verify resume modal is shown
      UITestHelpers.verifyResumeGameModal();
    });

    testWidgets('button is visible with correct color when enabled',
        (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Find the resume button and its IconButton
      final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
      final iconButtonFinder = find.descendant(
        of: resumeButton,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinder);

      // Verify color is white (Target Tag theme)
      expect(iconButton.color, Colors.white);

      // Verify icon is history icon
      final icon = iconButton.icon as Icon;
      expect(icon.icon, Icons.history);
    });

    testWidgets('button stays hidden when modal is not shown after resume',
        (tester) async {
      // Save a game
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Click resume button to show modal
      final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
      await tester.tap(resumeButton);
      await PumpSequences.asyncDataLoad(tester);

      // Resume the game
      final saved = await SaveGameService().loadSavedGames(gameType);
      await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
      await UITestHelpers.tapResumeGameButton(tester);

      // Verify game screen loaded
      expect(config.getSkipTurnButton(), findsOneWidget);

      // Throw another dart and save again
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      // Verify we're back on menu screen
      expect(config.getStartButton(), findsOneWidget);

      // Verify resume modal is NOT automatically shown
      expect(ElementFinders.getResumeGameModalOverlay(), findsNothing);

      // Verify resume button is still enabled
      final resumeButtonAfter = find.byKey(TargetTagMenuKeys.resumeGameButton);
      final iconButtonFinderAfter = find.descendant(
        of: resumeButtonAfter,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinderAfter);
      expect(iconButton.onPressed, isNotNull);
    });
  });
}
