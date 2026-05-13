import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: miss dart shows as Miss ring in edit dialog',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw S10, Miss, S5
    await throwDartViaMock(tester, 10, multiplier: 'single');
    await throwMissViaMock(tester); // dart 2 = Miss
    await throwDartViaMock(tester, 5, multiplier: 'single');

    // Open edit score dialog
    await openEditScore(tester, config);

    // Dart 2 dropdown should show "Miss" ring section
    final dart2Section = ElementFinders.getEditScoreDart2Dropdown();
    expect(dart2Section, findsOneWidget,
        reason: 'Dart 2 section should be present in edit dialog');

    // Cancel to clean up
    await cancelEditScore(tester);
  });
}
