import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/save_resume_helpers.dart';

final config = GameUIConfig.piratesGrid();
const gameType = 'pirates_grid';

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

/// Throw one dart at cell [0,0] — uses the cell-target lookup so PG's
/// randomized targets work correctly.
Future<void> throwOneDart(WidgetTester tester) async {
  final t = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
  await DartThrowHelpers.throwDartViaMock(tester, t);
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig gameConfig, {
  List<String> playerNames = const ['Alice', 'Bob'],
}) =>
    SaveResumeHelpers.navigateToGameScreen(
      tester,
      gameConfig,
      playerNames: playerNames,
    );

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.piratesGrid());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.piratesGrid(),
      GameSaveConfig.piratesGridSecond(),
    );
