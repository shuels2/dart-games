// integration_test/tiki_golf/edit_score/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf edit-score tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';

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

Future<void> setupAndStartGame(
  WidgetTester tester, {
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      playerNames: playerNames,
    );

/// Miss every dart of the turn, ending it in a Splash.
Future<void> throwAllMissesToSplash(WidgetTester tester,
    {int maxStrokes = 3}) async {
  for (int i = 0; i < maxStrokes; i++) {
    await throwMissViaMock(tester);
  }
}
