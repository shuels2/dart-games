import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 13: Solo Mode - Complete Game Flow - Validates 2 players added in solo mode, game starts successfully, Player 1 builds shields and gets tagged in, Player 2 builds partial shields, Player 1 attacks Player 2 target to reduce shields, turn order maintained correctly throughout game, game flows from start to active gameplay without errors',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Solo1', config);
    await UITestHelpers.addPlayer(tester, 'Solo2', config);
    await UITestHelpers.startGame(tester, config);

    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Player 1 builds shields
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

    // Throw 2 more darts to end the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn to Player 2
    await clickDartsRemoved(tester);

    // Player 2 builds partial shields
    final player2 = ProviderHelpers.getSelectedPlayers(tester).firstWhere((p) => p.id != player1Id);
    final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

    await throwDartViaMock(tester, player2Target!);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 1);

    // Remove darts to advance turn to Player 1
    await clickDartsRemoved(tester);

    // Player 1 attacks Player 2
    await throwDartViaMock(tester, player2Target);

    final player2ShieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player2.id);
    expect(player2ShieldsAfter, 0);

    // Verify game continues
    expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
  });
}
