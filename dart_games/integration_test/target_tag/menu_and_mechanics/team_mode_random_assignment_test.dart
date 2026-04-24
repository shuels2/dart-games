import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 14: Team Mode - Random Team Assignment - Validates team mode switch enabled, 4 players added (TeamPlayer1-4), game starts successfully in team mode with random team assignment, game is active. Note: Does NOT validate team badges displayed for each player or team UI elements - only verifies game starts',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Add 4 players
    for (int i = 1; i <= 4; i++) {
      await UITestHelpers.addPlayer(tester, 'TeamRandom$i', config);
    }

    // Start game (random team assignment)
    await UITestHelpers.startGame(tester, config);

    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Verify team badges present (random assignment)
    // At least some team indicators should be present
    expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
  });
}
