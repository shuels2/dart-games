// integration_test/treasure_divide/save_resume/save_modal_back_0_darts_test.dart
//
// SaveResume-3 — Back with 0 darts thrown skips the save modal entirely.
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
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);

    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    expect(ElementFinders.getSaveGameModalOverlay(), findsNothing);
    expect(config.getStartButton(), findsOneWidget);
  });
}
