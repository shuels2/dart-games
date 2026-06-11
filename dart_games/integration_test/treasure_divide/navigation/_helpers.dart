// integration_test/treasure_divide/navigation/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide navigation tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/results_helpers.dart';

final config = GameUIConfig.treasureDivide();

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

Future<void> setupAndStartGame(
  WidgetTester tester, {
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      playerNames: playerNames,
    );
