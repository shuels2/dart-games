import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: cancel preserves original darts', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw 3 darts: D10, Miss, S5
    await throwDartViaMock(tester, 10, multiplier: 'double'); // D10 = 20
    await throwMissViaMock(tester);
    await throwDartViaMock(tester, 5, multiplier: 'single'); // S5 = 5

    // Open edit score dialog
    await openEditScore(tester, config);

    // Change dart 1 to something else
    await setDart1(tester, 'S1');

    // Cancel — original should be preserved
    await cancelEditScore(tester);

    // Edit dialog should be closed
    EditScoreHelpers.verifyDialogClosed();
    expect(ElementFinders.getEditScoreDialog(), findsNothing);
  });
}
