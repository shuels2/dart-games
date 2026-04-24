import 'package:flutter/material.dart';
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
    // Full roundtrip: navigate -> throw -> save -> home -> resume -> complete
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
}
