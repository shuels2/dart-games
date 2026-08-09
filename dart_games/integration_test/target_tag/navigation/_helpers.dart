import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/navigation_suite.dart';
import '../../shared/ui_test_helpers.dart';

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
  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPEC =====
//
// Shared bodies live in shared/navigation_suite.dart; everything
// game-specific for Target Tag is supplied here. Shield Max 3 and the two
// players are the exact setup the four hand-written files used.

Future<void> _setupAndStart(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await setShieldMax(tester, 3);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await UITestHelpers.startGame(tester, config);
}

void _verifySettings(WidgetTester tester) {
  // Two spaces between "Max:" and the value — see commit a1fbe11.
  expect(find.text('Shield Max:  3'), findsOneWidget);
  expect(find.text('Player A'), findsWidgets);
  expect(find.text('Player B'), findsWidgets);
}

/// Reaches a backable game screen: finish a game, then Play Again for a fresh
/// board with 0 darts thrown (so the back tap raises no Save prompt).
Future<void> _reachGameScreen(WidgetTester tester) async {
  await _setupAndStart(tester);
  await completeGameToVictory(tester, 'Player A', 'Player B');
  await ResultsHelpers.pumpUntilResults(tester, config);
  expect(config.getPlayAgainButton(), findsOneWidget);
  await UITestHelpers.clickPlayAgain(tester, config);

  // Extra settle after Play Again before the game screen is interactive.
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getTargetTagBackButton,
  setupAndStart: _setupAndStart,
  playToVictory: (tester) =>
      completeGameToVictory(tester, 'Player A', 'Player B'),
  reachGameScreen: _reachGameScreen,
  verifySettings: _verifySettings,
);
