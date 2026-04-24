import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 10: Hero Bonus Toggle - Basic Validation - Validates hero bonus can be enabled on menu, shield max set to 3, 2 players added, player reaches tagged in status (game is active). Note: Does NOT validate hitting hero buff number, does NOT validate gold border (0xFFFFD700) or pulsing glow effect, does NOT validate hero buff damage mechanics - test only confirms game starts with hero bonus enabled',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Enable hero bonus
    await SettingsHelpers.toggleTargetTagHeroBonus(tester);

    await SettingsHelpers.setTargetTagShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'HeroTest1', config);
    await UITestHelpers.addPlayer(tester, 'HeroTest2', config);
    await UITestHelpers.startGame(tester, config);

    // Reach tagged in
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    await throwDartViaMock(tester, player1Target!, multiplier: 'triple');
    expect(ProviderHelpers.isTargetTagPlayerTaggedIn(tester, player1Id), isTrue);

    // Hero bonus is active - verify game continues
    // (Visual testing of gold pulsing would require screenshot comparison)
    expect(ProviderHelpers.isTargetTagGameActive(tester), isTrue);
  });
}
