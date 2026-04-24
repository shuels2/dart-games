import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.reefRoyale();

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

/// Throw a dart at a specific number with multiplier
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

/// Throw a bullseye (inner bull, 50 points, 2 marks on Bull target)
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

/// Throw outer bull (25 points, 1 mark on Bull target)
Future<void> throwOuterBullViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 25,
      multiplier: 'outer_bull',
      playerName: 'Player',
      baseScore: 25,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Throw a miss (bounceout/off-board)
Future<void> throwMissViaMock(WidgetTester tester) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'miss',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Click DARTS REMOVED to advance turn
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Verify dart indicator border color
void verifyDartIndicatorColor(WidgetTester tester, Key dartKey, int expectedColorValue) {
  final indicatorFinder = find.byKey(dartKey);
  expect(indicatorFinder, findsOneWidget);

  final container = tester.widget<Container>(indicatorFinder);
  final decoration = container.decoration as BoxDecoration?;
  expect(decoration, isNotNull);

  expect(decoration!.border, isNotNull);

  final border = decoration.border as Border;
  final actualColor = border.top.color.value;

  expect(actualColor, expectedColorValue,
      reason: 'Dart $dartKey should have border color 0x${expectedColorValue.toRadixString(16)}, '
          'but got 0x${actualColor.toRadixString(16)}');
}

/// Set up a 2-player game and start it
Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config, {
  bool easyClaim = false,
  bool neighborNumbers = false,
  bool cursedTide = false,
  bool bonusBuffs = false,
  bool speedPlay = false,
  int? roundLimit,
  bool randomReefs = false,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (cursedTide) {
    await SettingsHelpers.setReefRoyaleGameMode(tester, 'Cursed Tide');
  }

  if (easyClaim) {
    await SettingsHelpers.toggleReefRoyaleEasyClaim(tester);
  }

  if (neighborNumbers) {
    await SettingsHelpers.toggleReefRoyaleNeighborNumbers(tester);
  }

  if (randomReefs) {
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
  }

  if (bonusBuffs) {
    await SettingsHelpers.toggleReefRoyaleBonusBuffs(tester);
  }

  if (speedPlay) {
    await SettingsHelpers.toggleReefRoyaleSpeedPlay(tester);
  }

  if (roundLimit != null) {
    await SettingsHelpers.setReefRoyaleRoundLimit(tester, roundLimit);
  }

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added, no need to call selectPlayers
  await UITestHelpers.startGame(tester, config);
}
