import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Back to Menu returns home - Complete game, Back to Menu -> home screen', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    await completeGameToVictory(tester);

    // Click Back to Menu
    await ResultsHelpers.clickBackToMenu(tester, config);

    // Verify we're on the home screen
    expect(find.textContaining('Dart Games'), findsWidgets);
  });
}
