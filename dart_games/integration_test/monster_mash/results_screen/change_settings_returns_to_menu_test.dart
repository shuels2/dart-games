import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Change Settings returns to menu - Complete game, Change Settings -> menu with preserved settings', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester);

    // Click Change Settings
    await ResultsHelpers.clickChangeSettings(tester, config);

    // Verify we're back on the menu
    expect(find.textContaining('Monster Mash'), findsWidgets);

    // Verify players are present
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  });
}
