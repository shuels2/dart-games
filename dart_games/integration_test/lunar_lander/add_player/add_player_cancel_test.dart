import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: cancel closes dialog without adding player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Open the add player dialog
    final addButton = ElementFinders.getLunarLanderAddPlayerButtonEmptyState();
    if (addButton.evaluate().isEmpty) {
      final normalButton = ElementFinders.getLunarLanderAddPlayerButton();
      await tester.tap(normalButton);
    } else {
      await tester.tap(addButton);
    }
    await PumpSequences.dialogOpen(tester);

    // Verify dialog is open
    expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

    // Enter a name
    await tester.enterText(ElementFinders.getAddPlayerNameField(), 'Cancelled Astronaut');
    await PumpSequences.textEntry(tester);

    // Cancel instead of adding
    await tester.tap(ElementFinders.getAddPlayerCancelButton());
    await PumpSequences.dialogClose(tester);

    // Dialog should be closed
    expect(ElementFinders.getAddPlayerDialog(), findsNothing);

    // Player should not have been added
    expect(find.text('Cancelled Astronaut'), findsNothing);
  });
}
