// integration_test/treasure_divide/edit_score/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide edit-score tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> setupAndStartGame(
  WidgetTester tester, {
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      teamMode: teamMode,
      manualAssignment: manualAssignment,
      playerNames: playerNames,
    );
