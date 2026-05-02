import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

final config = GameUIConfig.carnivalDerby();
const gameType = 'carnival_derby';

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> throwOneDart(WidgetTester tester) =>
    DartThrowHelpers.throwDartViaMock(tester, 20);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.carnivalDerby());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.carnivalDerby(),
      GameSaveConfig.carnivalDerbySecond(),
    );
