import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/models/pirates_grid_game.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/pause_modal_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';

import '../../shared/element_finders.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/ui_test_helpers.dart';

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

Future<void> simulateDisconnectAndVerify(WidgetTester tester) =>
    PauseModalHelpers.simulateDisconnectAndVerify(tester);

Future<void> simulateReconnectAndVerify(WidgetTester tester) =>
    PauseModalHelpers.simulateReconnectAndVerify(tester);

Future<void> openEditScore(WidgetTester tester, GameUIConfig config) =>
    EditScoreHelpers.openEditScore(tester, config);

// ===== GAME-SPECIFIC HELPERS =====

/// Throw the correct dart for a grid cell's target requirement.
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
/// P2 always misses so steal mode can't create a ping-pong loop.
Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getPiratesGridProvider(tester);

  for (int attempt = 0; attempt < 20; attempt++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.currentGame?.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final p1Id = provider.currentGame!.playerIds[0];

    if (currentPlayerId == p1Id) {
      for (int col = 0; col < 3; col++) {
        if (provider.hasWinner) break;
        await throwForCellTarget(
            tester, provider.currentGame!.grid[0][col].target);
      }
    } else {
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
    }

    if (provider.hasWinner) break;

    await DartThrowHelpers.clickDartsRemoved(tester);
  }

  // After hasWinner becomes true the game-screen schedules navigation to
  // the results screen via Future.delayed(3000ms) inside _handleGameWon —
  // but only after a takeout is acknowledged. Click DARTS REMOVED to fire
  // _handleTakeoutFinished -> _handleGameWon, then pump past the 3s delay
  // AND give the route transition + results-screen build time to settle.
  await DartThrowHelpers.clickDartsRemoved(tester);
  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Pirate's Grid is supplied here. Darts are aimed at cell
// (0,0)'s target, whose requirement varies with the difficulty setting, so
// the number is read from the provider rather than hard-coded.

Future<void> _hitTopLeftCell(WidgetTester tester) async {
  final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
  await throwDartViaMock(tester, t00);
}

final pauseModalSpec = PauseModalSpec(
  config: config,
  menuBackButton: ElementFinders.getPiratesGridBackButton,
  ownGameCard: ElementFinders.getPiratesGridCard,
  menuSettingsControls: [ElementFinders.getPiratesGridDifficultyDropdown],
  menuAddPlayerButton: ElementFinders.getPiratesGridAddPlayerButtonEmptyState,
  startGame: (tester) => setupAndStartGame(tester, config),
  throwOneDart: _hitTopLeftCell,
  // A miss, not another cell hit — (0,0) is already claimed by then.
  throwAnotherDart: throwMissViaMock,
  throwTurnToTakeout: (tester) async {
    await _hitTopLeftCell(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
  },
  finishTakeout: clickDartsRemoved,
  openEditScore: (tester) => openEditScore(tester, config),
  reachResults: (tester) async {
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);
  },
  resultsAfterReconnect: (tester) async {
    await UITestHelpers.clickBackToMenu(tester, config);
    expect(ElementFinders.getPiratesGridCard(), findsOneWidget,
        reason: 'Back to Menu did not work after reconnect');
  },
);
