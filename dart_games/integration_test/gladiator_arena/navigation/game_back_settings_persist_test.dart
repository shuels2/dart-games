import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runGameBackSettingsPersistTest(navigationSpec,
      description:
          'Navigation: game back button returns to menu and settings persist');
}
