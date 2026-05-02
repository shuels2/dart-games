import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.targetTag();

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number, {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
  assert(mockApi != null, 'Mock API not available - game may not be initialized');
  mockApi!.simulateDartThrow(
    score: number * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
    multiplier: multiplier,
    playerName: 'Player',
    baseScore: number,
    widgetX: 125.0,
    widgetY: 125.0,
    widgetSize: 250.0,
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<void> setShieldMax(WidgetTester tester, int shieldMax) async {
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsWidgets);

  final shieldMaxLabel = find.textContaining('Shield Max:');
  expect(shieldMaxLabel, findsOneWidget);

  final shieldMaxContainer = find.ancestor(
    of: shieldMaxLabel,
    matching: find.byType(Container),
  );

  final shieldMaxSlider = find.descendant(
    of: shieldMaxContainer.first,
    matching: find.byType(Slider),
  );
  expect(shieldMaxSlider, findsOneWidget);

  Slider sliderWidget = tester.widget<Slider>(shieldMaxSlider);
  final currentValue = sliderWidget.value.toInt();

  if (currentValue == shieldMax) {
    return;
  }

  if (sliderWidget.onChanged != null) {
    sliderWidget.onChanged!(shieldMax.toDouble());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();
  }

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

String? getTargetNumberFromPlayerTile(WidgetTester tester, String playerName) {
  final playerProvider = ProviderHelpers.getPlayerProvider(tester);
  final targetTagProvider = ProviderHelpers.getTargetTagProvider(tester);

  final players = playerProvider.allPlayers;
  final player = players.firstWhere(
    (p) => p.name == playerName,
    orElse: () => throw Exception('Player $playerName not found'),
  );

  final targetNumber = targetTagProvider.getTargetNumber(player.id);
  return targetNumber?.toString();
}

Future<void> completeGameToVictory(WidgetTester tester, String player1Name, String player2Name) async {
  final target1Str = getTargetNumberFromPlayerTile(tester, player1Name);
  final target2Str = getTargetNumberFromPlayerTile(tester, player2Name);

  if (target1Str == null || target2Str == null) {
    throw Exception('Could not find target numbers for players');
  }

  final target1 = int.parse(target1Str);
  final target2 = int.parse(target2Str);

  // Turn 1: Player 1 throws TRIPLE on own target = 3 shields = TAGGED IN!
  await throwDartViaMock(tester, target1, multiplier: 'triple');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 2: Player 2 throws all misses (stays at 0 shields — eliminatable in one hit)
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 3: Player 1 (tagged in) hits Player 2's target once → instant elimination (P2 at 0 shields)
  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);

  // Wait for _handleGameWon 3s navigation delay
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
