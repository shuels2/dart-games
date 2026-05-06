import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
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

// ===== GAME-SPECIFIC HELPERS =====

/// Fill the grid to produce a draw:
/// Place flags alternately so no 3-in-a-row occurs.
/// Pattern (P1=A, P2=B):
///   A B A
///   B A B
///   B A B  ← no 3-in-a-row for either player
Future<void> fillGridForDraw(WidgetTester tester) async {
  final provider = ProviderHelpers.getPiratesGridProvider(tester);
  if (provider.currentGame == null) return;

  final p1Id = provider.currentGame!.playerIds[0];
  final p2Id = provider.currentGame!.playerIds[1];

  ProviderHelpers.setPiratesGridGameState(tester, claimedBy: [
    [p1Id, p2Id, p1Id],
    [p2Id, p1Id, p2Id],
    [p2Id, p1Id, p2Id],
  ]);
  // Force the round-end detection by simulating the last dart
  // The grid is now full — we simulate by throwing a dart that doesn't match
  // any empty cell (grid full → isDraw will be set in _checkRoundEnd).
  // Instead, set isDraw directly for the test:
  provider.currentGame!.isDraw = true;
  provider.currentGame!.winnerId = null;
  provider.notifyListeners();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}
