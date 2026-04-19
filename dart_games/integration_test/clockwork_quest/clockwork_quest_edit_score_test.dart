import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/edit_score_helpers.dart';

// ==========================================================================
// HELPER METHODS
// ==========================================================================

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
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

Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
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

Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  bool speedMode = false,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (includeBullseye) {
    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
  }
  if (speedMode) {
    await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
  }

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

/// Throw 3 darts to trigger takeout prompt (where edit score button appears)
Future<void> throw3DartsAndWaitForTakeout(WidgetTester tester,
    {int target1 = 0, int target2 = 0, int target3 = 0}) async {
  if (target1 > 0) {
    await throwDartViaMock(tester, target1);
  } else {
    await throwMissViaMock(tester);
  }
  if (target2 > 0) {
    await throwDartViaMock(tester, target2);
  } else {
    await throwMissViaMock(tester);
  }
  if (target3 > 0) {
    await throwDartViaMock(tester, target3);
  } else {
    await throwMissViaMock(tester);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Edit Score Tests', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    // ================================================================
    // EDIT SCORE BUTTON VISIBILITY
    // ================================================================

    testWidgets('Test 1: Edit score button appears after 3 darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // Throw 3 darts (hits on targets 1, 2, 3)
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      // Edit score button should be visible in the takeout prompt
      final editButton = config.getEditScoreButton();
      expect(editButton, findsOneWidget);
    });

    testWidgets('Test 2: Edit score button not visible before 3 darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // Throw only 2 darts
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);

      // Edit score button should NOT be visible yet
      final editButton = config.getEditScoreButton();
      expect(editButton, findsNothing);
    });

    // ================================================================
    // EDIT SCORE DIALOG
    // ================================================================

    testWidgets('Test 3: Edit score dialog opens with all elements',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throw3DartsAndWaitForTakeout(tester, target1: 1, target2: 2, target3: 3);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Verify dialog has all elements
      EditScoreHelpers.verifyDialogElements();
    });

    testWidgets('Test 4: Cancel edit score closes dialog',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throw3DartsAndWaitForTakeout(tester, target1: 1, target2: 2, target3: 3);

      await EditScoreHelpers.openEditScore(tester, config);
      await EditScoreHelpers.cancelEditScore(tester);

      // Dialog should be closed
      EditScoreHelpers.verifyDialogClosed();
    });

    // ================================================================
    // EDIT SCORE PRESERVES/CHANGES TARGET
    // ================================================================

    testWidgets('Test 5: Cancel edit score preserves target progression',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

      // Throw 3 hits (advance from target 1 to target 4)
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      final targetAfterHits =
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId);
      expect(targetAfterHits, 4, reason: 'Should have advanced to target 4');

      // Open and cancel edit score
      await EditScoreHelpers.editScoreAndCancel(tester, config);

      // Target should be unchanged
      expect(
        ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId),
        targetAfterHits,
      );
    });

    testWidgets('Test 6: Edit score changes misses to hits',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

      // Throw 3 misses - no advancement
      await throw3DartsAndWaitForTakeout(tester);

      // Should still be at target 1
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);

      // Edit: change dart 1 from Miss to S1 (single 1)
      await EditScoreHelpers.editScoreAndSave(
        tester, config,
        dart1: 'S1',
      );

      // Target should now be 2 (advanced by hitting target 1)
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 2);
    });

    testWidgets('Test 7: Edit score changes hits to misses',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

      // Throw 3 hits (targets 1, 2, 3 -> advance to target 4)
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 4);

      // Edit: change all darts to misses
      await EditScoreHelpers.editScoreAndSave(
        tester, config,
        dart1: 'Miss',
        dart2: 'Miss',
        dart3: 'Miss',
      );

      // Target should be back to 1 (no hits)
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);
    });

    testWidgets('Test 8: Edit score with partial changes',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

      // Throw 3 misses
      await throw3DartsAndWaitForTakeout(tester);
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);

      // Edit: change dart 1 and dart 2 to hits (S1, S2), leave dart 3 as miss
      await EditScoreHelpers.editScoreAndSave(
        tester, config,
        dart1: 'S1',
        dart2: 'S2',
      );

      // Target should be 3 (hit 1 and 2)
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 3);
    });

    // ================================================================
    // EDIT SCORE — SPEED MODE
    // ================================================================

    testWidgets('Test 9: Edit score in speed mode changes completed gears',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);

      // Hit gears 5, 10, 15 (speed mode: any order counts)
      await throwDartViaMock(tester, 5);
      await throwDartViaMock(tester, 10);
      await throwDartViaMock(tester, 15);

      expect(provider.getPlayerCompletedTargets(playerId), containsAll([5, 10, 15]));

      // Edit: change dart 2 from S10 to Miss
      await EditScoreHelpers.editScoreAndSave(
        tester, config,
        dart1: 'S5',
        dart2: 'Miss',
        dart3: 'S15',
      );

      expect(provider.getPlayerCompletedTargets(playerId), containsAll([5, 15]));
      expect(provider.getPlayerCompletedTargets(playerId), isNot(contains(10)));
    });

    testWidgets('Test 10: Edit score in speed mode adds new gears',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);

      // Throw 3 misses
      await throw3DartsAndWaitForTakeout(tester);
      expect(provider.getPlayerCompletedTargets(playerId), isEmpty);

      // Edit: change to 3 hits
      await EditScoreHelpers.editScoreAndSave(
        tester, config,
        dart1: 'S3',
        dart2: 'S7',
        dart3: 'S12',
      );

      expect(provider.getPlayerCompletedTargets(playerId), containsAll([3, 7, 12]));
    });

    // ================================================================
    // EDIT SCORE — BULLSEYE MODE
    // ================================================================

    testWidgets('Test 11: Edit score at bullseye target changes outcome',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, includeBullseye: true);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);

      // Set player to target 21 (bullseye)
      provider.currentGame!.currentTarget[playerId] = 21;
      // Update turn start state for edit score
      provider.currentGame!.turnStartCurrentTarget[playerId] = 21;
      provider.currentGame!.turnStartLapsCompleted[playerId] = 0;
      provider.currentGame!.turnStartState = provider.currentGame!.state;
      provider.currentGame!.turnStartWinnerId = null;
      provider.currentGame!.turnStartCompletedTargets[playerId] = [];
      provider.notifyListeners();
      await PumpSequences.simpleUpdate(tester);

      // Throw 3 misses at bullseye target
      await throw3DartsAndWaitForTakeout(tester);
      expect(provider.hasWinner, isFalse);

      // Edit: change dart 1 to Bullseye hit
      await EditScoreHelpers.editScoreAndSave(
        tester, config,
        dart1: 'Bull',
      );

      // Should now be a winner
      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, playerId);
    });
  });
}
