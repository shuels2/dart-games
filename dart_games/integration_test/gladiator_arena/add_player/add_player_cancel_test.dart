import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Player: cancel does not add player', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    final initialCount =
        ProviderHelpers.getAllPlayers(tester).length;

    // Open dialog and cancel
    await tester
        .tap(ElementFinders.getGladiatorArenaAddPlayerButtonEmptyState());
    await PumpSequences.dialogOpen(tester);

    await tester.enterText(
        ElementFinders.getAddPlayerNameField(), 'TestGladiator');
    await PumpSequences.textEntry(tester);

    await tester.tap(ElementFinders.getAddPlayerCancelButton());
    await PumpSequences.dialogClose(tester);

    // Player count should be unchanged
    expect(ProviderHelpers.getAllPlayers(tester).length, initialCount);
  });
}
