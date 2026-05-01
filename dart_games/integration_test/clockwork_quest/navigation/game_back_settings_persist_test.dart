import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../results/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Game back button returns to menu with settings preserved',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Complete game then Play Again to get fresh game screen
    await completeGameToVictory(tester);
    await PumpSequences.fullRebuild(tester);
    expect(config.getPlayAgainButton(), findsOneWidget);
    await UITestHelpers.clickPlayAgain(tester, config);

    // Wait for game screen to fully render after Play Again
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Tap game back button (0 darts thrown in new game, no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify back on menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(), findsOneWidget);
    expect(ElementFinders.getClockworkQuestSpeedModeCheckbox(), findsOneWidget);
  });
}
