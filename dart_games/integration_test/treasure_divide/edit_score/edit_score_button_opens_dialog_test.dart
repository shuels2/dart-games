// integration_test/treasure_divide/edit_score/edit_score_button_opens_dialog_test.dart
//
// Edit-1 — Edit Score button in the RemoveDartsModal opens the EditScoreDialog.
// Flow: start game, P1 throws 3 darts (all misses) → RemoveDartsModal shows →
// tap Edit Score → dialog opens → cancel → dialog dismissed.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: button opens dialog after 3 darts thrown',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        numberOfRounds: 9, playerNames: ['EditP1', 'EditP2']);

    // Throw 3 misses → shouldPromptTakeout=true → RemoveDartsModal shows
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Edit Score button should be visible in the RemoveDartsModal
    final editButton = find.byKey(TreasureDivideGameKeys.editScoreButton);
    expect(editButton, findsOneWidget,
        reason:
            '[DIAG td_edit_opens] Edit Score button not found in RemoveDartsModal');

    // Tap Edit Score → EditScoreDialog should open
    await EditScoreHelpers.openEditScore(tester, config);
    EditScoreHelpers.verifyDialogOpen();

    // Cancel → dialog closes
    await EditScoreHelpers.cancelEditScore(tester);
    EditScoreHelpers.verifyDialogClosed();
  });
}
