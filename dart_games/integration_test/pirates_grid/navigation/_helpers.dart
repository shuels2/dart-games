import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/models/pirates_grid_game.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';

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

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

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

// ===== GAME-SPECIFIC HELPERS =====

/// Throw the correct dart for a grid cell's target requirement.
/// Used by completeGameToVictory to work with any difficulty.
Future<void> throwForCellTarget(WidgetTester tester, CellTarget target) async {
  switch (target.requirement) {
    case CellRequirement.bull:
      await DartThrowHelpers.throwBullseyeViaMock(tester);
    case CellRequirement.tripleOnly:
      await DartThrowHelpers.throwDartViaMock(tester, target.number,
          multiplier: 'triple');
    case CellRequirement.doubleOnly:
    case CellRequirement.doubleOrTriple:
      await DartThrowHelpers.throwDartViaMock(tester, target.number,
          multiplier: 'double');
    case CellRequirement.any:
      await DartThrowHelpers.throwDartViaMock(tester, target.number);
  }
}

/// Complete the game to victory by planting flags in row 0 for P1.
///
/// Reads the actual target numbers from the grid at runtime — safe after
/// grid targets were randomized. P2 always misses all 3 darts every turn.
///
/// Steal-mode safety: because P2 ALWAYS misses, P2 can never steal P1's
/// flags even when steal mode is ON. P1 builds their winning line without
/// interference — no ping-pong loop is possible.
Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getPiratesGridProvider(tester);

  for (int attempt = 0; attempt < 20; attempt++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.currentGame?.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final p1Id = provider.currentGame!.playerIds[0];

    if (currentPlayerId == p1Id) {
      // P1: throw darts targeting each cell in row 0 using actual target numbers.
      // If a cell is already claimed by P1, throw its number anyway — redundant
      // hits on own cells are no-ops, keeping the 3-darts-per-turn count correct.
      for (int col = 0; col < 3; col++) {
        if (provider.hasWinner) break;
        await throwForCellTarget(
            tester, provider.currentGame!.grid[0][col].target);
      }
    } else {
      // P2: always miss all 3 darts
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
    }

    if (provider.hasWinner) break;

    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;
    }
  }

  if (!provider.hasWinner) {
    await clickDartsRemoved(tester);
  } else {
    await clickDartsRemoved(tester);
  }

  await ResultsHelpers.pumpUntilResults(tester, config);
}
