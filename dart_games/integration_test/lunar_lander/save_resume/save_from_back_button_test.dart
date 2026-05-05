import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Save: back button after darts thrown shows save modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, config);

    UITestHelpers.verifySaveGameModal();

    // Dismiss modal to avoid state bleed
    await UITestHelpers.tapDontSaveButton(tester);
  });
}
