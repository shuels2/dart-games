import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/widgets/resume_game_button.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clicking button shows resume modal', (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // LL's ResumeGameButton has no key — locate it by type.
    final resumeButton = find.byType(ResumeGameButton);
    await tester.tap(resumeButton);
    await PumpSequences.asyncDataLoad(tester);

    UITestHelpers.verifyResumeGameModal();
  });
}
