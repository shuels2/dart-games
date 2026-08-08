import 'package:integration_test/integration_test.dart';

import '../../shared/suites/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runMenuBackToHomeTest(navigationSpec);
}
