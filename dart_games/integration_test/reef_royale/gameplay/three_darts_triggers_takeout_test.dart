import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Three darts triggers takeout prompt',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 19);
    await throwDartViaMock(tester, 18);

    // After 3 darts, the remove darts modal should appear
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
  });
}
