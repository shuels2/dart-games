// integration_test/treasure_divide/save_resume/resume_button_shows_modal_test.dart
//
// SaveResume-9 — Tapping ResumeGameButton in AppBar shows the ResumeGameModal.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clicking button shows resume modal', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await SaveResumeHelpers.preSaveGame(GameSaveConfig.treasureDivide());
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Modal auto-pops on initial entry — dismiss it first
    UITestHelpers.verifyResumeGameModal();
    await UITestHelpers.tapStartNewGameButton(tester);
    expect(config.getStartButton(), findsOneWidget);

    // Tap resume button in AppBar
    final resumeButton =
        find.byKey(TreasureDivideMenuKeys.resumeGameButton);
    await tester.tap(resumeButton);
    await PumpSequences.asyncDataLoad(tester);

    UITestHelpers.verifyResumeGameModal();
  });
}
