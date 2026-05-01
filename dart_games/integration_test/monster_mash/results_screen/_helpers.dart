import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.monsterMash();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

// ===== GAME-SPECIFIC HELPERS =====

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
