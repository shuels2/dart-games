import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.reefRoyale();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwOuterBullViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwOuterBullViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config) =>
    GameSetupHelpers.setupAndStartReefRoyale(tester, config);

// ===== GAME-SPECIFIC HELPERS =====

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
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
