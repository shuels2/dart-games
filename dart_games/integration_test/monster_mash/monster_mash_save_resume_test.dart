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

/// Monster Mash - Save & Resume Game UI Tests
///
/// Tests the save game modal (back button) and resume game modal (home screen).
///
/// Run with:
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash/monster_mash_save_resume_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.monsterMash();
  const gameType = 'monster_mash';

  /// Navigate to game screen with 2 players ready to play
  Future<void> navigateToGameScreen(WidgetTester tester) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    await UITestHelpers.addPlayer(tester, 'Alice', config);
    await UITestHelpers.addPlayer(tester, 'Bob', config);
    final players = ProviderHelpers.getAllPlayers(tester);
    await UITestHelpers.selectPlayers(tester, players.map((p) => p.id).toList(), config);
    await UITestHelpers.startGame(tester, config);
  }

  /// Throw one dart on the game screen via emulator
  Future<void> throwOneDart(WidgetTester tester) async {
    final dartButton = config.getDartButton('single', 20);
    await tester.tap(dartButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Pre-populate a saved game in SharedPreferences
  Future<String> preSaveGame() async {
    final metadata = SavedGameMetadata.create(
      gameType: gameType,
      playerNames: ['Alice', 'Bob'],
      progressInfo: 'Round 1',
      gameModeName: 'HP: 20',
      leadingPlayerName: 'Alice',
      leadingPlayerScore: '20 HP',
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
      progressInfo: 'Round 3',
      gameModeName: 'HP: 30 + Bonus Buffs',
      leadingPlayerName: 'Charlie',
      leadingPlayerScore: '30 HP',
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
    testWidgets('tapping game with saved games shows resume modal',
        (tester) async {
      await SettingsHelpers.initializeSettings();
      await preSaveGame();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
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
      await tester.tap(find.byKey(MonsterMashMenuKeys.backButton));
      await PumpSequences.navigation(tester);

      // Tap game card on home
      await tester.tap(config.getGameCard());
      await PumpSequences.asyncDataLoad(tester);

      // Get saved game ID and select it
      final saved = await SaveGameService().loadSavedGames(gameType);
      expect(saved, hasLength(1));
      await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
      await UITestHelpers.tapResumeGameButton(tester);

      // Should be on game screen
      expect(config.getSkipTurnButton(), findsOneWidget);
    });

    testWidgets('Start New Game navigates to menu', (tester) async {
      await SettingsHelpers.initializeSettings();
      await preSaveGame();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.asyncDataLoad(tester);

      await UITestHelpers.tapStartNewGameButton(tester);

      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('delete individual saved game removes it', (tester) async {
      await SettingsHelpers.initializeSettings();
      final ids = await preSaveTwoGames();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
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
      await SettingsHelpers.initializeSettings();
      await preSaveTwoGames();

      await UITestHelpers.navigateToHomeScreen(tester);
      await tester.tap(config.getGameCard());
      await PumpSequences.asyncDataLoad(tester);

      await UITestHelpers.deleteAllSavedGames(tester);

      expect(ElementFinders.getResumeGameModalEmptyState(), findsOneWidget);
    });
  });
}
