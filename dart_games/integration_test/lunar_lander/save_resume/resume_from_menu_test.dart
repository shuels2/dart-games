import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Resume: pre-saved game shows resume modal on menu open',
      (tester) async {
    await UITestHelpers.resetServerState();
    await preSaveGame();

    // Navigate to game menu (will trigger resume modal since saved game exists)
    await UITestHelpers.navigateToGameMenu(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Resume modal should be visible
    UITestHelpers.verifyResumeGameModal();
  });
}
