import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid - Save and Resume", () {
    testWidgets('Save/Resume: save modal appears when pressing back with darts thrown',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config);

      // Throw 1 dart to have unsaved state
      await throwDartViaMock(tester, 1);

      // Tap game back button — save modal should appear
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await PumpSequences.simpleUpdate(tester);

      expect(ElementFinders.getSaveGameModalContainer(), findsOneWidget,
          reason: 'Save modal should appear when back pressed with darts thrown');
    });

    testWidgets('Save/Resume: save creates entry and navigates back to menu',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config);

      // Throw 1 dart
      await throwDartViaMock(tester, 1);

      // Tap back → save modal
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await PumpSequences.simpleUpdate(tester);

      // Tap Save — ensureVisible because headless chromedriver requires the
      // target in the viewport for the click to register.
      final saveButton = ElementFinders.getSaveGameModalSaveButton();
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await PumpSequences.navigation(tester);
      await PumpSequences.fullRebuild(tester);

      // Should be on menu now — inline diagnostic in reason string
      final diag = '[DIAG after-Save '
          'menuStart=${ElementFinders.getPiratesGridStartButton().evaluate().length} '
          'gameSkip=${ElementFinders.getPiratesGridSkipTurnButton().evaluate().length} '
          'homeCarnival=${ElementFinders.getCarnivalDerbyCard().evaluate().length} '
          'saveModal=${ElementFinders.getSaveGameModalContainer().evaluate().length} '
          'resumeModal=${ElementFinders.getResumeGameModalOverlay().evaluate().length}]';
      expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget,
          reason: 'Should be on menu after saving. $diag');
    });

    testWidgets('Save/Resume: resume modal appears on menu when saved games exist',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();

      // Pre-save a game
      await SaveResumeHelpers.preSaveGame(GameSaveConfig.piratesGrid());

      // Navigate to menu
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Resume modal should appear
      await PumpSequences.asyncDataLoad(tester);
      expect(ElementFinders.getResumeGameModalOverlay(), findsOneWidget,
          reason: 'Resume modal should appear when saved games exist');
    });

    testWidgets('Save/Resume: resume game restores full game state',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await setupAndStartGame(tester, config,
          playerNames: ['Alice', 'Bob']);

      // Throw a dart to plant a flag at cell [0,0] (get a real game state)
      final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
      await throwDartViaMock(tester, t00);

      // Save via back button. ensureVisible because headless chromedriver
      // requires the target in the viewport for the click to register.
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await PumpSequences.simpleUpdate(tester);
      final saveButton2 = ElementFinders.getSaveGameModalSaveButton();
      await tester.ensureVisible(saveButton2);
      await tester.pump();
      await tester.tap(saveButton2);
      await PumpSequences.navigation(tester);

      // Re-navigate to menu
      await UITestHelpers.navigateToGameMenu(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Resume modal should appear
      expect(ElementFinders.getResumeGameModalOverlay(), findsOneWidget,
          reason: 'Resume modal should appear');

      // Select the saved-game tile FIRST — the Resume button stays disabled
      // until a tile is selected (`onPressed: hasSelection ? ... : null`).
      // We don't have the savedId in this sub-test (it was created via the
      // Save modal, not preSaveGame), so look it up from the service.
      final savedGames = await SaveGameService().loadSavedGames('pirates_grid');
      expect(savedGames.length, greaterThanOrEqualTo(1),
          reason: 'Should have at least one saved game after Save tap');
      await UITestHelpers.selectSavedGameTile(tester, savedGames.first.id);

      // Tap resume — ensureVisible because headless chromedriver requires the
      // target in the viewport for the click to register.
      final resumeButton = ElementFinders.getResumeGameModalResumeButton();
      await tester.ensureVisible(resumeButton);
      await tester.pump();
      await tester.tap(resumeButton);
      await PumpSequences.navigation(tester);
      await PumpSequences.fullRebuild(tester);

      // Should be back in game with state restored — inline diagnostic
      final diag = '[DIAG after-Resume '
          'menuStart=${ElementFinders.getPiratesGridStartButton().evaluate().length} '
          'gameSkip=${ElementFinders.getPiratesGridSkipTurnButton().evaluate().length} '
          'gameBack=${ElementFinders.getPiratesGridGameBackButton().evaluate().length} '
          'resumeModal=${ElementFinders.getResumeGameModalOverlay().evaluate().length}]';
      expect(config.getSkipTurnButton(), findsOneWidget,
          reason: 'Game screen should be visible after resume. $diag');

      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      expect(provider.isGameActive, isTrue,
          reason: 'Game should be active after resume');
      // P1 (Alice) should have 1 flag (from cell [0,0] throw before save)
      final p1Id = provider.currentGame!.playerIds[0];
      expect(provider.currentGame!.getFlagsPlanted(p1Id), 1,
          reason: 'P1 should have 1 flag after resume (state restored)');
    });

    testWidgets('Save/Resume: resumed game auto-deletes save on completion',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();

      // Pre-save a game
      final savedId = await SaveResumeHelpers.preSaveGame(
          GameSaveConfig.piratesGrid());

      // Navigate to menu and resume
      await UITestHelpers.navigateToGameMenu(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Select the saved-game tile FIRST — the Resume button stays disabled
      // until a tile is selected.
      await UITestHelpers.selectSavedGameTile(tester, savedId);

      // ensureVisible — headless chromedriver requires the target in the
      // viewport for the click to register.
      final resumeButton = ElementFinders.getResumeGameModalResumeButton();
      await tester.ensureVisible(resumeButton);
      await tester.pump();
      await tester.tap(resumeButton);
      await PumpSequences.navigation(tester);
      await PumpSequences.fullRebuild(tester);

      // Verify game screen — inline diagnostic in reason string
      final diag2 = '[DIAG after-Resume-2 '
          'menuStart=${ElementFinders.getPiratesGridStartButton().evaluate().length} '
          'gameSkip=${ElementFinders.getPiratesGridSkipTurnButton().evaluate().length} '
          'gameBack=${ElementFinders.getPiratesGridGameBackButton().evaluate().length} '
          'resumeModal=${ElementFinders.getResumeGameModalOverlay().evaluate().length}]';
      expect(config.getSkipTurnButton(), findsOneWidget, reason: diag2);

      // Complete the game — save should be deleted on completion
      // (The resumed game tracks the saved ID and auto-deletes it)
      final provider = ProviderHelpers.getPiratesGridProvider(tester);
      expect(provider.resumedSavedGameId, savedId,
          reason: 'Resumed game should track the saved game ID');
    });

    testWidgets('Save/Resume: resume button enable/disable state',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();

      // No saved games — navigate to menu
      await UITestHelpers.navigateToGameMenu(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Resume modal should NOT appear (no saved games)
      expect(ElementFinders.getResumeGameModalOverlay(), findsNothing,
          reason: 'Resume modal should not appear without saved games');

      // Pre-save a game
      await SaveResumeHelpers.preSaveGame(GameSaveConfig.piratesGrid());

      // Navigate back to menu
      await UITestHelpers.navigateToGameMenu(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Resume modal should now appear
      expect(ElementFinders.getResumeGameModalOverlay(), findsOneWidget,
          reason: 'Resume modal should appear with saved game');
    });
  });
}
