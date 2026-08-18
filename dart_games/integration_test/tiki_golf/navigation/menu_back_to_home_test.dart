// integration_test/tiki_golf/navigation/menu_back_to_home_test.dart
//
// Test Nav-1 — From Tiki Golf menu, tap back arrow, assert home screen
//              with ≥3 game cards visible.
import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runMenuBackToHomeTest(navigationSpec,
      description: 'Menu back button returns to home screen with game cards');
}
