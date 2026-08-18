import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/play_to_complete_helpers.dart';
export '../../shared/provider_helpers.dart';

final config = GameUIConfig.piratesGrid();

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

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  String difficulty = 'Easy',
  String bestOf = '1',
  bool stealMode = false,
  bool speedPlay = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartPiratesGrid(
      tester,
      config,
      difficulty: difficulty,
      bestOf: bestOf,
      stealMode: stealMode,
      speedPlay: speedPlay,
      playerNames: playerNames,
    );

Future<void> tapPlayToComplete(WidgetTester tester) =>
    PlayToCompleteHelpers.tapPlayToComplete(tester);

Future<void> waitForGameCompletion(WidgetTester tester) =>
    PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () =>
          ProviderHelpers.getPiratesGridProvider(tester).hasWinner,
    );

// ===== PLAY TO COMPLETE SUITE SPEC =====
//
// Shared bodies live in shared/play_to_complete_suite.dart; everything
// specific to Pirate's Grid is supplied here. Only the two commodity scenarios
// (default settings, mid-game pickup) use it — the per-option tests in this
// folder stay hand-written.

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartPiratesGrid(tester, config),
  setupAndStartMidGame: (tester) => setupAndStartGame(tester, config,
      playerNames: ['Player A', 'Player B']),
  hasWinner: (tester) =>
      ProviderHelpers.getPiratesGridProvider(tester).hasWinner,
  // One cell claimed then two misses, and the turn taken out, so auto-play
  // picks up on the opponent's turn rather than mid-turn.
  midGameDarts: (tester) async {
    final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    await throwDartViaMock(tester, t00);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);
  },
);
