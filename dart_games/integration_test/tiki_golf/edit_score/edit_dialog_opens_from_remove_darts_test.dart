import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

/// Edit Score dialog opens from RemoveDartsModal Edit Score button after
/// throwing all maxStrokes darts (turn ended → modal shows).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: dialog opens from RemoveDartsModal after 3 darts thrown',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_edit_score_dialog_opens_from_remove_darts',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester, maxStrokes: 3,
            playerNames: ['Alice', 'Bob']);

        // Throw all 3 darts (Splash) → turn ends → RemoveDartsModal shows
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Edit Score button should be in the modal
        final editButton = config.getEditScoreButton();
        expect(editButton, findsOneWidget,
            reason: 'Edit Score button should be visible in RemoveDartsModal');

        // Tap Edit Score → dialog opens
        await EditScoreHelpers.openEditScore(tester, config);

        // Dialog is open
        EditScoreHelpers.verifyDialogOpen();
      },
    );
  });
}
