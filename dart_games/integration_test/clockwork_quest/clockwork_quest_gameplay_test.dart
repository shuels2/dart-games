import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

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

Future<void> throwBullseyeViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 50,
      multiplier: 'bullseye',
      playerName: 'Player',
      baseScore: 50,
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

/// Set up a game and start it with configurable options and player count
Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  bool speedMode = false,
  int laps = 1,
  List<String>? playerNames,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  // Toggle settings as needed
  if (includeBullseye) {
    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
  }
  if (speedMode) {
    await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
  }
  if (laps > 1) {
    await SettingsHelpers.selectClockworkQuestLaps(tester, laps);
  }

  final names = playerNames ?? ['Player A', 'Player B'];
  for (final name in names) {
    await UITestHelpers.addPlayer(tester, name, config);
  }

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

/// Complete a game to victory for the current player (P1).
/// Handles takeout prompts and opponent turns (all misses).
Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool includeBullseye = false,
}) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);

  for (int target = 1; target <= 20; target++) {
    await throwDartViaMock(tester, target);

    if (target % 3 == 0 && target < 20) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
  }

  if (includeBullseye && !provider.hasWinner) {
    // After hitting 20, need to also handle takeout before bull
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
    await throwBullseyeViaMock(tester);
  }

  // Wait for results screen navigation
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

/// Complete a full turn: throw 3 darts (misses) and click darts removed
Future<void> completeTurnWithMisses(WidgetTester tester) async {
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);
}

/// Advance player through targets sequentially to a specific target
/// Handles turn/takeout cycling automatically
Future<void> advancePlayerToTarget(
    WidgetTester tester, int targetNumber) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);
  final playerId = provider.getCurrentPlayerId()!;

  for (int t = 1; t < targetNumber; t++) {
    await throwDartViaMock(tester, t);
    final dartsThrown = provider.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3) {
      await clickDartsRemoved(tester);
      // Skip opponent turn
      await completeTurnWithMisses(tester);
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Gameplay Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    // ================================================================
    // BASIC GAMEPLAY — Default settings (no bullseye, no speed, 1 lap)
    // ================================================================

    testWidgets('Test 1: Game starts with correct initial state',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);
      expect(
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester), isNotNull);
      expect(
          ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester), 0);

      // Verify game screen widgets
      expect(find.byKey(ClockworkQuestGameKeys.activePlayerPanel),
          findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.gearTracker), findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.activePlayerName),
          findsOneWidget);
    });

    testWidgets('Test 2: Hit correct target advances gear',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Player starts at target 1
      expect(provider.getPlayerCurrentTarget(playerId), 1);

      // Hit target 1
      await throwDartViaMock(tester, 1);

      // Should advance to target 2
      expect(provider.getPlayerCurrentTarget(playerId), 2);
      expect(
          ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester), 1);
    });

    testWidgets('Test 3: Hit wrong target does not advance',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Hit target 5 instead of 1
      await throwDartViaMock(tester, 5);

      expect(provider.getPlayerCurrentTarget(playerId), 1);
    });

    testWidgets('Test 4: Miss does not advance gear',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      await throwMissViaMock(tester);

      expect(provider.getPlayerCurrentTarget(playerId), 1);
      expect(
          ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester), 1);
    });

    testWidgets('Test 5: Sequential progression 1 through 3',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      await throwDartViaMock(tester, 1);
      expect(provider.getPlayerCurrentTarget(playerId), 2);

      await throwDartViaMock(tester, 2);
      expect(provider.getPlayerCurrentTarget(playerId), 3);

      await throwDartViaMock(tester, 3);
      expect(provider.getPlayerCurrentTarget(playerId), 4);
    });

    testWidgets('Test 6: Three darts triggers takeout prompt',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      // Takeout prompt should appear
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.shouldPromptTakeout, isTrue);
    });

    testWidgets('Test 7: Turn advances after darts removed',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final firstPlayerId = provider.getCurrentPlayerId()!;

      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);
      await clickDartsRemoved(tester);

      final secondPlayerId = provider.getCurrentPlayerId()!;
      expect(secondPlayerId, isNot(equals(firstPlayerId)));
    });

    testWidgets('Test 8: Skip turn advances to next player',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final firstPlayerId = provider.getCurrentPlayerId()!;

      // Hide dartboard emulator so skip button is not obscured
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

      await UITestHelpers.clickSkipTurn(tester, config);

      // Show dartboard emulator for DARTS REMOVED button
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

      await clickDartsRemoved(tester);

      final secondPlayerId = provider.getCurrentPlayerId()!;
      expect(secondPlayerId, isNot(equals(firstPlayerId)));
    });

    testWidgets('Test 9: Dart indicators update after each throw',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // Before any throws, all 3 indicators exist but are empty (transparent fill, border only)
      for (int i = 0; i < 3; i++) {
        final indicator = tester.widget<Container>(
          find.byKey(ClockworkQuestGameKeys.dartIndicator(i)),
        );
        final decoration = indicator.decoration as BoxDecoration;
        expect(decoration.color, Colors.transparent,
            reason: 'Dart indicator $i should be empty before throws');
      }

      // First dart — hit target 1 (amber fill = hit)
      await throwDartViaMock(tester, 1);
      final d0After = tester.widget<Container>(
        find.byKey(ClockworkQuestGameKeys.dartIndicator(0)),
      );
      final d0Decoration = d0After.decoration as BoxDecoration;
      expect(d0Decoration.color, const Color(0xFFFFBF00),
          reason: 'D1 should be amber (hit)');

      // Second dart — miss (silver fill)
      await throwMissViaMock(tester);
      final d1After = tester.widget<Container>(
        find.byKey(ClockworkQuestGameKeys.dartIndicator(1)),
      );
      final d1Decoration = d1After.decoration as BoxDecoration;
      expect(d1Decoration.color, const Color(0xFF8A8D93),
          reason: 'D2 should be silver (miss)');

      // Third dart — hit target 2 (amber fill)
      await throwDartViaMock(tester, 2);
      final d2After = tester.widget<Container>(
        find.byKey(ClockworkQuestGameKeys.dartIndicator(2)),
      );
      final d2Decoration = d2After.decoration as BoxDecoration;
      expect(d2Decoration.color, const Color(0xFFFFBF00),
          reason: 'D3 should be amber (hit)');
    });

    testWidgets('Test 10: Gear widgets transition from inactive to active',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // Gear 1 starts as inactive (current target, not yet hit)
      expect(find.byKey(ClockworkQuestGameKeys.gear(1)), findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.gearActive(1)), findsNothing);

      // Hit target 1 to activate it
      await throwDartViaMock(tester, 1);

      // Gear 1 should now be active (key changes from gear(1) to gearActive(1))
      expect(find.byKey(ClockworkQuestGameKeys.gearActive(1)), findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.gear(1)), findsNothing);

      // Gear 2 should now be visible as inactive (next target)
      expect(find.byKey(ClockworkQuestGameKeys.gear(2)), findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.gearActive(2)), findsNothing);

      // Hit target 2 to activate it
      await throwDartViaMock(tester, 2);

      // Gear 2 should now be active
      expect(find.byKey(ClockworkQuestGameKeys.gearActive(2)), findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.gear(2)), findsNothing);

      // Gear 1 should still be active
      expect(find.byKey(ClockworkQuestGameKeys.gearActive(1)), findsOneWidget);
    });

    testWidgets(
        'Test 11: Win condition - standard (no bullseye, 1 lap)',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Set player near end
      provider.currentGame!.currentTarget[playerId] = 20;

      await throwDartViaMock(tester, 20);

      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, playerId);
    });

    testWidgets('Test 12: Opponent tiles visible on game screen',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerIds = provider.currentGame!.playerIds;
      final currentPlayerId = provider.getCurrentPlayerId()!;

      // The other player should show as opponent tile
      final opponentId = playerIds.firstWhere((id) => id != currentPlayerId);
      expect(find.byKey(ClockworkQuestGameKeys.playerTile(opponentId)),
          findsOneWidget);
    });

    testWidgets('Test 13: Double on correct target still advances 1 gear',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Hit double 1
      await throwDartViaMock(tester, 1, multiplier: 'double');

      // Should advance to target 2 (doubles count as single hit in normal mode)
      expect(provider.getPlayerCurrentTarget(playerId), 2);
    });

    testWidgets('Test 14: Triple on correct target still advances 1 gear',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Hit triple 1
      await throwDartViaMock(tester, 1, multiplier: 'triple');

      // Should advance to target 2
      expect(provider.getPlayerCurrentTarget(playerId), 2);
    });

    // ================================================================
    // INCLUDE BULLSEYE OPTION
    // ================================================================

    testWidgets('Test 15: Bullseye ON — must hit bull after 20',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, includeBullseye: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Verify maxTarget is 21 with bullseye
      expect(provider.currentGame!.maxTarget, 21);

      // Set player to target 20, hit 20
      provider.currentGame!.currentTarget[playerId] = 20;
      await throwDartViaMock(tester, 20);

      // Should advance to 21 (bullseye), not lap complete
      expect(provider.getPlayerCurrentTarget(playerId), 21);
      expect(provider.getPlayerLapsCompleted(playerId), 0);
    });

    testWidgets('Test 16: Bullseye ON — hitting bull at target 21 completes lap',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, includeBullseye: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      provider.currentGame!.currentTarget[playerId] = 21;
      await throwBullseyeViaMock(tester);

      // Should have completed 1 lap and won (1 lap game)
      expect(provider.hasWinner, isTrue);
    });

    testWidgets('Test 17: Bullseye OFF — hitting 20 wins game',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, includeBullseye: false);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.maxTarget, 20);

      provider.currentGame!.currentTarget[playerId] = 20;
      await throwDartViaMock(tester, 20);

      expect(provider.hasWinner, isTrue);
    });

    testWidgets('Test 18: Bullseye ON — gear 21 widget shown as inactive',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, includeBullseye: true);

      // The bullseye gear (gear 21) should be on screen as inactive
      expect(find.byKey(ClockworkQuestGameKeys.gear(21)), findsOneWidget);
      expect(find.byKey(ClockworkQuestGameKeys.gearActive(21)), findsNothing);

      // Set player to target 21 and hit bullseye
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;
      provider.currentGame!.currentTarget[playerId] = 21;
      // Mark gears 1-20 as completed so gear 21 is the current target
      for (int i = 1; i <= 20; i++) {
        provider.currentGame!.completedTargets[playerId]!.add(i);
      }
      provider.notifyListeners();
      await PumpSequences.simpleUpdate(tester);

      await throwBullseyeViaMock(tester);

      // Hitting gear 21 completes the game (last target in single lap)
      expect(provider.hasWinner, isTrue);
    });

    // ================================================================
    // SPEED MODE OPTION
    // ================================================================

    testWidgets('Test 19: Speed mode — any gear number counts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.speedMode, isTrue);

      // Hit gear 15 (not target 1)
      await throwDartViaMock(tester, 15);

      // Should count as a hit in speed mode (any uncompleted gear)
      final completed = provider.getPlayerCompletedTargets(playerId);
      expect(completed, contains(15));
    });

    testWidgets('Test 20: Speed mode — already activated gear does not count',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Hit gear 5
      await throwDartViaMock(tester, 5);
      expect(provider.getPlayerCompletedTargets(playerId), contains(5));

      // Hit gear 5 again
      await throwDartViaMock(tester, 5);
      // Should still only have 1 completed target
      expect(provider.getPlayerCompletedTargets(playerId).length, 1);
    });

    testWidgets('Test 21: Speed mode — completing all gears wins',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Activate gears 1-19 directly
      for (int i = 1; i <= 19; i++) {
        provider.currentGame!.completedTargets[playerId]!.add(i);
      }
      provider.currentGame!.currentTarget[playerId] = 20;

      // Hit the last gear
      await throwDartViaMock(tester, 20);

      expect(provider.hasWinner, isTrue);
    });

    testWidgets('Test 22: Speed mode with bullseye — must also hit bull',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config,
          speedMode: true, includeBullseye: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.maxTarget, 21);

      // Activate gears 1-20 directly
      for (int i = 1; i <= 20; i++) {
        provider.currentGame!.completedTargets[playerId]!.add(i);
      }
      provider.currentGame!.currentTarget[playerId] = 21;

      // Hit bullseye to complete
      await throwBullseyeViaMock(tester);

      expect(provider.hasWinner, isTrue);
    });

    testWidgets(
        'Test 23: Speed mode — hitting out-of-range number does not count',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Miss should not add any completed targets
      await throwMissViaMock(tester);
      expect(provider.getPlayerCompletedTargets(playerId), isEmpty);
    });

    // ================================================================
    // LAPS OPTION
    // ================================================================

    testWidgets('Test 24: 2 laps — completing 1 lap resets target to 1',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, laps: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.numberOfLaps, 2);

      // Set near end of first lap
      provider.currentGame!.currentTarget[playerId] = 20;
      await throwDartViaMock(tester, 20);

      // Should reset to target 1, lap 1 complete
      expect(provider.getPlayerCurrentTarget(playerId), 1);
      expect(provider.getPlayerLapsCompleted(playerId), 1);
      expect(provider.hasWinner, isFalse);
    });

    testWidgets('Test 25: 2 laps — completing both laps wins',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, laps: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Complete first lap
      provider.currentGame!.currentTarget[playerId] = 20;
      provider.currentGame!.lapsCompleted[playerId] = 0;
      await throwDartViaMock(tester, 20);
      expect(provider.hasWinner, isFalse);

      // Complete second lap
      provider.currentGame!.currentTarget[playerId] = 20;
      await throwDartViaMock(tester, 20);

      expect(provider.hasWinner, isTrue);
    });

    testWidgets('Test 26: Lap counter visible when laps > 1',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, laps: 3);

      expect(find.byKey(ClockworkQuestGameKeys.currentLapText),
          findsOneWidget);
    });

    testWidgets('Test 27: Lap counter NOT visible when laps = 1',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, laps: 1);

      expect(find.byKey(ClockworkQuestGameKeys.currentLapText),
          findsNothing);
    });

    // ================================================================
    // OPTION COMBINATIONS
    // ================================================================

    testWidgets(
        'Test 28: Bullseye + 2 laps — bull required each lap',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config,
          includeBullseye: true, laps: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.maxTarget, 21);
      expect(provider.currentGame!.numberOfLaps, 2);

      // Complete first lap ending with bull
      provider.currentGame!.currentTarget[playerId] = 21;
      await throwBullseyeViaMock(tester);

      expect(provider.getPlayerLapsCompleted(playerId), 1);
      expect(provider.getPlayerCurrentTarget(playerId), 1);
      expect(provider.hasWinner, isFalse);

      // Complete second lap
      provider.currentGame!.currentTarget[playerId] = 21;
      await throwBullseyeViaMock(tester);

      expect(provider.hasWinner, isTrue);
    });

    testWidgets(
        'Test 29: Speed mode + 2 laps — all gears reset after first lap',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true, laps: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      // Activate gears 1-19
      for (int i = 1; i <= 19; i++) {
        provider.currentGame!.completedTargets[playerId]!.add(i);
      }
      provider.currentGame!.currentTarget[playerId] = 20;

      await throwDartViaMock(tester, 20);

      // First lap done, targets should reset
      expect(provider.getPlayerLapsCompleted(playerId), 1);
      expect(provider.getPlayerCompletedTargets(playerId), isEmpty);
      expect(provider.hasWinner, isFalse);
    });

    testWidgets(
        'Test 30: Speed mode + bullseye + 2 laps — all options combined',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config,
          speedMode: true, includeBullseye: true, laps: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerId = provider.getCurrentPlayerId()!;

      expect(provider.currentGame!.speedMode, isTrue);
      expect(provider.currentGame!.includeBullseye, isTrue);
      expect(provider.currentGame!.numberOfLaps, 2);
      expect(provider.currentGame!.maxTarget, 21);

      // Activate all 20 numbered gears
      for (int i = 1; i <= 20; i++) {
        provider.currentGame!.completedTargets[playerId]!.add(i);
      }
      provider.currentGame!.currentTarget[playerId] = 21;

      // Hit bullseye to complete first lap
      await throwBullseyeViaMock(tester);

      expect(provider.getPlayerLapsCompleted(playerId), 1);
      expect(provider.hasWinner, isFalse);

      // Activate all gears again for second lap
      for (int i = 1; i <= 20; i++) {
        provider.currentGame!.completedTargets[playerId]!.add(i);
      }
      provider.currentGame!.currentTarget[playerId] = 21;

      await throwBullseyeViaMock(tester);

      expect(provider.hasWinner, isTrue);
    });

    // ================================================================
    // FULL GAME TO VICTORY (end-to-end)
    // ================================================================

    testWidgets('Test 31: Full game — P1 wins with sequential hits',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final player1 = provider.getCurrentPlayerId()!;

      // P1 plays turns, P2 misses, until P1 wins
      for (int target = 1; target <= 20; target++) {
        await throwDartViaMock(tester, target);

        // After every 3rd dart, handle takeout and opponent turn
        if (target % 3 == 0 && target < 20) {
          await clickDartsRemoved(tester);
          // P2 turn: all misses
          await completeTurnWithMisses(tester);
        }
      }

      // Game should be won
      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, player1);
    });

    // ================================================================
    // MULTI-PLAYER GAMES (3+ players)
    // ================================================================

    testWidgets('Test 32: 3-player game — opponent tiles visible for both opponents',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config,
          playerNames: ['Alice', 'Bob', 'Carol']);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerIds = provider.currentGame!.playerIds;
      final currentPlayerId = provider.getCurrentPlayerId()!;

      // Both non-active players should show as opponent tiles
      final opponents = playerIds.where((id) => id != currentPlayerId).toList();
      expect(opponents.length, 2);

      for (final opponentId in opponents) {
        expect(
          find.byKey(ClockworkQuestGameKeys.playerTile(opponentId)),
          findsOneWidget,
          reason: 'Opponent tile for $opponentId should be visible',
        );
      }
    });

    testWidgets('Test 33: 4-player game — turn cycles through all 4 players',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config,
          playerNames: ['P1', 'P2', 'P3', 'P4']);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final playerIds = provider.currentGame!.playerIds;

      // Verify P1 is active
      expect(provider.getCurrentPlayerId(), playerIds[0]);

      // P1 turn: 3 misses
      await completeTurnWithMisses(tester);
      expect(provider.getCurrentPlayerId(), playerIds[1]);

      // P2 turn: 3 misses
      await completeTurnWithMisses(tester);
      expect(provider.getCurrentPlayerId(), playerIds[2]);

      // P3 turn: 3 misses
      await completeTurnWithMisses(tester);
      expect(provider.getCurrentPlayerId(), playerIds[3]);

      // P4 turn: 3 misses — back to P1
      await completeTurnWithMisses(tester);
      expect(provider.getCurrentPlayerId(), playerIds[0]);
    });

    // ================================================================
    // FULL GAME — BULLSEYE END-TO-END
    // ================================================================

    testWidgets('Test 34: Full game with bullseye — P1 wins after hitting bull',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, includeBullseye: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final player1 = provider.getCurrentPlayerId()!;

      // P1 hits 1-20 sequentially
      for (int target = 1; target <= 20; target++) {
        await throwDartViaMock(tester, target);
        if (target % 3 == 0 && target < 20) {
          await clickDartsRemoved(tester);
          await completeTurnWithMisses(tester);
        }
      }

      // After hitting 20, should be at target 21 (bullseye)
      expect(provider.getPlayerCurrentTarget(player1), 21);
      expect(provider.hasWinner, isFalse);

      // Handle takeout from the turn that hit 20
      if (provider.shouldPromptTakeout) {
        await clickDartsRemoved(tester);
        await completeTurnWithMisses(tester);
      }

      // Hit bullseye to win
      await throwBullseyeViaMock(tester);

      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, player1);
    });

    // ================================================================
    // FULL GAME — SPEED MODE END-TO-END
    // ================================================================

    testWidgets('Test 35: Full game with speed mode — P1 wins hitting gears in any order',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config, speedMode: true);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final player1 = provider.getCurrentPlayerId()!;

      // Hit gears in non-sequential order: 20, 15, 10, 5, 1, ...
      final order = [20, 15, 10, 5, 1, 19, 14, 9, 4, 2, 18, 13, 8, 3, 17, 12, 7, 6, 16, 11];
      for (final gear in order) {
        await throwDartViaMock(tester, gear);
        if (provider.hasWinner) break;
        if (provider.shouldPromptTakeout) {
          await clickDartsRemoved(tester);
          await completeTurnWithMisses(tester);
        }
      }

      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, player1);
    });

    // ================================================================
    // FULL GAME — 3 PLAYERS TO RESULTS SCREEN
    // ================================================================

    testWidgets('Test 36: 3-player game completes and shows results',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config,
          playerNames: ['Alice', 'Bob', 'Carol']);

      await completeGameToVictory(tester, numOpponents: 2);

      // Should be on results screen
      await UITestHelpers.verifyResultsScreen(tester, config);
    });
  });
}
