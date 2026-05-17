// integration_test/tiki_golf/save_resume/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf save/resume tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_helpers.dart';

final config = GameUIConfig.tikiGolf();
const gameType = 'tiki_golf';

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

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.tikiGolf());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.tikiGolf(),
      GameSaveConfig.tikiGolfSecond(),
    );

// One-dart helper that throws the first hole's target on dart 1 (Birdie).
// Use for pre-save setup to advance game state before saving.
Future<void> throwOneDart(WidgetTester tester) async {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
  await throwDartViaMock(tester, target);
}
