import 'package:flutter_test/flutter_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/settings_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/settings_helpers.dart';

final config = GameUIConfig.piratesGrid();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  String difficulty = 'Easy',
  String bestOf = '1',
  bool stealMode = false,
  bool speedPlay = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartPiratesGrid(
      tester,
      config,
      difficulty: difficulty,
      bestOf: bestOf,
      stealMode: stealMode,
      speedPlay: speedPlay,
      playerNames: playerNames,
    );

Future<void> setDifficulty(WidgetTester tester, String value) =>
    SettingsHelpers.setPiratesGridDifficulty(tester, value);

Future<void> setBestOf(WidgetTester tester, String value) =>
    SettingsHelpers.setPiratesGridBestOf(tester, value);

Future<void> toggleStealMode(WidgetTester tester) =>
    SettingsHelpers.togglePiratesGridStealMode(tester);

Future<void> toggleSpeedPlay(WidgetTester tester) =>
    SettingsHelpers.togglePiratesGridSpeedPlay(tester);
