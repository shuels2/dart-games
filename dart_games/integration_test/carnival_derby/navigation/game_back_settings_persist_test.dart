import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../ui/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Game back button returns to menu with settings preserved',
      (WidgetTester tester) async {
    await navigateToCarnivalDerbyMenu(tester);

    // Set target score for quick win
    await setTargetScore(tester, 180);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await startGame(tester);

    // Complete game then Play Again to get fresh game screen
    await completeGameToVictory(tester);
    await UITestHelpers.clickPlayAgain(tester, config);

    // Tap game back button (0 darts thrown in new game, no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify back on menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    expect(find.textContaining('180'), findsOneWidget);
  });
}
