import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Play Again - Hero Bonus Setting Preserved', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3
    await setShieldMax(tester, 3);

    await SettingsHelpers.toggleTargetTagHeroBonus(tester);

    await UITestHelpers.addPlayer(tester, 'Hero1', config);
    await UITestHelpers.addPlayer(tester, 'Hero2', config);

    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester, 'Hero1', 'Hero2');

    // Click Play Again
    await ResultsHelpers.clickPlayAgain(tester, config);
    await tester.pump(const Duration(seconds: 3)); // Longer wait for game restart
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Should restart with hero bonus enabled
    expect(find.text('Target Tag Game On!'), findsOneWidget);
    expect(find.text('Hero1'), findsWidgets);
    expect(find.text('Hero2'), findsWidgets);
  });
}
