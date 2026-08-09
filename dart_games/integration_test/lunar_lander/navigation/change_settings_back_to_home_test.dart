import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runChangeSettingsBackToHomeTest(navigationSpec,
      description: 'Navigation: change settings back to home');
}
