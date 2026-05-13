import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';

final config = GameUIConfig.gladiatorArena();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      playerNames: playerNames,
    );
