import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/models/pirates_grid_game.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/pause_modal_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
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

Future<void> simulateDisconnectAndVerify(WidgetTester tester) =>
    PauseModalHelpers.simulateDisconnectAndVerify(tester);

Future<void> simulateReconnectAndVerify(WidgetTester tester) =>
    PauseModalHelpers.simulateReconnectAndVerify(tester);

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
}
