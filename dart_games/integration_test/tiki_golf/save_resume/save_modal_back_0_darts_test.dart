import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('back button with 0 darts navigates without save modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    expect(ElementFinders.getSaveGameModalOverlay(), findsNothing);
    expect(config.getStartButton(), findsOneWidget);
  });
}
