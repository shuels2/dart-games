import 'package:flutter_test/flutter_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/play_to_complete_helpers.dart';
export '../../shared/provider_helpers.dart';

final config = GameUIConfig.lunarLander();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int altitude = 200,
  bool hardLanding = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: altitude,
      hardLanding: hardLanding,
      playerNames: playerNames,
    );

Future<void> tapPlayToComplete(WidgetTester tester) =>
    PlayToCompleteHelpers.tapPlayToComplete(tester);

Future<void> waitForGameCompletion(
  WidgetTester tester, {
  required bool Function() isComplete,
  int maxIterations = 500,
}) =>
    PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: isComplete,
      maxIterations: maxIterations,
    );
