// integration_test/tiki_golf/navigation/change_settings_preserves_settings_test.dart
//
// Max Strokes=5 + Mulligan ON survive the results-screen Change Settings
// round trip, along with the two players.
import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runChangeSettingsPreservesSettingsTest(navigationSettingsSpec,
      description:
          'Change Settings preserves Max Strokes and Mulligan and players after victory');
}
