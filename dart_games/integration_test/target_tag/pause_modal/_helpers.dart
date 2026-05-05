import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/settings_helpers.dart';

final config = GameUIConfig.targetTag();

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

Future<void> setShieldMax(WidgetTester tester, int shieldMax) =>
    SettingsHelpers.setTargetTagShieldMax(tester, shieldMax);

// ===== GAME-SPECIFIC HELPERS =====

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

  // Turn 1: Player 1 hits own target as triple (fills shields to max, tagged in)
  await throwDartViaMock(tester, target1, multiplier: 'triple');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 2: Player 2 throws all misses (stays at 0 shields)
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Turn 3: Player 1 (tagged in) hits Player 2's target once -> instant elimination
  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);

  // Wait for _handleGameWon 3s navigation delay
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
