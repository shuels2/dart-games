import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/play_to_complete_helpers.dart';
export '../../shared/provider_helpers.dart';

final config = GameUIConfig.gladiatorArena();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      targetScore: targetScore,
      doubleFinishEnabled: doubleFinishEnabled,
      shieldRoundEnabled: shieldRoundEnabled,
      speedPlayEnabled: speedPlayEnabled,
      playerNames: playerNames,
    );

Future<void> tapPlayToComplete(WidgetTester tester) =>
    PlayToCompleteHelpers.tapPlayToComplete(tester);

Future<void> waitForGameCompletion(
  WidgetTester tester, {
  required bool Function() isComplete,
  int maxIterations = 500,
}) =>
    PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: isComplete,
      maxIterations: maxIterations,
    );

// ===== PLAY TO COMPLETE SUITE SPEC =====
//
// Shared bodies live in shared/play_to_complete_suite.dart; everything
// specific to Gladiator Arena is supplied here. Only the two commodity scenarios
// (default settings, mid-game pickup) use it — the per-option tests in this
// folder stay hand-written.

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartGladiatorArena(tester, config),
  // The mid-game run uses a low target with double-finish off so the game is
  // reachable from a part-played board inside the poll budget.
  setupAndStartMidGame: (tester) =>
      GameSetupHelpers.setupAndStartGladiatorArena(tester, config,
          targetScore: 100, doubleFinishEnabled: false),
  hasWinner: (tester) =>
      ProviderHelpers.getGladiatorArenaProvider(tester).hasWinner,
  // A full scoring turn, taken out, then the opponent's turn missed away.
  midGameDarts: (tester) async {
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.clickDartsRemoved(tester);
    await DartThrowHelpers.completeTurnWithMisses(tester);
  },
);
