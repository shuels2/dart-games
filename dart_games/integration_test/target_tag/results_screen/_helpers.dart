import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/player_provider.dart';

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

  await throwDartViaMock(tester, target1, multiplier: 'triple');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await throwDartViaMock(tester, target2, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}

Future<void> completeGameToVictoryTeamMode(WidgetTester tester, String team1Player, String team2Player) async {
  final provider = Provider.of<TargetTagProvider>(tester.element(find.byType(Scaffold).first), listen: false);
  final game = provider.currentGame!;

  final currentPlayerId = game.getCurrentPlayerId();
  final currentTeamId = game.playerToTeam![currentPlayerId]!;
  final teamTargetNum = game.targetNumbers[currentPlayerId]!;

  await throwDartViaMock(tester, teamTargetNum, multiplier: 'triple');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  int? opponentTargetNum;
  final playerProvider = Provider.of<PlayerProvider>(tester.element(find.byType(Scaffold).first), listen: false);
  final allPlayers = playerProvider.allPlayers;
  final currentTeamPlayers = game.teamPlayers![currentTeamId]!;

  for (final player in allPlayers) {
    if (!currentTeamPlayers.contains(player.id)) {
      opponentTargetNum = game.targetNumbers[player.id];
      break;
    }
  }

  if (opponentTargetNum == null) {
    throw Exception('Could not find opponent target number');
  }

  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await throwDartViaMock(tester, 0, multiplier: 'miss');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await throwDartViaMock(tester, opponentTargetNum, multiplier: 'single');
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await tester.pump(const Duration(seconds: 5));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}
