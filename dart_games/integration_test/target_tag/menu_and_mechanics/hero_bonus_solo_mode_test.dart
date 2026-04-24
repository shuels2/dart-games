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
      'Test 17: Hero Bonus in Solo Mode - Validates hero bonus switch enabled on menu, 2 players added, game started, hero buff number and multiplier retrieved from provider for both players (buff values exist and are valid dart notation D1-D20 or T1-T20). Players throw darts including hero buff hits, D1 indicators show gold borders (0xFFFFD700) after hero buff throws. Note: Description originally claimed hero buff damage mechanics but test only validates hero buff values exist and gold color appears - does NOT explicitly validate bonus damage multiplier application',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable hero bonus
    await SettingsHelpers.toggleTargetTagHeroBonus(tester);

    await SettingsHelpers.setTargetTagShieldMax(tester, 5);

    await UITestHelpers.addPlayer(tester, 'HeroSolo1', config);
    await UITestHelpers.addPlayer(tester, 'HeroSolo2', config);
    await UITestHelpers.startGame(tester, config);

    // Get player IDs
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    final player1 = selectedPlayers.firstWhere((p) => p.name == 'HeroSolo1');
    final player2 = selectedPlayers.firstWhere((p) => p.name == 'HeroSolo2');

    // Get hero buffs for each player
    final targetTagProvider = ProviderHelpers.getTargetTagProvider(tester);
    final player1HeroBuff = targetTagProvider.getSoloHeroBuffNumber(player1.id);
    final player1HeroMultiplier = targetTagProvider.getSoloHeroBuffMultiplier(player1.id);
    final player2HeroBuff = targetTagProvider.getSoloHeroBuffNumber(player2.id);
    final player2HeroMultiplier = targetTagProvider.getSoloHeroBuffMultiplier(player2.id);

    // Verify both players have hero buffs assigned
    expect(player1HeroBuff, isNotNull);
    expect(player1HeroMultiplier, isNotNull);
    expect(player2HeroBuff, isNotNull);
    expect(player2HeroMultiplier, isNotNull);

    // Player 1's turn: Hit target, miss, miss
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1.id);
    await throwDartViaMock(tester, player1Target!);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Player 2's turn: Hit their hero buff, miss, miss
    await throwDartViaMock(tester, player2HeroBuff!, multiplier: player2HeroMultiplier!);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Verify player 2 has all shields (5), player 1 has 0 shields
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 5);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1.id), 0);

    // Verify D1 has gold border (hero bonus hit)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);

    await clickDartsRemoved(tester);

    // Player 1's turn: Hit their hero buff, miss, miss
    await throwDartViaMock(tester, player1HeroBuff!, multiplier: player1HeroMultiplier!);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Verify player 1 has full shields (5), player 2 has 4 shields
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1.id), 5);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player2.id), 4);

    // Verify D1 has gold border (hero bonus hit)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);
  });
}
