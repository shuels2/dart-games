import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score dialog opens from Remove Darts modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw 3 darts so RemoveDartsModal appears
    await throwDartViaMock(tester, 10, multiplier: 'single'); // S10
    await throwMissViaMock(tester); // Miss
    await throwDartViaMock(tester, 5, multiplier: 'single'); // S5

    // Open Edit Score from the RemoveDartsModal
    await openEditScore(tester, config);

    // Verify dialog is open
    EditScoreHelpers.verifyDialogOpen();
    EditScoreHelpers.verifyDialogElements();

    // Cancel to clean up
    await cancelEditScore(tester);
  });
}
