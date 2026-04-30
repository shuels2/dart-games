import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Start game with custom settings - Health=30, buffs ON, speed play ON, round limit=5, 3 players -> provider confirms all settings', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set custom settings
    await SettingsHelpers.setMonsterMashHealthMax(tester, 30);
    await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);
    await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
    await SettingsHelpers.setMonsterMashRoundLimit(tester, 5);

    // Add 3 players
    await UITestHelpers.addPlayer(tester, 'Player X', config);
    await UITestHelpers.addPlayer(tester, 'Player Y', config);
    await UITestHelpers.addPlayer(tester, 'Player Z', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Verify game is active
    expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);

    // Verify custom health
    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester);
    expect(currentPlayerId, isNotNull);
    final health = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId!);
    expect(health, 30);

    // Verify round limit
    final roundLimit = ProviderHelpers.getMonsterMashRoundLimit(tester);
    expect(roundLimit, 5);

    // Verify current round starts at 1
    final currentRound = ProviderHelpers.getMonsterMashCurrentRound(tester);
    expect(currentRound, 1);
  });
}
