import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping game with saved games shows resume modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await preSaveGame();
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    UITestHelpers.verifyResumeGameModal();
  });
}
