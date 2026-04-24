import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Edit score dialog opens with all elements',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    await throw3DartsAndWaitForTakeout(tester, target1: 1, target2: 2, target3: 3);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Verify dialog has all elements
    EditScoreHelpers.verifyDialogElements();
  });
}
