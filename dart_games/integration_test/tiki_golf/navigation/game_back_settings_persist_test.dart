// integration_test/tiki_golf/navigation/game_back_settings_persist_test.dart
//
// Test Nav-2 — Set Max Strokes=5 and Mulligan ON, TEE OFF, then back out of
//              the game (dismissing the Save modal if it appears) and assert
//              the menu still shows both settings and both players.
import 'package:integration_test/integration_test.dart';

import '../../shared/suites/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runGameBackSettingsPersistTest(navigationGameBackSpec,
      description:
          "Game back with Don't Save returns to menu with settings preserved");
}
