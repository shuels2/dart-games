import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.carnivalDerby();

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }
}

Future<void> navigateToCarnivalDerbyMenu(WidgetTester tester) async {
  await UITestHelpers.resetServerState();
  await UITestHelpers.navigateToGameMenu(tester, config);
  expect(find.textContaining('Target score:'), findsOneWidget);
}

Future<void> setTargetScore(WidgetTester tester, int targetScore) async {
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsOneWidget);

  Slider sliderWidget = tester.widget<Slider>(sliderFinder);
  final currentValue = sliderWidget.value.toInt();

  if (currentValue == targetScore) {
    return;
  }

  if (sliderWidget.onChanged != null) {
    sliderWidget.onChanged!(targetScore.toDouble());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();
  }

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> startGame(WidgetTester tester) async {
  await UITestHelpers.startGame(tester, config);
  expect(find.text('Carnival Derby Race'), findsOneWidget);
}

Future<void> completeGameToVictory(WidgetTester tester) async {
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await clickDartsRemoved(tester);

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
