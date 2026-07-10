// integration_test/treasure_divide/save_resume/resume_auto_deletes_on_completion_test.dart
//
// SaveResume-16 — Resumed game auto-deletes the saved record on results screen.
//                 Uses in-game Save flow (Rule §17) + canonical completion driver.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game auto-deletes saved game on completion',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Step 1: Start game (7 rounds for speed), throw 1 dart, save
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Step 2: Go back to home from menu
    await tester.tap(find.byKey(TreasureDivideMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Step 3: Tap game card → auto-popup
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Step 4: Select saved game and resume
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final savedGameId = saved[0].id;
    await UITestHelpers.selectSavedGameTile(tester, savedGameId);
    await UITestHelpers.tapResumeGameButton(tester);

    expect(config.getSkipTurnButton(), findsOneWidget);

    // Step 5: Drive game to completion using canonical TD completion driver.
    //         P1 (Alice) hits target all 3 darts; P2 (Bob) misses all 3.
    //         simulateTakeoutFinished() is used instead of UI button.
    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    final p1Id = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);

    int turnCount = 0;
    while (!provider.hasWinner) {
      final currentId =
          ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);
      final isP1Turn = (currentId == p1Id);
      final roundIndex =
          ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);

      if (isP1Turn) {
        // Hit target 3 times
        for (var i = 0; i < 3; i++) {
          if (target == -1) {
            await throwDartViaMock(tester, 1, multiplier: 'double');
          } else if (target == -2) {
            await throwDartViaMock(tester, 1, multiplier: 'triple');
          } else {
            await throwDartViaMock(tester, target);
          }
        }
      } else {
        // Miss all 3
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
      }

      // Simulate takeout
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      if (provider.shouldPromptTakeout) {
        final mockApi = getMockApi(tester);
        mockApi?.simulateTakeoutFinished();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      turnCount++;
      if (turnCount > 40) break; // Safety bound
    }

    await ResultsHelpers.pumpUntilResults(tester, config);

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Verify saved game was auto-deleted
    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty);
  });
}
