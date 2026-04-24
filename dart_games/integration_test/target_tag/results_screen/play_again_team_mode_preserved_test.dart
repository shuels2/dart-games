import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Play Again - Team Mode Settings and Team Assignment Preserved', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3
    await setShieldMax(tester, 3);

    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    await UITestHelpers.addPlayer(tester, 'TeamA1', config);
    await UITestHelpers.addPlayer(tester, 'TeamA2', config);
    await UITestHelpers.addPlayer(tester, 'TeamB1', config);
    await UITestHelpers.addPlayer(tester, 'TeamB2', config);

    await UITestHelpers.startGame(tester, config);

    await completeGameToVictoryTeamMode(tester, 'TeamA1', 'TeamB1');

    // Extra pumps to ensure results screen is fully rendered and interactive for team mode
    // Team mode requires significantly more time for all victory announcements and screen transition
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Verify results screen is visible before clicking
    expect(find.textContaining('WINNER'), findsOneWidget);
    expect(find.text('Target Tag Game Over'), findsOneWidget);

    // Click Play Again
    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget); // Verify button exists
    await tester.tap(playAgainButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // Longer wait for game restart
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Should restart in team mode
    expect(find.text('Target Tag Game On!'), findsOneWidget);
    expect(find.textContaining('Team'), findsWidgets);
  });
}
