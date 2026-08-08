// integration_test/tiki_golf/navigation/change_settings_back_to_home_test.dart
//
// Test Nav-3 — Play a game to completion, tap CHANGE COURSE on results,
//              assert menu loaded, then menu back arrow, assert home screen.
import 'package:integration_test/integration_test.dart';

import '../../shared/suites/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runChangeSettingsBackToHomeTest(navigationSpec,
      description:
          'Results change settings then menu back returns to home screen');
}
