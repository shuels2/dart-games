import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

// Game configuration for Monster Mash
final config = GameUIConfig.monsterMash();

// ===== MOCK API DART THROWING HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number, {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
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

/// Complete a game to victory via elimination (low health for speed)
Future<void> completeGameToVictory(WidgetTester tester) async {
  final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
  final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
  if (playerA == null || playerB == null) {
    throw Exception('Players not found');
  }

  final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
  final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
  final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

  // Attack opponent with triples: 3+3+3 = 9 damage (out of 10 HP)
  await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
  await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
  await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // Opponent misses
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // Finish off opponent (1 HP remaining)
  await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
  await clickDartsRemoved(tester);

  // Wait for victory screen
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
