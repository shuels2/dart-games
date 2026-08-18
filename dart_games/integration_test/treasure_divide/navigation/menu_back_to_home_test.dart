// integration_test/treasure_divide/navigation/menu_back_to_home_test.dart
//
// Test Nav-1 — From the Treasure Divide menu, tap back, assert home screen
//              with ≥3 game cards.
import 'package:integration_test/integration_test.dart';

import '../../shared/navigation_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runMenuBackToHomeTest(navigationSpec,
      description: 'Menu back button returns to home screen with game cards');
}
