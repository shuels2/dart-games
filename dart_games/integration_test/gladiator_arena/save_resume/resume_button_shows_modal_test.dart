import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/widgets/resume_game_button.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping resume button shows resume modal', (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Tap resume button
    final resumeButton = find.byType(ResumeGameButton);
    await tester.tap(resumeButton);
    await PumpSequences.asyncDataLoad(tester);

    // Modal should be visible
    expect(ElementFinders.getResumeGameModalOverlay(), findsOneWidget);
    expect(ElementFinders.getResumeGameModalTitle(), findsOneWidget);
    expect(ElementFinders.getResumeGameModalSavedGamesList(), findsOneWidget);
  });
}
