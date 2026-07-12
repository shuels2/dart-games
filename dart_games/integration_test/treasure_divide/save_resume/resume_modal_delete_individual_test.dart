// integration_test/treasure_divide/save_resume/resume_modal_delete_individual_test.dart
//
// SaveResume-12 — Deleting one saved tile removes it while the other remains.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete individual saved game removes it', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    final ids = await SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.treasureDivide(),
      GameSaveConfig.treasureDivideSecond(),
    );
    await UITestHelpers.tapGameCard(tester, config);
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
