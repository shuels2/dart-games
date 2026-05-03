import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';

final config = GameUIConfig.lunarLander();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      playerNames: playerNames,
    );
