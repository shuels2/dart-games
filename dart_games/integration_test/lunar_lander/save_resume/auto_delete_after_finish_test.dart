import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Resume: saved game is auto-deleted after game completes',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Full roundtrip — start a real game and save it. The stub-state pattern
    // (preSaveGame) only works for tests that DON'T trigger restoreGame. Here
    // we resume + complete, which requires real game state.
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Back to home from menu
    await tester.tap(find.byKey(LunarLanderMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home — navigates to menu screen
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    // Resume the saved game
    final savedBefore = await SaveGameService().loadSavedGames(gameType);
    expect(savedBefore, hasLength(1));
    await UITestHelpers.selectSavedGameTile(tester, savedBefore[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Complete the game by throwing darts until win.
    // (After resume, throw triple-20s and miss away the rest until landing.)
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

    // Trigger the victory flow: the loop exits with hasWinner=true BEFORE
    // calling clickDartsRemoved on the winning dart, so _handleGameWon
    // (which navigates to results AND auto-deletes the saved game) has not
    // fired yet. Tap DARTS REMOVED to dispatch takeout_finished, which
    // chains into the victory + cleanup flow.
    await clickDartsRemoved(tester);

    // Allow the auto-navigate-on-win + addPostFrameCallback chains to complete
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // After game completes, the save should be auto-deleted
    final savedAfter = await SaveGameService().loadSavedGames(gameType);
    expect(savedAfter, isEmpty,
        reason: 'Saved game should be auto-deleted after game completion');
  });
}
