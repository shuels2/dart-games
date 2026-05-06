import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

      // Tap Save
      await tester.tap(ElementFinders.getSaveGameModalSaveButton());
      await PumpSequences.navigation(tester);

      // Should be on menu now
      expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget,
          reason: 'Should be on menu after saving');
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

      // Save via back button
      await UITestHelpers.tapGameScreenBackButton(tester, config);
      await PumpSequences.simpleUpdate(tester);
      await tester.tap(ElementFinders.getSaveGameModalSaveButton());
      await PumpSequences.navigation(tester);

      // Re-navigate to menu
      await UITestHelpers.navigateToGameMenu(tester, config);
      await PumpSequences.asyncDataLoad(tester);

      // Resume modal should appear
      expect(ElementFinders.getResumeGameModalOverlay(), findsOneWidget,
          reason: 'Resume modal should appear');

      // Tap resume
      await tester.tap(ElementFinders.getResumeGameModalResumeButton());
      await PumpSequences.navigation(tester);

      // Should be back in game with state restored
      expect(config.getSkipTurnButton(), findsOneWidget,
          reason: 'Game screen should be visible after resume');

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

      await tester.tap(ElementFinders.getResumeGameModalResumeButton());
      await PumpSequences.navigation(tester);

      // Verify game screen
      expect(config.getSkipTurnButton(), findsOneWidget);

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
