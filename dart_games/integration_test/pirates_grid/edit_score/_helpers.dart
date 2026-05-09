import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/edit_score_helpers.dart';
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

Future<void> openEditScore(WidgetTester tester) =>
    EditScoreHelpers.openEditScore(tester, config);

Future<void> updateScore(WidgetTester tester) =>
    EditScoreHelpers.updateScore(tester);

Future<void> cancelEditScore(WidgetTester tester) =>
    EditScoreHelpers.cancelEditScore(tester);

// ===== GAME-SPECIFIC HELPERS =====

/// Set up game state for edit-creates-winner test:
/// P1 has 2 cells in row 0 (cells [0,0] and [0,1] claimed).
/// P1 needs [0,2] to win. Target for [0,2] is 16 (Easy difficulty).
Future<void> setupNearWinState(WidgetTester tester) async {
  final provider = ProviderHelpers.getPiratesGridProvider(tester);
  if (provider.currentGame == null) return;

  final p1Id = provider.currentGame!.playerIds[0];
  // Claim row 0, cols 0 and 1 for P1 directly
  ProviderHelpers.setPiratesGridGameState(tester, claimedBy: [
    [p1Id, p1Id, null],  // row 0: P1 has cols 0 and 1, col 2 empty
    [null, null, null],   // row 1: all empty
    [null, null, null],   // row 2: all empty
  ]);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}
