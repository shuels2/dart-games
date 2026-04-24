import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('back button after darts thrown shows save modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, config);

    UITestHelpers.verifySaveGameModal();

    // Dismiss the modal so this test leaves no widget tree state that
    // could bleed into the next test (lingering provider listeners and
    // postFrameCallbacks would otherwise fire against the next test's
    // freshly-reset server and corrupt its state).
    await UITestHelpers.tapDontSaveButton(tester);
  });
}
