import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
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
    await SettingsHelpers.setCarnivalDerbyTargetScore(tester, '201');
    await SettingsHelpers.toggleCarnivalDerbyPerfectFinish(tester);

    // Add players and start game
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    // Tap game back button (0 darts thrown, no save modal)
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.navigation(tester);

    // Verify back on menu with settings preserved
    expect(config.getStartButton(), findsOneWidget);
    expect(find.textContaining('201'), findsOneWidget);
  });
}
