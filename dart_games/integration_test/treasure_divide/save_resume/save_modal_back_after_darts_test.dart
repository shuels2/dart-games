// integration_test/treasure_divide/save_resume/save_modal_back_after_darts_test.dart
//
// SaveResume-4 — Back after throwing darts shows the save modal.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('back button after darts thrown shows save modal', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 15);

    await UITestHelpers.tapGameScreenBackButton(tester, config);

    UITestHelpers.verifySaveGameModal();

    // Dismiss to leave no lingering widget state
    await UITestHelpers.tapDontSaveButton(tester);
  });
}
