import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/results_helpers.dart';
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

Future<void> clickPlayAgain(WidgetTester tester) =>
    ResultsHelpers.clickPlayAgain(tester, config);

Future<void> clickChangeSettings(WidgetTester tester) =>
    ResultsHelpers.clickChangeSettings(tester, config);

Future<void> clickBackToMenu(WidgetTester tester) =>
    ResultsHelpers.clickSelectDifferentGame(tester, config);

// ===== GAME-SPECIFIC HELPERS =====

/// Complete the game to victory (P1 wins row 0: S20+S18+S16)
Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getPiratesGridProvider(tester);

  for (int attempt = 0; attempt < 20; attempt++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.currentGame?.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final p1Id = provider.currentGame!.playerIds[0];

    if (currentPlayerId == p1Id) {
      await throwDartViaMock(tester, 20);
      if (provider.hasWinner) break;
      await throwDartViaMock(tester, 18);
      if (provider.hasWinner) break;
      await throwDartViaMock(tester, 16);
    } else {
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

  await clickDartsRemoved(tester);

  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await PumpSequences.fullRebuild(tester);
}
