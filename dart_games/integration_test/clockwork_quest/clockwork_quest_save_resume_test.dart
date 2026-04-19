import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/pump_sequences.dart';

/// Clockwork Quest - Save & Resume Game UI Tests
///
/// Tests the save game modal (back button) and resume game modal (menu screen).
///
/// Run with:
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/clockwork_quest/clockwork_quest_save_resume_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();
  const gameType = 'clockwork_quest';

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
        score: 1,
        multiplier: 'single',
        playerName: 'Player',
        baseScore: 1,
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

  /// Click DARTS REMOVED button on emulator
  Future<void> clickDartsRemoved(WidgetTester tester) async {
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Throw a miss (score 0) via mock API
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

  /// Complete a full turn with 3 misses and click darts removed
  Future<void> completeTurnWithMisses(WidgetTester tester) async {
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);
  }

  /// Pre-populate a saved game via server API
  Future<String> preSaveGame() async {
    final metadata = SavedGameMetadata.create(
      gameType: gameType,
      playerNames: ['Alice', 'Bob'],
      progressInfo: 'Gear 1',
      gameModeName: 'Standard',
      leadingPlayerName: 'Alice',
      leadingPlayerScore: 'Gear 1',
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
      progressInfo: 'Gear 5',
      gameModeName: 'Bullseye + Speed Mode',
      leadingPlayerName: 'Charlie',
      leadingPlayerScore: 'Gear 5',
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
      await UITestHelpers.navigateToHomeScreen(tester);
      await preSaveGame();
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
      await tester.tap(find.byKey(ClockworkQuestMenuKeys.backButton));
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

      // Verify game state: 1 dart was thrown before save
      expect(
          ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester), 1);

      // Verify game is active
      expect(ProviderHelpers.isClockworkQuestGameActive(tester), true);
    });

    testWidgets('Start New Game dismisses modal and shows menu', (tester) async {
      await UITestHelpers.navigateToHomeScreen(tester);
      await preSaveGame();
      await tester.tap(config.getGameCard());
      await PumpSequences.navigation(tester);
      await PumpSequences.asyncDataLoad(tester);

      await UITestHelpers.tapStartNewGameButton(tester);

      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('delete individual saved game removes it', (tester) async {
      await UITestHelpers.navigateToHomeScreen(tester);
      final ids = await preSaveTwoGames();
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
      await UITestHelpers.navigateToHomeScreen(tester);
      await preSaveTwoGames();
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
      await tester.tap(find.byKey(ClockworkQuestMenuKeys.backButton));
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
      await tester.tap(find.byKey(ClockworkQuestMenuKeys.backButton));
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

      // Play to completion: Alice has advanced from 1 to 2 (1 dart thrown)
      // Need to reach target 20 and hit it to win

      // Alice's remaining 2 darts: advance to 3 and 4
      await throwDartViaMock(tester, 2); // advance to 3
      await throwDartViaMock(tester, 3); // advance to 4
      await clickDartsRemoved(tester);

      // Bob's turn: miss all
      await completeTurnWithMisses(tester);

      // Alice hits targets in groups of 3, with Bob missing between
      for (int startTarget = 4; startTarget <= 20; startTarget += 3) {
        for (int t = startTarget; t < startTarget + 3 && t <= 20; t++) {
          await throwDartViaMock(tester, t);
        }
        // Fill remaining darts with misses if fewer than 3 targets hit
        final targetsHit =
            (startTarget + 2 <= 20) ? 3 : (20 - startTarget + 1);
        for (int i = targetsHit; i < 3; i++) {
          await throwMissViaMock(tester);
        }
        await clickDartsRemoved(tester);

        // Check if game is over (Alice won after hitting target 20)
        if (ProviderHelpers.clockworkQuestHasWinner(tester)) break;

        // Bob's turn: miss all
        await completeTurnWithMisses(tester);
      }

      // Wait for results screen navigation
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();
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

      final resumeButton = find.byKey(ClockworkQuestMenuKeys.resumeGameButton);
      expect(resumeButton, findsOneWidget);

      final iconButtonFinder = find.descendant(
        of: resumeButton,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNull);
      expect(iconButton.tooltip, 'No saved games');
    });

    testWidgets('button becomes enabled after saving a game', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      final resumeButton = find.byKey(ClockworkQuestMenuKeys.resumeGameButton);
      expect(resumeButton, findsOneWidget);

      final iconButtonFinder = find.descendant(
        of: resumeButton,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNotNull);
      expect(iconButton.tooltip, 'Resume saved game');
    });

    testWidgets('clicking button shows resume modal', (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      final resumeButton = find.byKey(ClockworkQuestMenuKeys.resumeGameButton);
      await tester.tap(resumeButton);
      await PumpSequences.asyncDataLoad(tester);

      UITestHelpers.verifyResumeGameModal();
    });

    testWidgets('button is visible with correct color when enabled',
        (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      final resumeButton = find.byKey(ClockworkQuestMenuKeys.resumeGameButton);
      final iconButtonFinder = find.descendant(
        of: resumeButton,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinder);

      // Verify color is Steam White
      expect(iconButton.color, const Color(0xFFF5F0E8));

      final icon = iconButton.icon as Icon;
      expect(icon.icon, Icons.history);
    });

    testWidgets('button stays hidden when modal is not shown after resume',
        (tester) async {
      await navigateToGameScreen(tester);
      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      final resumeButton = find.byKey(ClockworkQuestMenuKeys.resumeGameButton);
      await tester.tap(resumeButton);
      await PumpSequences.asyncDataLoad(tester);

      final saved = await SaveGameService().loadSavedGames(gameType);
      await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
      await UITestHelpers.tapResumeGameButton(tester);

      expect(config.getSkipTurnButton(), findsOneWidget);

      await throwOneDart(tester);
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await UITestHelpers.tapSaveGameButton(tester);

      expect(config.getStartButton(), findsOneWidget);
      expect(ElementFinders.getResumeGameModalOverlay(), findsNothing);

      final resumeButtonAfter = find.byKey(ClockworkQuestMenuKeys.resumeGameButton);
      final iconButtonFinderAfter = find.descendant(
        of: resumeButtonAfter,
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(iconButtonFinderAfter);
      expect(iconButton.onPressed, isNotNull);
    });
  });
}
