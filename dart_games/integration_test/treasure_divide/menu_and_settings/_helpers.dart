// integration_test/treasure_divide/menu_and_settings/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide menu & settings tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> navigateToMenu(WidgetTester tester) =>
    UITestHelpers.navigateToGameMenu(tester, config);

Future<void> addPlayer(WidgetTester tester, String name) =>
    UITestHelpers.addPlayer(tester, name, config);

Future<void> startGame(WidgetTester tester) =>
    UITestHelpers.startGame(tester, config);

Future<void> setGameModeTeam(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideGameModeTeam(tester);

Future<void> setGameModeSolo(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideGameModeSolo(tester);

Future<void> setAssignmentManual(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideAssignmentManual(tester);

Future<void> setAssignmentRandom(WidgetTester tester) =>
    SettingsHelpers.setTreasureDivideAssignmentRandom(tester);

Future<void> selectRounds(WidgetTester tester, int rounds) =>
    SettingsHelpers.selectTreasureDivideRounds(tester, rounds);

Future<void> toggleQuarterIt(WidgetTester tester) =>
    SettingsHelpers.toggleTreasureDivideQuarterIt(tester);

Future<void> toggleCustomTargets(WidgetTester tester) =>
    SettingsHelpers.toggleTreasureDivideCustomTargets(tester);

Future<void> selectCrews(WidgetTester tester, int crews) =>
    SettingsHelpers.selectTreasureDivideCrews(tester, crews);
