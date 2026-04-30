import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Results content - single winner - Winner name via key, all 3 action buttons visible', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Complete game
    await completeGameToVictory(tester);

    // Verify winner name
    final winnerName = ElementFinders.getMonsterMashWinnerName();
    expect(winnerName, findsOneWidget);

    // Verify all 3 action buttons
    expect(config.getPlayAgainButton(), findsOneWidget);
    expect(config.getChangeSettingsButton(), findsOneWidget);
    expect(config.getBackToMenuButton(), findsOneWidget);
  });
}
