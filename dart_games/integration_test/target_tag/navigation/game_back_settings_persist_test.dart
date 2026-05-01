import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Game back button returns to menu with settings preserved',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Change settings to non-default values
    await SettingsHelpers.setTargetTagShieldMax(tester, 5);
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Add players and start game
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);
    await UITestHelpers.addPlayer(tester, 'Player D', config);
    await UITestHelpers.startGame(tester, config);

    // Tap game back button (0 darts thrown, no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify back on menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    expect(find.text('Shield Max: 5'), findsOneWidget);
    // Team mode should still be toggled on
    expect(find.textContaining('Team Mode'), findsOneWidget);
  });
}
