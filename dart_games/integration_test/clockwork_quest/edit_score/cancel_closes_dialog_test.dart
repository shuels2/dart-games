import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Cancel edit score closes dialog',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await throw3DartsAndWaitForTakeout(tester, target1: 1, target2: 2, target3: 3);

    await EditScoreHelpers.openEditScore(tester, config);
    await EditScoreHelpers.cancelEditScore(tester);

    // Dialog should be closed
    EditScoreHelpers.verifyDialogClosed();
  });
}
