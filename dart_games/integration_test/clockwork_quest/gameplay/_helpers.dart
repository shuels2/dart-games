import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.clockworkQuest();

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

/// Complete game: P1 advances through all targets to win
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
