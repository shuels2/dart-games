import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Outer bull heals +5 - Reduce health, throw Outer Bull -> +5 health (capped at max)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final firstPlayerId = currentPlayerId;

    // Miss 3 darts, advance turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Opponent attacks to reduce health
    final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, firstPlayerId)!;
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
    await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // First player's health should be 14 (20 - 6)
    final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
    expect(healthBefore, 14);

    // Throw outer bull to heal +5
    await throwOuterBullViaMock(tester);

    // Verify +5 heal
    final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
    expect(healthAfter, 19); // 14 + 5 = 19
  });
}
