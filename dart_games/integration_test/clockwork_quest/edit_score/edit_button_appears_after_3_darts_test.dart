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

    // Throw 3 darts (hits on targets 1, 2, 3)
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 2);
    await throwDartViaMock(tester, 3);

    // Edit score button should be visible in the takeout prompt
    final editButton = config.getEditScoreButton();
    expect(editButton, findsOneWidget);
  });
}
