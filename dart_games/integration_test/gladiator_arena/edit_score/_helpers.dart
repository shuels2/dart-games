import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';

final config = GameUIConfig.gladiatorArena();

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

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      targetScore: targetScore,
      doubleFinishEnabled: doubleFinishEnabled,
      shieldRoundEnabled: shieldRoundEnabled,
      speedPlayEnabled: speedPlayEnabled,
      playerNames: playerNames,
    );

Future<void> openEditScore(WidgetTester tester, GameUIConfig config) =>
    EditScoreHelpers.openEditScore(tester, config);

Future<void> setDart1(WidgetTester tester, String segment) =>
    EditScoreHelpers.setDart1(tester, segment);

Future<void> setDart2(WidgetTester tester, String segment) =>
    EditScoreHelpers.setDart2(tester, segment);

Future<void> setDart3(WidgetTester tester, String segment) =>
    EditScoreHelpers.setDart3(tester, segment);

Future<void> updateScore(WidgetTester tester) =>
    EditScoreHelpers.updateScore(tester);

Future<void> cancelEditScore(WidgetTester tester) =>
    EditScoreHelpers.cancelEditScore(tester);
