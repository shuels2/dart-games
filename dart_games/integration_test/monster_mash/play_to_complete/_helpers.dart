// integration_test/monster_mash/play_to_complete/_helpers.dart
//
// Spec for the two commodity play-to-complete scenarios. The bodies live in
// shared/play_to_complete_suite.dart; this file supplies only what is
// specific to Monster Mash.
//
// The per-OPTION play-to-complete tests in this folder (bestof3,
// hard_landing_on, shield_round, and so on) are NOT templated — they assert
// game-specific settings effects and stay hand-written.
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.monsterMash();

Future<void> _setupAndStart(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await UITestHelpers.startGame(tester, config);
}

/// The mid-game run lowers Health Max first so the hand-thrown attacks land
/// on a board that can still finish inside the poll budget.
Future<void> _setupAndStartMidGame(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);
  await UITestHelpers.startGame(tester, config);
}

/// Two attacks on the opponent's target, read from the provider because the
/// assignment is randomized.
Future<void> _midGameDarts(WidgetTester tester) async {
  final currentPlayerId =
      ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
  final players = ProviderHelpers.getSelectedPlayers(tester);
  final opponent = players.firstWhere((p) => p.id != currentPlayerId);
  final opponentTarget =
      ProviderHelpers.getMonsterMashPlayerTarget(tester, opponent.id)!;

  await DartThrowHelpers.throwDartViaMock(tester, opponentTarget,
      multiplier: 'single');
  await DartThrowHelpers.throwDartViaMock(tester, opponentTarget,
      multiplier: 'single');
}

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: _setupAndStart,
  setupAndStartMidGame: _setupAndStartMidGame,
  hasWinner: (tester) =>
      ProviderHelpers.getMonsterMashProvider(tester).hasWinner,
  midGameDarts: _midGameDarts,
  maxIterations: 800,
  verifyNotWonBeforeAutoPlay: true,
);
