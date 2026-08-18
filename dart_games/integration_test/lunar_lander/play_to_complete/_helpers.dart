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

final config = GameUIConfig.lunarLander();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int altitude = 200,
  bool hardLanding = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: altitude,
      hardLanding: hardLanding,
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
// specific to Lunar Lander is supplied here. Only the two commodity scenarios
// (default settings, mid-game pickup) use it — the per-option tests in this
// folder stay hand-written.

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartLunarLander(tester, config),
  hasWinner: (tester) =>
      ProviderHelpers.getLunarLanderProvider(tester).hasWinner,
  // Descend 20 + 20 = 40 of the default 200.
  midGameDarts: (tester) async {
    await DartThrowHelpers.throwDartViaMock(tester, 20);
    await DartThrowHelpers.throwDartViaMock(tester, 20);
  },
  verifyNotWonBeforeAutoPlay: true,
);
