// integration_test/treasure_divide/add_player/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide add-player tests.
import 'package:flutter_test/flutter_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.treasureDivide();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> navigateToMenu(WidgetTester tester) =>
    UITestHelpers.navigateToGameMenu(tester, config);

Future<void> addPlayer(WidgetTester tester, String name) =>
    UITestHelpers.addPlayer(tester, name, config);
