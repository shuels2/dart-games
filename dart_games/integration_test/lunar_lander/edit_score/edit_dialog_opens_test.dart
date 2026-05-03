import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: dialog opens when edit button is tapped',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Throw 3 darts so the RemoveDartsModal appears (the Edit Score button
    // lives inside the modal, which only renders after the turn ends per
    // spec §10B). Two misses + one scoring dart fills the turn.
    await throwDartViaMock(tester, 10);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Tap edit score button (inside the now-visible RemoveDartsModal)
    await openEditScore(tester);

    // Verify dialog is open with all three dart dropdowns
    expect(ElementFinders.getEditScoreDialog(), findsOneWidget);
    expect(ElementFinders.getEditScoreDart1Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreDart2Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreDart3Dropdown(), findsOneWidget);
    expect(ElementFinders.getEditScoreSaveButton(), findsOneWidget);
    expect(ElementFinders.getEditScoreCancelButton(), findsOneWidget);
  });
}
