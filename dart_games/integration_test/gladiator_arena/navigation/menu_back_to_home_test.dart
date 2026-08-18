import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runMenuBackToHomeTest(navigationSpec,
      description: 'Navigation: menu back button returns to home screen',
      verifyMenuFirst: true);
}
