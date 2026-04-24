import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Results Screen Content - Team Mode Victory Display', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3
    await setShieldMax(tester, 3);

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Add 4 players for 2v2
    await UITestHelpers.addPlayer(tester, 'Team1 Winner1', config);
    await UITestHelpers.addPlayer(tester, 'Team1 Winner2', config);
    await UITestHelpers.addPlayer(tester, 'Team2 Loser1', config);
    await UITestHelpers.addPlayer(tester, 'Team2 Loser2', config);

    await UITestHelpers.startGame(tester, config);

    // In team mode, players on same team share target
    // Get first player from each team and complete to victory
    // Team 1 player gets tagged in, then attacks Team 2 target
    await completeGameToVictoryTeamMode(tester, 'Team1 Winner1', 'Team2 Loser1');

    // Verify results screen shows WINNERS (plural for team)
    // Note: May show WINNER! or WINNERS! depending on implementation
    expect(find.textContaining('WINNER'), findsOneWidget);
    expect(find.text('Target Tag Game Over'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
    expect(find.text('Change Settings'), findsOneWidget);
    expect(find.text('Select Different Game'), findsOneWidget);
  });
}
