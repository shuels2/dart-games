import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 3: Menu - Target Score Slider Range
  // Features: Target score configuration, slider bounds validation
  // UI Elements: Slider (20-250, 46 divisions), target score display text
  // Validates: Slider min/max values, target score text updates, range label
  testWidgets('Test 3: Target Score Range Validation', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    // Verify default target score display and range
    expect(find.textContaining('Target score:'), findsOneWidget);
    expect(find.text('Range: 20-250 points'), findsOneWidget);

    // Set target to 20 (minimum)
    await setTargetScore(tester, 20);
    expect(find.textContaining('Target score: 20'), findsOneWidget);

    // Set target to 250 (maximum)
    await setTargetScore(tester, 250);
    expect(find.textContaining('Target score: 250'), findsOneWidget);

    // Set target to 150 (middle)
    await setTargetScore(tester, 150);
    expect(find.textContaining('Target score: 150'), findsOneWidget);
  });
}
