// integration_test/tiki_golf/menu_and_settings/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf menu & settings tests.
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

final config = GameUIConfig.tikiGolf();

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

Future<void> navigateToMenu(WidgetTester tester) =>
    UITestHelpers.navigateToGameMenu(tester, config);

Future<void> setGameModeTeam(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfGameModeTeam(tester);

Future<void> setGameModeSolo(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfGameModeSolo(tester);

Future<void> setAssignmentManual(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfAssignmentManual(tester);

Future<void> setAssignmentRandom(WidgetTester tester) =>
    SettingsHelpers.setTikiGolfAssignmentRandom(tester);

Future<void> setMaxStrokes(WidgetTester tester, int maxStrokes) =>
    SettingsHelpers.setTikiGolfMaxStrokes(tester, maxStrokes);

Future<void> toggleMulligan(WidgetTester tester) =>
    SettingsHelpers.toggleTikiGolfMulligan(tester);
