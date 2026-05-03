import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Resume: re-saving an already-saved game overwrites (not duplicates)',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Full roundtrip — start a real game and save it. The stub-state pattern
    // (preSaveGame) only works for tests that DON'T trigger restoreGame. Here
    // we resume + re-save, which requires real game state.
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

    // Throw another dart, then save again (back button → save)
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    UITestHelpers.verifySaveGameModal();
    await UITestHelpers.tapSaveGameButton(tester);

    // Should still be only 1 saved game (overwrote, not duplicated)
    final savedAfter = await SaveGameService().loadSavedGames(gameType);
    expect(savedAfter, hasLength(1),
        reason: 'Re-saving should overwrite existing save, not create a duplicate');
  });
}
