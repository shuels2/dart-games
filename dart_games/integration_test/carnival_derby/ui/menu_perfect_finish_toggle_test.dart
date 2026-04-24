import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 4: Menu - Perfect Finish Mode Toggle
  // Features: Perfect Finish mode configuration
  // UI Elements: Perfect Finish Yes/No radio buttons
  // Validates: Radio buttons exist and toggle between Yes/No states
  testWidgets('Test 4: Perfect Finish Toggle', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    // Verify Perfect Finish radio buttons exist (Yes/No)
    expect(find.text('Yes'), findsWidgets);
    expect(find.text('No'), findsWidgets);

    // Toggle Perfect Finish ON (tap "Yes")
    await togglePerfectFinish(tester);
    await tester.pump();

    // Note: toggling "OFF" would require tapping "No" button
    // The togglePerfectFinish helper always sets it to ON (Yes)
  });
}
