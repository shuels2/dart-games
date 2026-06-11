// integration_test/treasure_divide/save_resume/resume_modal_shows_on_game_tap_test.dart
//
// SaveResume-10 — ResumeGameModal auto-pops on initial menu entry when saves exist.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping game with saved games shows resume modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await SaveResumeHelpers.preSaveGame(GameSaveConfig.treasureDivide());
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    UITestHelpers.verifyResumeGameModal();
  });
}
