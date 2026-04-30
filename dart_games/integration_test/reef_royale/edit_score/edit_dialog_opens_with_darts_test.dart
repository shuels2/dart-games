import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Edit score dialog opens with current darts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 19);
    await throwDartViaMock(tester, 18);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Tap edit score
    final editButton = config.getEditScoreButton();
    await tester.tap(editButton);
    await PumpSequences.dialogOpen(tester);

    // Dialog should be visible
    expect(ElementFinders.getEditScoreDialog(), findsOneWidget);
  });
}
