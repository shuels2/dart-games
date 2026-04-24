import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 9: Tagged In - Successfully Attack Opponent (GOLD) - Validates Player 1 gets tagged in with max shields, Player 2 builds partial shields (not tagged in), Player 1 on next turn hits Player 2 target shows gold border (0xFFFFD700), successful opponent attack reduces opponent shields, dart color correctly indicates successful attack (gold for hitting opponent while tagged in)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Attacker', config);
    await UITestHelpers.addPlayer(tester, 'Defender', config);
    await UITestHelpers.startGame(tester, config);

    // Player 1 reaches tagged in
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    // Build shields to max (3 shields in a single triple throw)
    await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

    // Throw 2 more darts to end the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn
    await clickDartsRemoved(tester);

    // Player 2 builds partial shields
    final player2 = ProviderHelpers.getSelectedPlayers(tester).firstWhere((p) => p.id != player1Id);
    final player2Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player2.id);

    await throwDartViaMock(tester, player2Target!);
    await throwDartViaMock(tester, player2Target);

    final player2Shields = ProviderHelpers.getTargetTagPlayerShields(tester, player2.id);
    expect(player2Shields, 2);

    // Player 2 ends turn
    await throwMissViaMock(tester);

    // Remove darts to advance turn
    await clickDartsRemoved(tester);

    // Player 1 attacks Player 2
    final currentId = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, currentId!), isTrue);

    await throwDartViaMock(tester, player2Target);

    // Verify Player 2 shields reduced
    final player2ShieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player2.id);
    expect(player2ShieldsAfter, equals(player2Shields - 1));

    // Verify D1 indicator has gold border (0xFFFFD700)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);
  });
}
