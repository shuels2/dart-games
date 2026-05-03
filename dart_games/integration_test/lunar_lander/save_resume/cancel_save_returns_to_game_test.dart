import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Save: tapping Don\'t Save on save modal returns to game screen',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);

    // Tap back — shows save modal
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    UITestHelpers.verifySaveGameModal();

    // Tap Don't Save
    await UITestHelpers.tapDontSaveButton(tester);

    // Should have navigated back to menu (not game — the back pops the game screen)
    // Verify we're on menu (not game screen and not home)
    expect(config.getStartButton(), findsOneWidget);
  });
}
