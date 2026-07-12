// integration_test/treasure_divide/save_resume/resume_modal_start_new_game_test.dart
//
// SaveResume-11 — Start New Game in the resume modal dismisses it and shows menu.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Start New Game dismisses modal and shows menu', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await SaveResumeHelpers.preSaveGame(GameSaveConfig.treasureDivide());
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    await UITestHelpers.tapStartNewGameButton(tester);

    expect(config.getStartButton(), findsOneWidget);
  });
}
