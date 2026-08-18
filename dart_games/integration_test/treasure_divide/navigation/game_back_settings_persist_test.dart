// integration_test/treasure_divide/navigation/game_back_settings_persist_test.dart
//
// Test Nav-2 — Rounds=7 + Quarter It ON, SET SAIL, then back out of the game
//              and assert the menu still shows both settings and both crew.
import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runGameBackSettingsPersistTest(navigationSpec,
      description:
          "Game back with Don't Save returns to menu with settings preserved");
}
