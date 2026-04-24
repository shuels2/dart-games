import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.reefRoyale();

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
    WidgetTester tester, GameUIConfig config) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

/// Complete game: P1 claims all 7 targets
Future<void> completeGameToVictory(WidgetTester tester) async {
  // P1 Turn 1: claim 20, 19, 18
  await throwDartViaMock(tester, 20, multiplier: 'triple');
  await throwDartViaMock(tester, 19, multiplier: 'triple');
  await throwDartViaMock(tester, 18, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // P2 misses
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // P1 Turn 2: claim 17, 16, 15
  await throwDartViaMock(tester, 17, multiplier: 'triple');
  await throwDartViaMock(tester, 16, multiplier: 'triple');
  await throwDartViaMock(tester, 15, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // P2 misses
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // P1 Turn 3: claim Bull (bullseye=2 + outer=1 = 3 marks)
  await throwBullseyeViaMock(tester);
  await throwOuterBullViaMock(tester);

  // Wait for takeout prompt (3500ms delay triggers simulateTakeoutStarted)
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();

  // Click DARTS REMOVED to trigger takeout_finished -> _handleGameWon
  await clickDartsRemoved(tester);

  // Wait for results screen navigation (3000ms delay in _handleGameWon)
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(); // Process navigation
  await tester.pump(); // Build results screen
  await tester.pump(); // Layout
}
