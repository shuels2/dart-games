import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.reefRoyale();

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

Future<void> setupAndStartGame(WidgetTester tester, GameUIConfig config, {
  bool bonusBuffs = false,
  bool cursedTide = false,
  bool neighborNumbers = false,
}) =>
    // NOTE: `showHints` was removed from the helper signature when the
    // Show Hints menu toggle was deleted (hints are always on for new
    // games now). Callers that previously passed showHints:true can
    // just drop the named argument — the game starts with hints on
    // automatically.
    GameSetupHelpers.setupAndStartReefRoyale(
      tester,
      config,
      bonusBuffs: bonusBuffs,
      cursedTide: cursedTide,
      neighborNumbers: neighborNumbers,
    );
