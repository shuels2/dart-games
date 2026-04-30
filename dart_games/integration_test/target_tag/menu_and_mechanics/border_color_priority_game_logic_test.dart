import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 12: Border Color Priority Order - Game Logic Only - Validates basic dart game logic (hitting own target increases shields, throwing miss does not change shields) with 2 players. Note: Does NOT validate any visual dart border colors or priority hierarchy - implementation comment states "Visual validation of colors would require screenshot testing. For now, verify game logic is correct". Only game mechanics tested, not visual display',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await SettingsHelpers.setTargetTagShieldMax(tester, 5);

    await UITestHelpers.addPlayer(tester, 'Priority1', config);
    await UITestHelpers.addPlayer(tester, 'Priority2', config);
    await UITestHelpers.startGame(tester, config);

    // Test various scenarios - verify game logic
    final player1Id = ProviderHelpers.getTargetTagCurrentPlayerId(tester);
    final player1Target = ProviderHelpers.getTargetTagPlayerTarget(tester, player1Id!);

    // Hit own target (should build shields)
    await throwDartViaMock(tester, player1Target!);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), greaterThan(0));

    // Miss (no change)
    final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, player1Id);
    await throwMissViaMock(tester);
    expect(ProviderHelpers.getTargetTagPlayerShields(tester, player1Id), equals(shieldsBefore));

    // Visual validation of colors would require screenshot testing
    // For now, verify game logic is correct
  });
}
