import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../shared/dart_throw_helpers.dart';
import '../shared/pump_sequences.dart';
import '../shared/game_ui_config.dart';
import '../shared/game_setup_helpers.dart';
import '../shared/provider_helpers.dart';

export '../shared/ui_test_helpers.dart';
export '../shared/element_finders.dart';
export '../shared/pump_sequences.dart';

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

/// Complete the game to victory by planting flags in a winning line for P1.
///
/// Pirate's Grid (Easy, Bo1): P1 needs 3 in a row.
/// Strategy: throw S20, S18, S16 → row 0 win.
/// After each turn, P2 misses all 3 darts.
Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getPiratesGridProvider(tester);

  for (int attempt = 0; attempt < 20; attempt++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.currentGame?.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final p1Id = provider.currentGame!.playerIds[0];

    if (currentPlayerId == p1Id) {
      // P1: throw singles on row-0 targets (20, 18, 16) to win row 0
      await throwDartViaMock(tester, 20);
      if (provider.hasWinner) break;
      await throwDartViaMock(tester, 18);
      if (provider.hasWinner) break;
      await throwDartViaMock(tester, 16);
    } else {
      // P2: throw misses
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
    // Final takeout to trigger navigation to results
    await clickDartsRemoved(tester);
  } else {
    await clickDartsRemoved(tester);
  }

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
