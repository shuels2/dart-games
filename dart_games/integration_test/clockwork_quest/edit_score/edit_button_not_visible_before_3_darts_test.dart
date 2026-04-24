import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Edit score button not visible before 3 darts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw only 2 darts
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 2);

    // Edit score button should NOT be visible yet
    final editButton = config.getEditScoreButton();
    expect(editButton, findsNothing);
  });
}
