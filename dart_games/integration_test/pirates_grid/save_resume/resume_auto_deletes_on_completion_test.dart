import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game auto-deletes saved game on completion',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Full roundtrip: navigate -> throw -> save -> home -> resume -> complete.
    // Uses in-game save flow because preSaveGame's placeholder gameState
    // (`{'_marker': 'test'}`) causes PiratesGridGame.fromJson to crash on
    // restore (`json['grid'] as List` throws on the placeholder value).
    await setupAndStartGame(tester, config,
        playerNames: ['Alice', 'Bob']);
    final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    await throwDartViaMock(tester, t00);

    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.simpleUpdate(tester);
    final saveButton = ElementFinders.getSaveGameModalSaveButton();
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await PumpSequences.navigation(tester);

    // Look up the savedId we just created
    final savedGames = await SaveGameService().loadSavedGames(gameType);
    expect(savedGames.length, greaterThanOrEqualTo(1),
        reason: 'Should have at least one saved game after Save tap');
    final savedId = savedGames.first.id;

    // Back to home from menu
    await tester.tap(find.byKey(PiratesGridMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home â€” navigates to menu screen
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Select the saved-game tile and resume
    await UITestHelpers.selectSavedGameTile(tester, savedId);

    final resumeButton = ElementFinders.getResumeGameModalResumeButton();
    await tester.ensureVisible(resumeButton);
    await tester.pump();
    await tester.tap(resumeButton);
    await PumpSequences.navigation(tester);
    await PumpSequences.fullRebuild(tester);

    // Verify game screen loaded
    expect(config.getSkipTurnButton(), findsOneWidget,
        reason: 'Game screen should be visible after resume');

    // Verify the provider tracks the savedId for auto-deletion on completion
    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    expect(provider.resumedSavedGameId, savedId,
        reason: 'Resumed game should track the saved game ID');

    // Play to completion using the dartboard emulator play-to-complete button
    await PlayToCompleteHelpers.tapPlayToComplete(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible after completion');

    // Verify saved game was auto-deleted on completion
    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty,
        reason: 'Saved game should be auto-deleted when resumed game completes');
  });
}
