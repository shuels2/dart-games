import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/settings_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/edit_score_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/ui_test_helpers.dart';

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
  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Target Tag is supplied here.
//
// Target Tag's hand-written pause tests were the older generation: they
// guarded every tap with `if (finder.evaluate().isNotEmpty)` and skipped the
// pause-still-visible assert and the trailing reconnect that the newer games
// make. The shared bodies are a strict superset — nothing Target Tag asserted
// is dropped, and the overlay assertions it lacked are now made.

Future<void> _hitOwnTarget(WidgetTester tester) async {
  final targetNumber = GameSetupHelpers.getCurrentPlayerTargetNumber(tester);
  await DartThrowHelpers.throwDartViaMock(tester, targetNumber);
}

final pauseModalSpec = PauseModalSpec(
  config: config,
  menuBackButton: ElementFinders.getTargetTagBackButton,
  ownGameCard: ElementFinders.getTargetTagCard,
  verifyOnMenu: (tester) =>
      expect(find.text('TARGET TAG GAME SETUP'), findsWidgets,
          reason: 'Menu screen not showing — setup heading not found'),
  menuSettingsControls: [ElementFinders.getTargetTagShieldMaxSlider],
  menuStartPlayers: const ['PauseA', 'PauseB'],
  verifyOnHome: (tester) {
    expect(find.byKey(HomeKeys.carnivalDerbyCard), findsOneWidget);
    expect(find.byKey(HomeKeys.targetTagCard), findsOneWidget);
  },
  startGame: (tester) =>
      GameSetupHelpers.setupAndStartTargetTag(tester, config),
  verifyOnGameScreen: (tester) {
    expect(config.getGameBackButton(), findsOneWidget,
        reason: 'Game screen not showing — game back button not found');
    expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue,
        reason: 'Game is no longer active');
  },
  throwOneDart: _hitOwnTarget,
  throwAnotherDart: throwMissViaMock,
  throwTurnToTakeout: (tester) async {
    // One hit plus two misses fills the turn without eliminating anyone.
    await _hitOwnTarget(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
  },
  verifyNoSavePrompt: (tester) => expect(find.text('Save'), findsNothing,
      reason: 'Save prompt appeared despite the pause overlay'),
  finishTakeout: clickDartsRemoved,
  openEditScore: (tester) => EditScoreHelpers.openEditScore(tester, config),
  reachResults: (tester) async {
    await GameSetupHelpers.setupAndStartTargetTag(tester, config, shieldMax: 3);
    await completeGameToVictory(tester, 'Player A', 'Player B');
  },
  resultsAfterReconnect: (tester) async {
    await UITestHelpers.clickPlayAgain(tester, config);
    expect(config.getPlayAgainButton(), findsNothing,
        reason: 'Play Again did not work after reconnect');
  },
);
