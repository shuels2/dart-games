import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

export '../../shared/provider_helpers.dart';
export '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.clockworkQuest();

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

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  bool speedMode = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartClockworkQuest(
      tester,
      config,
      includeBullseye: includeBullseye,
      speedMode: speedMode,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> throw3DartsAndWaitForTakeout(WidgetTester tester,
    {int target1 = 0, int target2 = 0, int target3 = 0}) async {
  if (target1 > 0) {
    await throwDartViaMock(tester, target1);
  } else {
    await throwMissViaMock(tester);
  }
  if (target2 > 0) {
    await throwDartViaMock(tester, target2);
  } else {
    await throwMissViaMock(tester);
  }
  if (target3 > 0) {
    await throwDartViaMock(tester, target3);
  } else {
    await throwMissViaMock(tester);
  }
}
