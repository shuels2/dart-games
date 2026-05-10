import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: whitespace-only name keeps dialog open',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open dialog
    await tester
        .tap(ElementFinders.getGladiatorArenaAddPlayerButtonEmptyState());
    await PumpSequences.dialogOpen(tester);

    // Enter whitespace only
    await tester.enterText(
        ElementFinders.getAddPlayerNameField(), '   ');
    await PumpSequences.textEntry(tester);

    // Try to submit
    await tester.tap(ElementFinders.getAddPlayerAddButton());
    await PumpSequences.simpleUpdate(tester);

    // Dialog should still be visible
    expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

    // Clean up
    await tester.tap(ElementFinders.getAddPlayerCancelButton());
    await PumpSequences.dialogClose(tester);
  });
}
