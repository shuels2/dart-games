import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 8: Tagged In - Hit Own Target (PINK) - Validates player reaches tagged in status with max shields, on next turn player is tagged in, hitting own target while tagged in shows pink border (0xFFFF007A), dart color logic inverts when tagged in (own target becomes bad, opponent target becomes good)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'InvertLogic1', config);
    await UITestHelpers.addPlayer(tester, 'InvertLogic2', config);
    await UITestHelpers.startGame(tester, config);

    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    expect(player1Id, isNotNull);
    final player1 = ProviderHelpers.findPlayerById(tester, player1Id!);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id);

    // Player 1 Turn 1: Reach tagged in with triple, then 2 misses
    await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn
    await clickDartsRemoved(tester);

    // Verify player 2 is now current (using active player panel)
    final currentPlayerName = ElementFinders.getTargetTagActivePlayerNameText(tester);
    expect(currentPlayerName, equals('InvertLogic2'));

    // Player 2 Turn: Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Remove darts to advance turn
    await clickDartsRemoved(tester);

    // Verify player 1 is now current again (using active player panel)
    final currentPlayerName2 = ElementFinders.getTargetTagActivePlayerNameText(tester);
    expect(currentPlayerName2, equals('InvertLogic1'));
    // Verify still tagged in
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

    // Player 1 Turn 2: Hit own target (should be pink - bad when tagged in)
    final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
    await throwDartViaMock(tester, player1Target);

    // Shields should not change (hitting own target when tagged in is bad)
    final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
    expect(shieldsAfter, equals(shieldsBefore));

    // Verify D1 indicator has pink border (0xFFFF007A)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFF007A);
  });
}
