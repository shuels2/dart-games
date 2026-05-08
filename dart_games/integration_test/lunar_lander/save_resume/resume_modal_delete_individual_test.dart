import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete individual saved game removes it', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    final ids = await preSaveTwoGames();
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
        findsOneWidget);
    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
        findsOneWidget);

    await UITestHelpers.deleteSavedGameTile(tester, ids[0]);

    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
        findsNothing);
    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
        findsOneWidget);
  });
}
