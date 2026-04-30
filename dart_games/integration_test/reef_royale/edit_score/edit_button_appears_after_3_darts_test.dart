import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Edit score button appears after 3 darts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 19);
    await throwDartViaMock(tester, 18);

    // Wait for takeout prompt
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Edit score button should be visible
    final editButton = config.getEditScoreButton();
    expect(editButton, findsOneWidget);
  });
}
