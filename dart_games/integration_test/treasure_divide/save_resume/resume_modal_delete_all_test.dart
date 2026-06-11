// integration_test/treasure_divide/save_resume/resume_modal_delete_all_test.dart
//
// SaveResume-13 — Delete all saved games shows the empty state in the modal.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete all saved games shows empty state', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.treasureDivide(),
      GameSaveConfig.treasureDivideSecond(),
    );
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    await UITestHelpers.deleteAllSavedGames(tester);

    expect(ElementFinders.getResumeGameModalEmptyState(), findsOneWidget);
  });
}
