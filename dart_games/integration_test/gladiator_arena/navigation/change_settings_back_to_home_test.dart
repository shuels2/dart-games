// Gladiator's "change settings" navigation case is a plain menu → back → home
// check (it never plays a game), so it runs the same shared body as Nav-1.
import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runMenuBackToHomeTest(navigationSpec,
      description: 'Navigation: back from menu returns to home screen',
      verifyMenuFirst: true);
}
