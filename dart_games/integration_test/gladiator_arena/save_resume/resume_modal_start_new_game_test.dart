import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Start New Game button in resume modal dismisses modal',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Pre-save a game then navigate to menu
    await preSaveGame();
    await UITestHelpers.navigateToGameMenu(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Tap Start New Game
    final startNewBtn = ElementFinders.getResumeGameModalStartNewButton();
    expect(startNewBtn, findsOneWidget);
    await tester.tap(startNewBtn);
    await PumpSequences.dialogClose(tester);

    // Modal should be gone, menu visible
    expect(ElementFinders.getResumeGameModalOverlay(), findsNothing);
    expect(config.getStartButton(), findsOneWidget);
  });
}
