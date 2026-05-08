import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game auto-deletes saved game on completion',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Full roundtrip: navigate -> throw -> save -> home -> resume -> complete.
    // Uses in-game save flow because preSaveGame's placeholder gameState
    // (`{'_marker': 'test'}`) causes LunarLanderGame.fromJson to crash on
    // restore (required fields like 'starting_altitude' are absent).
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Look up the savedId we just created
    final savedBefore = await SaveGameService().loadSavedGames(gameType);
    expect(savedBefore, hasLength(1));

    // Back to home from menu
    await tester.tap(find.byKey(LunarLanderMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home — navigates to menu screen
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    // Resume the saved game
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Verify the provider tracks the savedId for auto-deletion on completion
    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    expect(provider.resumedSavedGameId, saved[0].id,
        reason: 'Resumed game should track the saved game ID');

    // Play to completion: throw triple-20s until altitude reaches 0.
    // Alice has 2 remaining darts in current turn (1 was already thrown).
    // After clickDartsRemoved, turns alternate. Continue until hasWinner.
    for (int i = 0; i < 30; i++) {
      if (!ProviderHelpers.isLunarLanderGameActive(tester)) break;
      if (ProviderHelpers.lunarLanderHasWinner(tester)) break;
      await throwDartViaMock(tester, 20, multiplier: 'triple');
      if (ProviderHelpers.lunarLanderHasWinner(tester)) break;
      if (ProviderHelpers.getLunarLanderProvider(tester).shouldPromptTakeout) {
        await clickDartsRemoved(tester);
        if (ProviderHelpers.lunarLanderHasWinner(tester)) break;
        await completeTurnWithMisses(tester);
      }
    }

    // Trigger the victory flow: dispatch takeout_finished to chain into
    // the victory + auto-delete flow.
    await clickDartsRemoved(tester);

    // Allow the auto-navigate-on-win + addPostFrameCallback chains to complete
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible after completion');

    // Verify saved game was auto-deleted on completion
    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty,
        reason:
            'Saved game should be auto-deleted when resumed game completes');
  });
}
