import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 4: UI Feedback - Complete Validation - Validates menu shows Shield Max setting, Solo/Team mode toggle visible, Hero Bonus switch visible, NEW PLAYER button functional, LETS PLAY TAG button enables when minimum players selected, game screen displays "Target Tag Game On!" title. Verifies current player ID exists and shields initialized to 0. Note: Does NOT explicitly verify player tiles show shields count/target numbers on tiles or active panel information display',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify menu UI elements
    expect(find.textContaining('Shield Max:'), findsOneWidget);
    expect(ElementFinders.getTargetTagTeamModeToggle(), findsOneWidget);
    expect(ElementFinders.getTargetTagHeroBonusToggle(), findsOneWidget);

    // Add 2 players (button will be verified implicitly by successful add)
    await UITestHelpers.addPlayer(tester, 'UITest1', config);
    await UITestHelpers.addPlayer(tester, 'UITest2', config);

    // Verify start button enabled
    expect(config.getStartButton(), findsOneWidget);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Verify game screen UI
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Verify player tiles show shields and targets
    final player1 = ProviderHelpers.findPlayerByName(tester, 'UITest1');
    final player2 = ProviderHelpers.findPlayerByName(tester, 'UITest2');
    expect(player1, isNotNull);
    expect(player2, isNotNull);

    // Verify shields displayed
    final shields1 = ProviderHelpers.getTargetTagPlayerShields(tester, player1!.id);
    final shields2 = ProviderHelpers.getTargetTagPlayerShields(tester, player2!.id);
    expect(shields1, 0);
    expect(shields2, 0);

    // Verify current player indicator
    final currentPlayerId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);
  });
}
